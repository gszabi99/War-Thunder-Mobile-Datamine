from "%globalsDarg/darg_library.nut" import *
let logA = log_with_prefix("[ADS] ")
let { eventbus_subscribe } = require("eventbus")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { parse_json, object_to_json_string } = require("json")
let { DBGLEVEL } = require("dagor.system")
let { is_ios } = require("%sqstd/platform.nut")
let { needAdsLoad, rewardInfo, giveReward, onFinishShowAds, RETRY_LOAD_TIMEOUT, RETRY_INC_TIMEOUT,
  providerPriorities, onShowAds, openAdsPreloader, isOpenedAdsPreloaderWnd, closeAdsPreloader,
  hasAdsPreloadError, adsPreloadParams
} = require("%rGui/ads/adsInternalState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let ads = is_ios ? require("ios.ads") : require("adsIosDbg.nut")
let sendAdsBqEvent = is_ios ? require("%rGui/ads/sendAdsBqEvent.nut") : @(_, __, ___ = null) null
let { sendUiBqEvent, sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { ADS_STATUS_LOADED, ADS_STATUS_SHOWN, ADS_STATUS_OK,
  setTestingMode, isAdsInited, getProvidersStatus, addProviderInitWithPriority, setPriorityForProvider,
  isAdsLoaded, loadAds, showAds, showConsent
} = ads
let { isGoogleConsentAllowAds } = require("%appGlobals/loginState.nut")
let { logFirebaseEventWithJson } = require("%rGui/notifications/logEvents.nut")
let { can_preload_request_ads_consent } = require("%appGlobals/permissions.nut")

let isInited = Watched(isAdsInited())
let isLoaded = Watched(isAdsLoaded())
let loadedProvider = hardPersistWatched("adsIos.loadedProvider", "")
let isAdsVisible = Watched(false)
let failInARow = hardPersistWatched("adsIos.failsInARow", 0)

let needAdsLoadExt = Computed(@() isGoogleConsentAllowAds.get() && isInited.get() && !isLoaded.get()
  && (needAdsLoad.get() || isOpenedAdsPreloaderWnd.get()))

function isAllProvidersFailed(providers, statuses) {
  foreach(key, _ in providers)
    if (key not in statuses || statuses[key] == ADS_STATUS_LOADED)
      return false
  return true
}

function handleShowAds(rInfo) {
  rewardInfo(rInfo)
  onShowAds(loadedProvider.get())
  showAds()
}

function initProviders() {
  if (!isGoogleConsentAllowAds.get())
    return
  let { providers, countryCode } = providerPriorities.get()
  if (providers.len() == 0)
    return
  setTestingMode(DBGLEVEL > 0)
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
isGoogleConsentAllowAds.subscribe(@(_) initProviders())

let statusNames = {}
foreach(id, val in ads)
  if (type(val) != "integer")
    continue
  else if (id.startswith("ADS_STATUS_"))
    statusNames[val] <- id
let getStatusName = @(v) statusNames?[v] ?? v

eventbus_subscribe("ios.ads.onInit", function(msg) {
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

local providersStatuses = {}
eventbus_subscribe("ios.ads.onLoad",function (params) {
  let { status, provider = "unknown" } = params
  logA($"onLoad {getStatusName(status)} ({provider})")
  isLoadStarted = false
  loadedProvider.set(provider)
  isLoaded(status == ADS_STATUS_LOADED && isAdsLoaded())
  if (isLoaded.get()) {
    failInARow(0)
    clearTimer(retryLoad)
    providersStatuses.clear()
    sendAdsBqEvent("loaded", provider, false)
    if (isOpenedAdsPreloaderWnd.get() && adsPreloadParams.get())
      handleShowAds(adsPreloadParams.get())
    return
  }

  if (provider not in providersStatuses)
    providersStatuses[provider] <- status

  if (needAdsLoadExt.get() && !isRetryQueued) {
    isRetryQueued = true
    resetTimeout(RETRY_LOAD_TIMEOUT + failInARow.get() * RETRY_INC_TIMEOUT, retryLoad)
    failInARow(failInARow.get() + 1) //we can have several fail events on single adsLoad request
  }
  if (isAllProvidersFailed(providerPriorities.get().providers, providersStatuses))
    hasAdsPreloadError.set(true)
  sendAdsBqEvent("load_failed", provider, false)
})

eventbus_subscribe("ios.ads.onRevenue", function (params) {
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


eventbus_subscribe("ios.ads.onShow",function (params) { //we got this event on start ads show, and on finish
  let { status, provider = "unknown" } = params
  logA($"onShow {getStatusName(status)}:", rewardInfo.value?.bqId, rewardInfo.value?.bqParams)
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

eventbus_subscribe("ios.ads.onReward", function (params) {
  let { provider = "unknown" } = params
  logA($"onReward {params.amount} {params.type}:", rewardInfo.value?.bqId, rewardInfo.value?.bqParams)
  giveReward()
  closeAdsPreloader()
  sendAdsBqEvent("receive_reward", provider)
})


function showAdsForReward(rInfo) {
  providersStatuses.clear()
  if (isLoaded.get())
    handleShowAds(rInfo)
  else
    openAdsPreloader(rInfo)
}

function onTryShowNotAvailableAds() {
  if (isGoogleConsentAllowAds.get())
    return false
  sendUiBqEvent("ads_consent", { id = "show_on_try_watch_ads" })
  showConsent()
  return true
}


return {
  isAdsAvailable = WatchedRo(true)
  isAdsVisible
  canShowAds = can_preload_request_ads_consent.get() ? isLoaded : Watched(true)
  showAdsForReward
  isLoaded
  onTryShowNotAvailableAds
}
