from "%globalsDarg/darg_library.nut" import *
let logA = log_with_prefix("[ADS] ")
let { eventbus_subscribe } = require("eventbus")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { parse_json, json_to_string } = require("json")
let { is_android } = require("%sqstd/platform.nut")
let { needAdsLoad, rewardInfo, giveReward, onFinishShowAds, RETRY_LOAD_TIMEOUT, RETRY_INC_TIMEOUT,
  providerPriorities, onShowAds
} = require("%rGui/ads/adsInternalState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let ads = is_android ? require("android.ads") : require("adsAndroidDbg.nut")
let sendAdsBqEvent = is_android ? require("%rGui/ads/sendAdsBqEvent.nut") : @(_, __, ___ = null) null
let { sendUiBqEvent, sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { ADS_STATUS_LOADED, ADS_STATUS_SHOWN, ADS_STATUS_OK,
  isAdsInited, getProvidersStatus, addProviderInitWithPriority, setPriorityForProvider,
  isAdsLoaded, loadAds, showAds, showConsent
} = ads

let { isAdsAllowedForRequest } = require("%rGui/notifications/consent/consentGoogleState.nut")
let { logFirebaseEventWithJson } = require("%rGui/notifications/logEvents.nut")

let isInited = Watched(isAdsInited())
let isLoaded = Watched(isAdsLoaded())
let loadedProvider = hardPersistWatched("adsAndroid.loadedProvider", "")
let isAdsVisible = Watched(false)
let failInARow = hardPersistWatched("adsAndroid.failsInARow", 0)

let needAdsLoadExt = Computed(@() isAdsAllowedForRequest.get() && isInited.get() && needAdsLoad.get() && !isLoaded.get())

function initProviders() {
  if (!isAdsAllowedForRequest.get())
    return
  let { providers, countryCode } = providerPriorities.get()
  if (providers.len() == 0)
    return

  logA($"Init providers for {countryCode}")
  let pStatus = parse_json(getProvidersStatus())
  let initedProviders = {}
  foreach (info in pStatus)
    if (info.isInited)
      initedProviders[info.provider] <- true

  foreach (id, _ in initedProviders)
    if (id not in providers)
      setPriorityForProvider(id, -1) //switch of provider missing in config

  foreach (id, p in providers)
    if (id in initedProviders)
      setPriorityForProvider(id, p.priority)
    else
      addProviderInitWithPriority(id, p.key, p.priority)
}
initProviders()
providerPriorities.subscribe(@(_) initProviders())
isAdsAllowedForRequest.subscribe(@(_) initProviders())

let statusNames = {}
foreach(id, val in ads)
  if (type(val) != "integer")
    continue
  else if (id.startswith("ADS_STATUS_"))
    statusNames[val] <- id
let getStatusName = @(v) statusNames?[v] ?? v

eventbus_subscribe("android.ads.onInit", function(msg) {
  let { status, provider } = msg
  if (status != ADS_STATUS_OK)
    return
  logA($"Provider {provider} inited")
  isInited(true)
})

local isLoadStarted = false
function startLoading() {
  logA($"Start loading")
  isLoadStarted = true
  loadAds()
  sendAdsBqEvent("load_request", "", false)
}
if (needAdsLoadExt.value)
  startLoading()
needAdsLoadExt.subscribe(function(v) {
  if (v)
    startLoading()
})

local isRetryQueued = false
function retryLoad() {
  isRetryQueued = false
  if (!needAdsLoadExt.value || isLoadStarted)
    return
  logA($"Retry loading")
  isLoadStarted = true
  loadAds()
  sendAdsBqEvent("load_retry", "", false)
}

eventbus_subscribe("android.ads.onLoad", function (params) {
  let { status, provider = "unknown" } = params
  logA($"onLoad {getStatusName(status)} ({provider})")
  isLoadStarted = false
  loadedProvider.set(provider)
  isLoaded(status == ADS_STATUS_LOADED && isAdsLoaded())
  if (isLoaded.value) {
    failInARow(0)
    clearTimer(retryLoad)
    sendAdsBqEvent("loaded", provider, false)
    return
  }

  if (needAdsLoadExt.value && !isRetryQueued) {
    isRetryQueued = true
    resetTimeout(RETRY_LOAD_TIMEOUT + failInARow.value * RETRY_INC_TIMEOUT, retryLoad)
    failInARow(failInARow.value + 1) //we can have several fail events on single adsLoad request
  }
  sendAdsBqEvent("load_failed", provider, false)
})

eventbus_subscribe("android.ads.onRevenue", function (params) {
  let { adapter = "default", provider = "unknown", json = "{}" } = params
  let { value = 0.0, currency = "USD" } = parse_json(json)
  logA($"revenue {value} {currency} provider = {provider} ({adapter})")
  if (value == 0.0)
    return
  sendCustomBqEvent("ad_revenue", {
    provider
    mediator = adapter
    revenue = value
    currency
  })
  logFirebaseEventWithJson("ad_impression", json_to_string({
    ad_platform = provider
    ad_source = adapter
    value = value
    currency = currency
  }, false))
})

eventbus_subscribe("android.ads.onShow", function (params) { //we got this event on start ads show, and on finish
  let { status, provider = "unknown" } = params
  logA($"onShow {getStatusName(status)}:", rewardInfo.value?.bqId, rewardInfo.value?.bqParams)
  if (status == ADS_STATUS_SHOWN) {
    sendAdsBqEvent("show_start", provider)
    isAdsVisible(true)
  }
  else {
    isLoaded(false)
    isAdsVisible(false)
    onFinishShowAds()
    sendAdsBqEvent("show_stop", provider)
  }
})

eventbus_subscribe("android.ads.onReward", function (params) {
  let { provider = "unknown" } = params
  logA($"onReward {params.amount} {params.type}:", rewardInfo.value?.bqId, rewardInfo.value?.bqParams)
  giveReward()
  sendAdsBqEvent("receive_reward", provider)
})

function showAdsForReward(rInfo) {
  if (!isLoaded.value)
    return
  rewardInfo(rInfo)
  onShowAds(loadedProvider.get())
  showAds()
}

function onTryShowNotAvailableAds() {
  if (isAdsAllowedForRequest.get())
    return false
  sendUiBqEvent("ads_consent", { id = "show_on_try_watch_ads" })
  showConsent()
  return true
}

return {
  isAdsAvailable = WatchedRo(true)
  isAdsVisible
  canShowAds = isLoaded
  showAdsForReward
  onTryShowNotAvailableAds
}
