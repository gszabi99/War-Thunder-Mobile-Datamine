from "%globalsDarg/darg_library.nut" import *
let logA = log_with_prefix("[ADS] ")
let { eventbus_subscribe } = require("eventbus")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { parse_json, object_to_json_string } = require("json")
let { is_android } = require("%sqstd/platform.nut")
let { rewardInfo, giveReward, onFinishShowAds, RETRY_LOAD_TIMEOUT, RETRY_INC_TIMEOUT,
  providerPriorities, onShowAds, openAdsPreloader, isOpenedAdsPreloaderWnd, closeAdsPreloader,
  hasAdsPreloadError, adsPreloadParams
} = require("%rGui/ads/adsInternalState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let ads = is_android ? require("android.ads") : require("%rGui/ads/byPlatform/adsAndroidDbg.nut")
let sendAdsBqEvent = is_android ? require("%rGui/ads/sendAdsBqEvent.nut") : @(_, __, ___ = null) null
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { ADS_STATUS_LOADED, ADS_STATUS_SHOWN, ADS_STATUS_OK, ADS_STATUS_FAIL_IN_QUEUE_SKIP,
  isAdsInited, getProvidersStatus, addProviderInitWithPriority, setPriorityForProvider,
  isAdsLoaded, loadAds, showAds
} = ads

let { isGoogleConsentAllowAds } = require("%appGlobals/loginState.nut")
let { logFirebaseEventWithJson } = require("%rGui/notifications/logEvents.nut")


let isInited = Watched(isAdsInited())
let isLoaded = Watched(isAdsLoaded())
let loadedProvider = hardPersistWatched("adsAndroid.loadedProvider", "")
let isAdsVisible = Watched(false)
let failInARow = hardPersistWatched("adsAndroid.failsInARow", 0)

let needAdsLoad = Computed(@() isGoogleConsentAllowAds.get() && isInited.get() && !isLoaded.get()
   && isOpenedAdsPreloaderWnd.get())

function isAllProvidersFailed(providers, statuses) {
  foreach(key, _ in providers)
    if (key not in statuses || statuses[key] == ADS_STATUS_LOADED)
      return false
  return true
}

function handleShowAds(rInfo) {
  rewardInfo.set(rInfo)
  onShowAds(loadedProvider.get())
  showAds()
}

function initProviders() {
  if (!isGoogleConsentAllowAds.get())
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
      setPriorityForProvider(id, -1) 

  foreach (id, p in providers)
    if (id in initedProviders) {
      setPriorityForProvider(id, p.priority)
    } else {
      logA($"Add provider {id} with priority {p.priority}")
      addProviderInitWithPriority(id, p.key, p.priority)
    }
}
initProviders()
providerPriorities.subscribe(@(_) initProviders())
isGoogleConsentAllowAds.subscribe(@(_) initProviders())

let statusNames = {}
foreach(id, val in ads)
  if (type(val) != "integer")
    continue
  else if (id.startswith("ADS_STATUS_"))
    statusNames[val] <- id
let getStatusName = @(v) statusNames?[v] ?? v

eventbus_subscribe("android.ads.onInit", function(msg) {
  let { status, provider } = msg
  if (status != ADS_STATUS_OK) {
    logA($"Provider {provider} init failed")
    return
  }
  logA($"Provider {provider} inited")
  isInited.set(true)
})

local isLoadStarted = false
function startLoading() {
  logA($"Start loading")
  isLoadStarted = true
  loadAds()
  sendAdsBqEvent("load_request", "", false)
}
if (needAdsLoad.get())
  startLoading()
needAdsLoad.subscribe(function(v) {
  if (v)
    startLoading()
})

local isRetryQueued = false
function retryLoad() {
  isRetryQueued = false
  if (!needAdsLoad.get() || isLoadStarted)
    return
  logA($"Retry loading")
  isLoadStarted = true
  loadAds()
  sendAdsBqEvent("load_retry", "", false)
}

local providersStatuses = {}
eventbus_subscribe("android.ads.onLoad", function (params) {
  let { status, provider = "unknown", adapter = "none" } = params
  logA($"onLoad {getStatusName(status)} {provider}({adapter})")
  if (status == ADS_STATUS_FAIL_IN_QUEUE_SKIP) {
    logA("Skipping, waiting for next ads provider")
    return
  }
  isLoadStarted = false
  loadedProvider.set(provider)
  isLoaded.set(status == ADS_STATUS_LOADED && isAdsLoaded())
  if (isLoaded.get()) {
    failInARow.set(0)
    clearTimer(retryLoad)
    providersStatuses.clear()
    sendAdsBqEvent("loaded", provider, false)
    if (isOpenedAdsPreloaderWnd.get() && adsPreloadParams.get())
      handleShowAds(adsPreloadParams.get())
    return
  }

  if (provider not in providersStatuses)
    providersStatuses[provider] <- status

  if (needAdsLoad.get() && !isRetryQueued) {
    isRetryQueued = true
    resetTimeout(RETRY_LOAD_TIMEOUT + failInARow.get() * RETRY_INC_TIMEOUT, retryLoad)
    failInARow.set(failInARow.get() + 1) 
  }
  if (isAllProvidersFailed(providerPriorities.get().providers, providersStatuses))
    hasAdsPreloadError.set(true)
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
  logFirebaseEventWithJson("ad_impression", object_to_json_string({
    ad_platform = provider
    ad_source = adapter
    value = value
    currency = currency
  }, false))
})

eventbus_subscribe("android.ads.onShow", function (params) { 
  let { status, provider = "unknown" } = params
  logA($"onShow {getStatusName(status)}:", rewardInfo.get()?.bqId, rewardInfo.get()?.bqParams)
  if (status == ADS_STATUS_SHOWN) {
    sendAdsBqEvent("show_start", provider)
    isAdsVisible.set(true)
  }
  else {
    isLoaded.set(false)
    isAdsVisible.set(false)
    onFinishShowAds()
    closeAdsPreloader()
    sendAdsBqEvent("show_stop", provider)
  }
})

eventbus_subscribe("android.ads.onReward", function (params) {
  let { provider = "unknown" } = params
  logA($"onReward {params.amount} {params.type}:", rewardInfo.get()?.bqId, rewardInfo.get()?.bqParams)
  giveReward()
  closeAdsPreloader()
  sendAdsBqEvent("receive_reward", provider)
})

function showAdsForReward(rInfo) {
  if (!isInited.get()) {
    logerr("Trying to show ads when there is no initialized provider")
    return
  }
  providersStatuses.clear()
  if (isLoaded.get())
    handleShowAds(rInfo)
  else
    openAdsPreloader(rInfo)
}

return {
  isAdsAvailable = WatchedRo(true)
  isAdsVisible
  showAdsForReward
  isLoaded
  isInited
}
