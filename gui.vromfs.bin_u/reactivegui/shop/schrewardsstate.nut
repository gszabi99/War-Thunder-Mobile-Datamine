from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { shopCategoriesCfg, getGoodsType, isGoodsFitToCampaign } = require("shopCommon.nut")
let { campConfigs, receivedSchRewards } = require("%appGlobals/pServer/campaign.nut")
let { schRewardInProgress, apply_scheduled_reward } = require("%appGlobals/pServer/pServerApi.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { isAdsAvailable, canShowAds, showAdsForReward } = require("%rGui/ads/adsState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")


let watchedSchRewardAd = Watched({})
let schRewards = Computed(@() (campConfigs.value?.schRewards ?? {})
  .filter(@(g) isGoodsFitToCampaign(g, campConfigs.value))
  .map(@(g, id) g.__merge({ id, gtype = getGoodsType(g), isFreeReward = true })))

let schRewardsByCategory = Computed(function() {
  let res = {}
  let listByType = {}
  foreach (c in shopCategoriesCfg) {
    let list = []
    res[c.id] <- list
    foreach (gt in c.gtypes)
      listByType[gt] <- list
  }
  let hasAds = isAdsAvailable
  foreach (goods in schRewards.value)
    if (!goods.needAdvert || hasAds)
      listByType[goods.gtype].append(goods)
  return res.filter(@(list) list.len() > 0)
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

let function updateActualSchRewards() {
  let received = receivedSchRewards.value
  let curTime = serverTime.value
  local nextTime = 0
  local actual = {}
  foreach (catId, list in schRewardsByCategory.value) {
    let listExt = list.map(function(r) {
      let readyTime = (received?[r.id] ?? 0) + r.interval
      return r.__merge({ isReady = readyTime <= curTime, readyTime })
    })
    local reward = null
    local priority = 0
    foreach (r in listExt) {
      let pr = getRewardPriority(r)
      if (reward != null && priority >= pr)
        continue
      reward = r
      priority = pr
    }
    actual[catId] <- reward
    if (!reward.isReady)
      nextTime = nextTime == 0 ? reward.readyTime : min(nextTime, reward.readyTime)
  }

  nextUpdate({ time = nextTime })
  actualSchRewardByCategory(actual)
}
updateActualSchRewards()
schRewardsByCategory.subscribe(@(_) updateActualSchRewards())
receivedSchRewards.subscribe(@(_) updateActualSchRewards())

let function resetUpdateTimer() {
  let { time } = nextUpdate.value
  let left = time - serverTime.value
  if (left <= 0)
    clearTimer(updateActualSchRewards)
  else
    resetTimeout(left, updateActualSchRewards)
}
resetUpdateTimer()
nextUpdate.subscribe(@(_) resetUpdateTimer())

let function onSchRewardReceive(schReward) {
  if (schRewardInProgress.value == schReward.id)
    return
  if (!schReward.isReady) {
    openMsgBox({ text = loc("msg/scheduledRewardNotReadyYet") })
    return
  }

  if (!schReward.needAdvert)
    apply_scheduled_reward(schReward.id)
  else if (canShowAds.value)
    showAdsForReward({ schRewardId = schReward.id, bqId = $"scheduled_{schReward.id}" })
  else
    openMsgBox({ text = loc("msg/adsNotReadyYet") })
}

subscribe("adsRewardApply", function(data) {
  let { schRewardId = null } = data
  let reward = schRewards.value?[schRewardId]
  if (reward == null)
    return
  let receivedTime = receivedSchRewards.value?[schRewardId] ?? 0
  if (receivedTime + reward.interval <= serverTime.value) {
    apply_scheduled_reward(schRewardId)
    watchedSchRewardAd({ schRewardId, receivedTime })
  }

})

return {
  actualSchRewardByCategory
  actualSchRewards
  onSchRewardReceive
  watchedSchRewardAd
}