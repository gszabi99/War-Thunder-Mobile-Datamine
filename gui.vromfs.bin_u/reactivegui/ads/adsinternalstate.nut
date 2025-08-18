from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { getCountryCode } = require("auth_wt")
let { isDownloadedFromGooglePlay } = require("android.platform")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { is_ios, is_android } = require("%sqstd/platform.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { isConsentWasAutoSkipped, needOpenConsentWnd } = require("%rGui/notifications/consent/consentState.nut")
let { set_mute_sound } = require("soundOptions")


let RETRY_LOAD_TIMEOUT = 120
let RETRY_INC_TIMEOUT = 60 

let hasAdsPreloadError = Watched(false)
let adsPreloadParams = Watched(null)
let isOpenedAdsPreloaderWnd = Computed(@() adsPreloadParams.get() != null
  && !isConsentWasAutoSkipped.get()
  && isLoggedIn.get())

let rewardInfo = mkWatched(persist, "rewardInfo", null)
let debugAdsWndParams = Watched(null)
let attachedAdsButtons = Watched(0)
let isAnyAdsButtonAttached = Computed(@() attachedAdsButtons.get() > 0)

isLoggedIn.subscribe(@(v) !v? adsPreloadParams.set(null) : null)

function giveReward() {
  if (rewardInfo.get() != null)
    eventbus_send("adsRewardApply", rewardInfo.get())
}

function onFinishShowAds() {
  if (rewardInfo.get() != null)
    eventbus_send("adsShowFinish", rewardInfo.get())
  set_mute_sound(true)
}

let cancelReward = @() rewardInfo.set(null)

let providersId = is_ios ? "iOS"
  : isDownloadedFromGooglePlay() ? "android_gp"
  : "android_apk"
let fbProvidersId = is_android ? "android" : providersId

let adsAccessesProvider = Computed(function() {
  let { adsAccessesCfg = {} } = serverConfigs.get()

  let provider = providersId in adsAccessesCfg ? providersId : fbProvidersId
  if (provider in adsAccessesCfg && ((myUserId.get() % 100) < adsAccessesCfg[provider].percent))
    return adsAccessesCfg[provider].id

  return ""
})

let allProviders = keepref(Computed(function() {
  if (!isLoggedIn.get())
    return {}
  let { adsCfg = null } = serverConfigs.get()

  return adsCfg?[$"{adsAccessesProvider.get()}"]
    ?? adsCfg?[providersId]
    ?? adsCfg?[fbProvidersId]
    ?? {}
}))
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