from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { shopCategoriesCfg, getGoodsType, isGoodsFitToCampaign } = require("shopCommon.nut")
let { campConfigs, receivedSchRewards } = require("%appGlobals/pServer/campaign.nut")
let { schRewardInProgress, apply_scheduled_reward, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { isAdsAvailable, canShowAds, showAdsForReward, showNotAvailableAdsMsg } = require("%rGui/ads/adsState.nut")
let adBudget = require("%rGui/ads/adBudget.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { playSound } = require("sound_wt")


let lastAppliedSchReward = Watched({})
let schRewardsBase = Computed(@() (campConfigs.value?.schRewards ?? {})
  .filter(@(g) isGoodsFitToCampaign(g, campConfigs.value))
  .map(@(g, id) g.__merge({ id, gtype = getGoodsType(g), isFreeReward = true })))
let schRewardsStatus = Watched({})
let schRewards = Computed(@() schRewardsBase.value
  .map(@(r, id) id in schRewardsStatus.value ? r.__merge(schRewardsStatus.value[id]) : r))

let schRewardsByCategory = Computed(function() {
  let res = {}
  let listByType = {}
  let hiddenList = []
  foreach (c in shopCategoriesCfg) {
    let list = []
    res[c.id] <- list
    foreach (gt in c.gtypes)
      listByType[gt] <- list
  }
  let hasAds = isAdsAvailable.get()
  foreach (goods in schRewardsBase.value) {
    if (goods?.isHidden) { // Hidden for shop
      hiddenList.append(goods)
      continue
    }

    if (!goods.needAdvert || hasAds)
      listByType[goods.gtype].append(goods)
  }

  return { shop = res.filter(@(list) list.len() > 0), hidden = hiddenList }
})

let actualSchRewardByCategory = Watched({})
let actualSchRewards = Computed(function() {
  let res = {}
  foreach (v in actualSchRewardByCategory.value)
    res[v.id] <- v
  return res
})

let nextUpdate = Watched({ time = 0 }) //even when value changed to the same, better to restart timer.

let READY_ADVERT      = 10000000000
let READY_NOT_ADVERT  = 20000000000
let getRewardPriority = @(rew) - rew.readyTime
  + (!rew.isReady ? 0
    : rew.needAdvert ? READY_ADVERT
    : READY_NOT_ADVERT)

function updateActualSchRewards() {
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
      if (schReward != null && priority >= pr)
        continue
      schReward = reward
      priority = pr
    }
    actual[catId] <- schReward
    if (!schReward.isReady)
      nextTime = nextTime == 0 ? schReward.readyTime : min(nextTime, schReward.readyTime)
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
  if (schRewardInProgress.value == schReward.id)
    return
  if (!schReward.isReady) {
    openMsgBox({ text = loc("msg/scheduledRewardNotReadyYet") })
    return
  }

  let { cost = 0 } = schReward
  if (cost > adBudget.value) {
    openMsgBox({ text = loc("playBattlesToUnlockAds") })
    return
  }

  if (!schReward.needAdvert)
    applyScheduledReward(schReward.id)
  else if (canShowAds.value) {
    playSound("meta_ad_button")
    showAdsForReward({ schRewardId = schReward.id, cost = schReward?.cost ?? 0, bqId = $"scheduled_{schReward.id}" })
  }
  else
    showNotAvailableAdsMsg()
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