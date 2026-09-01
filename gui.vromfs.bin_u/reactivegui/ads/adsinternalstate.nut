from "%globalsDarg/darg_library.nut" import *
from "android.platform" import isDownloadedFromGooglePlay, getBuildMarket
from "app" import get_game_version_str
from "auth_wt" import getCountryCode
from "eventbus" import eventbus_send
from "soundOptions" import set_mute_sound
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/platform.nut" import is_ios, is_android, platformId
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/consent.nut" import isTcfConsentEnabled
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/bqClient.nut" import sendCustomBqEvent
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/profileStates.nut" import myUserId
from "%rGui/notifications/consentFirebase/consentState.nut" import isConsentWasAutoSkipped, needOpenConsentWnd
from "%rGui/notifications/consentTcf/consentTcfState.nut" import isTcfConsentAutoSkipped, openTcfConsentWnd


const RETRY_LOAD_TIMEOUT = 120
const RETRY_INC_TIMEOUT = 60 
let isHuaweiBuild = getBuildMarket() == "appgallery"

let isShowStarted = hardPersistWatched("ads.isShowStarted", false)
let hasAdsPreloadError = Watched(false)
let adsPreloadParams = Watched(null)
let isOpenedAdsPreloaderWnd = Computed(@() adsPreloadParams.get() != null
  && ((isTcfConsentEnabled.get() && !isTcfConsentAutoSkipped.get()) || (!isTcfConsentEnabled.get() && !isConsentWasAutoSkipped.get()))
  && isLoggedIn.get())

let rewardInfo = mkWatched(persist, "rewardInfo", null)
let debugAdsWndParams = Watched(null)
let attachedAdsButtons = Watched(0)
let isAnyAdsButtonAttached = Computed(@() attachedAdsButtons.get() > 0)
let failedProviders = mkWatched(persist, "failedProviders", {})

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
  : isHuaweiBuild ? "huawei"
  : isDownloadedFromGooglePlay() ? "android_gp"
  : "android_apk"
let fbProvidersId = is_android ? "android" : providersId

let operator = getCurCircuitOverride("publisher")
let operatorProvidersId = operator ? $"{operator}_{fbProvidersId}" : providersId

let adsAccessesProvider = Computed(function() {
  let { adsAccessesCfg = {} } = serverConfigs.get()

  let provider = operatorProvidersId in adsAccessesCfg ? operatorProvidersId : fbProvidersId
  if (provider in adsAccessesCfg && ((myUserId.get() % 100) < adsAccessesCfg[provider].percent))
    return adsAccessesCfg[provider].id

  return ""
})

let allProviders = keepref(Computed(function() {
  if (!isLoggedIn.get())
    return {}
  let { adsCfg = null } = serverConfigs.get()

  return adsCfg?[$"{adsAccessesProvider.get()}"]
    ?? adsCfg?[operatorProvidersId]
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
    providers[id] <- { key = p.key, periods, params = p?.params ?? {}, showCount }
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
  if (isTcfConsentEnabled.get() && isTcfConsentAutoSkipped.get())
    openTcfConsentWnd()
  else if (!isTcfConsentEnabled.get() && isConsentWasAutoSkipped.get())
    needOpenConsentWnd.set(true)
  adsPreloadParams.set(rInfo)
}

failedProviders.subscribe(function(f) {
  let { providers, countryCode } = providerPriorities.get()
  if (f.len() == 0 || providers.len() == 0)
    return
  foreach (id, _ in providers)
    if (id not in f)
      return

  sendCustomBqEvent("ads", {
    status = "failed to init"
    provider = ";".join(providers.keys().sort())
    platform = platformId
    location = countryCode
    gameVersion = get_game_version_str()
  })
})

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
  failedProviders
  isOpenedAdsPreloaderWnd
  isShowStarted
  openAdsPreloader
  closeAdsPreloader = @() adsPreloadParams.set(null)
  hasAdsPreloadError
  adsPreloadParams
}