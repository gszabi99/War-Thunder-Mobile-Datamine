from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { send } = require("eventbus")
let logA = log_with_prefix("[ADS] ")
let { campConfigs, receivedSchRewards } = require("%appGlobals/pServer/campaign.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let LOAD_ADS_BEFORE_TIME = 120 //2 min before ads will be ready to watch
let RETRY_LOAD_TIMEOUT = 120
let RETRY_INC_TIMEOUT = 60 //increase time with each fail, but reset on success. Also retry after battle without timeout

let needAdsLoadByTime = Watched(false)
let needAdsLoad = Computed(@() !isInBattle.value && needAdsLoadByTime.value)
let advertRewardsTimes = keepref(Computed(function() {
  let received = receivedSchRewards.value
  return (campConfigs.value?.schRewards ?? {})
    .filter(@(r) r.needAdvert)
    .map(@(r, id) (received?[id] ?? 0) + r.interval)
}))
let rewardInfo = mkWatched(persist, "rewardInfo", null)
let debugAdsWndParams = Watched(null)
let attachedAdsButtons = Watched(0)
let isAnyAdsButtonAttached = Computed(@() attachedAdsButtons.get() > 0)

needAdsLoad.subscribe(@(v) logA(v ? "Need to prepare ads load" : "no more need to load ads now"))

let function updateNeedAdsLoad() {
  local nextTime = advertRewardsTimes.value.reduce(@(a, b) min(a, b))
  needAdsLoadByTime(nextTime != null && nextTime - LOAD_ADS_BEFORE_TIME <= serverTime.value)
  if (!needAdsLoadByTime.value && nextTime != null)
    resetTimeout(nextTime - serverTime.value - LOAD_ADS_BEFORE_TIME, updateNeedAdsLoad)
  else
    clearTimer(updateNeedAdsLoad)
}
advertRewardsTimes.subscribe(@(_) updateNeedAdsLoad())
updateNeedAdsLoad()

let function giveReward() {
  if (rewardInfo.value != null)
    send("adsRewardApply", rewardInfo.value)
}

let function onFinishShowAds() {
  if (rewardInfo.value != null)
    send("adsShowFinish", rewardInfo.value)
}

let cancelReward = @() rewardInfo(null)

return {
  RETRY_LOAD_TIMEOUT
  RETRY_INC_TIMEOUT
  needAdsLoad
  rewardInfo
  giveReward
  onFinishShowAds
  cancelReward
  debugAdsWndParams
  attachedAdsButtons
  isAnyAdsButtonAttached
}