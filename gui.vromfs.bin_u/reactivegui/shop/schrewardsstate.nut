from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { G_UNIT, G_UNIT_UPGRADE, G_ITEM } = require("%appGlobals/rewardType.nut")
let { resetExtTimeout, clearExtTimer } = require("%appGlobals/timeoutExt.nut")
let { getShopCategory, getGoodsType } = require("%rGui/shop/shopCommon.nut")
let { campConfigs, receivedSchRewards } = require("%appGlobals/pServer/campaign.nut")
let { hasVip } = require("%rGui/state/profilePremium.nut")
let { schRewardInProgress, apply_scheduled_reward, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { isAdsAvailable, showAdsForReward, isProviderInited } = require("%rGui/ads/adsState.nut")
let adBudget = require("%rGui/ads/adBudget.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { playSound } = require("sound_wt")
let { rewardsToShopGoods } = require("%rGui/shop/rewardsToShopGoods.nut")

let rewardsToGoodsFormat = @(schReward, id)
  schReward.__merge({ id, isFreeReward = true }, rewardsToShopGoods(schReward?.rewards ?? []))

function isRewardsFitToCampaign(schReward, cConfigs) {
  let { rewards = [] } = schReward
  foreach(g in rewards)
    if (g.gType == G_UNIT || g.gType == G_UNIT_UPGRADE)
      return g.id in cConfigs?.allUnits
    else if (g.gType == G_ITEM)
      return g.id in cConfigs?.allItems
  return true
}

let lastAppliedSchReward = Watched({})
let schRewardsBase = Computed(@() (campConfigs.get()?.schRewards ?? {})
  .filter(@(g) isRewardsFitToCampaign(g, campConfigs.get()))
  .map(rewardsToGoodsFormat))
let schRewardsStatus = Watched({})
let schRewards = Computed(@() schRewardsBase.get()
  .map(@(r, id) id in schRewardsStatus.get() ? r.__merge(schRewardsStatus.get()[id]) : r))

let schRewardsByCategory = Computed(function() {
  let res = {}
  let hiddenList = []
  let hasAds = isAdsAvailable.get()
  foreach (goods in schRewardsBase.get()) {
    if (goods?.isHidden || (goods.needAdvert && !hasAds)) { 
      hiddenList.append(goods)
      continue
    }

    let cat = getShopCategory(getGoodsType(goods))
    if (cat not in res)
      res[cat] <- []
    res[cat].append(goods)
  }

  return { shop = res, hidden = hiddenList }
})

let actualSchRewardByCategory = Watched({})
let actualSchRewards = Computed(function() {
  let res = {}
  foreach (v in actualSchRewardByCategory.get())
    res[v.id] <- v
  return res
})

let READY_ADVERT      = 10000000000
let READY_NOT_ADVERT  = 20000000000
let getRewardPriority = @(readyTime, isReady, needAdvert) - readyTime
  + (!isReady ? 0
    : needAdvert ? READY_ADVERT
    : READY_NOT_ADVERT)

function getReadyInfo(reward, received, curTime) {
  let readyTime = (received?[reward.id] ?? 0) + reward.interval
  return { readyTime, isReady = readyTime <= curTime }
}

function updateActualSchRewards() {
  if (!isServerTimeValid.get())
    return
  let received = receivedSchRewards.get()
  let curTime = serverTime.get()
  local nextTime = 0
  let actual = {}
  let status = {}
  let { shop, hidden } = schRewardsByCategory.get()
  foreach (catId, list in shop) {
    local schReward = null
    local priority = 0
    foreach (r in list) {
      status[r.id] <- getReadyInfo(r, received, curTime)
      let { readyTime, isReady } = status[r.id]
      if (!isReady)
        nextTime = nextTime <= 0 ? readyTime : min(nextTime, readyTime)
      let pr = getRewardPriority(readyTime, isReady, r.needAdvert)
      if (schReward != null && priority >= pr)
        continue
      schReward = r.__merge(status[r.id])
      priority = pr
    }
    actual[catId] <- schReward
  }
  foreach (r in hidden) {
    status[r.id] <- getReadyInfo(r, received, curTime)
    let { readyTime, isReady } = status[r.id]
    if (!isReady)
      nextTime = nextTime <= 0 ? readyTime : min(nextTime, readyTime)
  }

  actualSchRewardByCategory.set(actual)
  schRewardsStatus.set(status)

  let left = nextTime - curTime
  if (left <= 0)
    clearExtTimer(updateActualSchRewards)
  else
    resetExtTimeout(left, updateActualSchRewards)
}

updateActualSchRewards()
schRewardsByCategory.subscribe(@(_) updateActualSchRewards())
receivedSchRewards.subscribe(@(_) updateActualSchRewards())
isServerTimeValid.subscribe(@(v) v ? updateActualSchRewards() : null)

registerHandler("onSchRewardApplied", function(res, context) {
  if (res?.error != null)
    return
  let { rewardId } = context
  lastAppliedSchReward.set({ rewardId, time = serverTime.get() })
})

let applyScheduledReward = @(rewardId)
  apply_scheduled_reward(rewardId, { id = "onSchRewardApplied", rewardId })

function onSchRewardReceive(schReward) {
  if (schReward.id in schRewardInProgress.get())
    return
  if (!schRewardsStatus.get()?[schReward.id].isReady) {
    if (!schReward.isReady) 
      openMsgBox({ text = loc("msg/scheduledRewardNotReadyYet") })
    return
  }

  let { cost = 0 } = schReward
  if (cost > adBudget.get()) {
    openMsgBox({ text = loc("msg/adsLimitReached") })
    return
  }

  if (!schReward.needAdvert || hasVip.get())
    applyScheduledReward(schReward.id)
  else if (!isProviderInited.get())
    openMsgBox({ text = loc("shop/notAvailableAds") })
  else {
    playSound("meta_ad_button")
    showAdsForReward({ schRewardId = schReward.id, cost = schReward?.cost ?? 0, bqId = $"scheduled_{schReward.id}" })
  }
}

eventbus_subscribe("adsRewardApply", function(data) {
  let { schRewardId = null } = data
  let reward = schRewards.get()?[schRewardId]
  if (reward == null)
    return
  let receivedTime = receivedSchRewards.get()?[schRewardId] ?? 0
  if (receivedTime + reward.interval <= serverTime.get())
    applyScheduledReward(schRewardId)
})

return {
  schRewards
  actualSchRewardByCategory
  actualSchRewards
  onSchRewardReceive
  lastAppliedSchReward
  adBudget
}