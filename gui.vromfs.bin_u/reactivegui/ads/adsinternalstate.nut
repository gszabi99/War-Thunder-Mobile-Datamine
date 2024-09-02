from "%globalsDarg/darg_library.nut" import *
let logA = log_with_prefix("[ADS] ")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { eventbus_send } = require("eventbus")
let { getCountryCode } = require("auth_wt")
let { isDownloadedFromGooglePlay } = require("android.platform")
let { is_ios, is_android } = require("%sqstd/platform.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { campConfigs, receivedSchRewards } = require("%appGlobals/pServer/campaign.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { can_preload_request_ads_consent } = require("%appGlobals/permissions.nut")
let { isConsentWasAutoSkipped, needOpenConsentWnd } = require("%rGui/notifications/consent/consentState.nut")
let { set_mute_sound } = require("soundOptions")


let LOAD_ADS_BEFORE_TIME = 120 //2 min before ads will be ready to watch
let RETRY_LOAD_TIMEOUT = 120
let RETRY_INC_TIMEOUT = 60 //increase time with each fail, but reset on success. Also retry after battle without timeout

let hasAdsPreloadError = Watched(false)
let adsPreloadParams = Watched(null)
let isOpenedAdsPreloaderWnd = Computed(@() adsPreloadParams.get() != null && !isConsentWasAutoSkipped.get())

let needAdsLoadByTime = Watched(false)
let needAdsLoad = Computed(@() !isInBattle.get() && needAdsLoadByTime.get())
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
function updateNeedAdsLoad() {
  local nextTime = advertRewardsTimes.value.reduce(@(a, b) min(a, b))
  needAdsLoadByTime(can_preload_request_ads_consent.get() && nextTime != null && nextTime - LOAD_ADS_BEFORE_TIME <= serverTime.get())
  if (!needAdsLoadByTime.get() && nextTime != null)
    resetTimeout(nextTime - serverTime.get() - LOAD_ADS_BEFORE_TIME, updateNeedAdsLoad)
  else
    clearTimer(updateNeedAdsLoad)
}
advertRewardsTimes.subscribe(@(_) updateNeedAdsLoad())
updateNeedAdsLoad()

function giveReward() {
  if (rewardInfo.value != null)
    eventbus_send("adsRewardApply", rewardInfo.value)
}

function onFinishShowAds() {
  if (rewardInfo.value != null)
    eventbus_send("adsShowFinish", rewardInfo.value)
  set_mute_sound(true)
}

let cancelReward = @() rewardInfo(null)

let providersId = is_ios ? "iOS"
  : isDownloadedFromGooglePlay() ? "android_gp"
  : "android_apk"
let fbProvidersId = is_android ? "android" : providersId
let allProviders = keepref(Computed(@() !isLoggedIn.get() ? {}
  : (serverConfigs.get()?.adsCfg[providersId] ?? serverConfigs.get()?.adsCfg[fbProvidersId] ?? {})))
let providerShows = hardPersistWatched("ads.providerShows", {})

let prevIfEqual = @(prev, cur) isEqual(cur, prev) ? prev : cur
let providerPriorities = Computed(function(prev) {
  let countryCode = getCountryCode()
  let providers = {}
  let res = { countryCode, providers }
  let providersBase = allProviders.get()
  if (providersBase.len() == 0)
    return prevIfEqual(prev, res)

  local maxPeriods = 0
  local maxShowCount = 0
  foreach (id, p in providersBase) {
    let showCount = p.showCountOverwriteByRegion?[countryCode] ?? p.showCount
    if (showCount <= 0)
      continue
    let periods = (providerShows.get()?[id] ?? 0) / showCount
    providers[id] <- { key = p.key, periods, showCount }
    maxShowCount = max(maxShowCount, showCount)
    maxPeriods = max(maxPeriods, periods)
  }

  foreach (p in providers)
    p.priority <- (maxPeriods - p.periods) * (maxShowCount + 1) + p.showCount

  return prevIfEqual(prev, res)
})

function onShowAds(providerBase = "") {
  set_mute_sound(false)
  local provider = providerBase
  if (provider == "") {
    local priority = -1
    foreach (id, p in providerPriorities.get().providers)
      if (p.priority > priority) {
        provider = id
        priority = p.priority
      }
  }

  providerShows.mutate(@(v) v[provider] <- (v?[provider] ?? 0) + 1)
}

function openAdsPreloader(rInfo) {
  if (isConsentWasAutoSkipped.get())
    needOpenConsentWnd.set(true)
  adsPreloadParams.set(rInfo)
}

return {
  RETRY_LOAD_TIMEOUT
  RETRY_INC_TIMEOUT
  needAdsLoad
  rewardInfo
  giveReward
  onFinishShowAds
  onShowAds
  cancelReward
  debugAdsWndParams
  attachedAdsButtons
  isAnyAdsButtonAttached
  providerPriorities
  isOpenedAdsPreloaderWnd
  openAdsPreloader
  closeAdsPreloader = @() adsPreloadParams.set(null)
  hasAdsPreloadError
  adsPreloadParams
}