from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { G_UNIT, G_UNIT_UPGRADE, G_ITEM } = require("%appGlobals/rewardType.nut")
let { getShopCategory } = require("shopCommon.nut")
let { campConfigs, receivedSchRewards } = require("%appGlobals/pServer/campaign.nut")
let { hasVip } = require("%rGui/state/profilePremium.nut")
let { schRewardInProgress, apply_scheduled_reward, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { isAdsAvailable, showAdsForReward } = require("%rGui/ads/adsState.nut")
let adBudget = require("%rGui/ads/adBudget.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { playSound } = require("sound_wt")
let rewardsToShopGoods = require("rewardsToShopGoods.nut")

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
let schRewardsBase = Computed(@() (campConfigs.value?.schRewards ?? {})
  .filter(@(g) isRewardsFitToCampaign(g, campConfigs.value))
  .map(rewardsToGoodsFormat))
let schRewardsStatus = Watched({})
let schRewards = Computed(@() schRewardsBase.value
  .map(@(r, id) id in schRewardsStatus.value ? r.__merge(schRewardsStatus.value[id]) : r))

let schRewardsByCategory = Computed(function() {
  let res = {}
  let hiddenList = []
  let hasAds = isAdsAvailable.get()
  foreach (goods in schRewardsBase.get()) {
    if (goods?.isHidden || (goods.needAdvert && !hasAds)) { 
      hiddenList.append(goods)
      continue
    }

    let cat = getShopCategory(goods.gtype)
    if (cat not in res)
      res[cat] <- []
    res[cat].append(goods)
  }

  return { shop = res, hidden = hiddenList }
})

let actualSchRewardByCategory = Watched({})
let actualSchRewards = Computed(function() {
  let res = {}
  foreach (v in actualSchRewardByCategory.value)
    res[v.id] <- v
  return res
})

let nextUpdate = Watched({ time = 0 }) 

let READY_ADVERT      = 10000000000
let READY_NOT_ADVERT  = 20000000000
let getRewardPriority = @(rew) - rew.readyTime
  + (!rew.isReady ? 0
    : rew.needAdvert ? READY_ADVERT
    : READY_NOT_ADVERT)

function updateActualSchRewards() {
  if (!isServerTimeValid.get())
    return
  let received = receivedSchRewards.value
  let curTime = serverTime.value
  local nextTime = 0
  local actual = {}
  local status = {}
  foreach (r in schRewardsBase.value) {
    let readyTime = (received?[r.id] ?? 0) + r.interval
    status[r.id] <- { isReady = readyTime <= curTime, readyTime }
  }
  foreach (catId, list in schRewardsByCategory.value.shop) {
    local schReward = null
    local priority = 0
    foreach (r in list) {
      let reward = r.__merge(status?[r.id])
      let pr = getRewardPriority(reward)
      if (!reward.isReady)
        nextTime = nextTime == 0 ? reward.readyTime : min(nextTime, reward.readyTime)
      if (schReward != null && priority >= pr)
        continue
      schReward = reward
      priority = pr
    }
    actual[catId] <- schReward
  }
  foreach (r in schRewardsByCategory.value.hidden)
    if (r.id in status && !status[r.id].isReady)
      nextTime = nextTime == 0 ? status[r.id].readyTime : min(nextTime, status[r.id].readyTime)

  nextUpdate({ time = nextTime })
  actualSchRewardByCategory(actual)
  schRewardsStatus(status)
}
updateActualSchRewards()
schRewardsByCategory.subscribe(@(_) updateActualSchRewards())
receivedSchRewards.subscribe(@(_) updateActualSchRewards())
isServerTimeValid.subscribe(@(v) v ? updateActualSchRewards() : null)

function resetUpdateTimer() {
  let { time } = nextUpdate.value
  let left = time - serverTime.value
  if (left <= 0)
    clearTimer(updateActualSchRewards)
  else
    resetTimeout(left, updateActualSchRewards)
}
resetUpdateTimer()
nextUpdate.subscribe(@(_) resetUpdateTimer())

registerHandler("onSchRewardApplied", function(res, context) {
  if (res?.error != null)
    return
  let { rewardId } = context
  lastAppliedSchReward({ rewardId, time = serverTime.value })
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
  if (cost > adBudget.value) {
    openMsgBox({ text = loc("msg/adsLimitReached") })
    return
  }

  if (!schReward.needAdvert || hasVip.get())
    applyScheduledReward(schReward.id)
  else {
    playSound("meta_ad_button")
    showAdsForReward({ schRewardId = schReward.id, cost = schReward?.cost ?? 0, bqId = $"scheduled_{schReward.id}" })
  }
}

eventbus_subscribe("adsRewardApply", function(data) {
  let { schRewardId = null } = data
  let reward = schRewards.value?[schRewardId]
  if (reward == null)
    return
  let receivedTime = receivedSchRewards.value?[schRewardId] ?? 0
  if (receivedTime + reward.interval <= serverTime.value)
    applyScheduledReward(schRewardId)
})

return {
  schRewards
  schRewardsStatus
  actualSchRewardByCategory
  actualSchRewards
  onSchRewardReceive
  lastAppliedSchReward
  adBudget
}