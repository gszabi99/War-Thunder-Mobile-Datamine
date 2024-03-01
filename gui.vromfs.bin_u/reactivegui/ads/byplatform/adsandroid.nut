from "%globalsDarg/darg_library.nut" import *
let logA = log_with_prefix("[ADS] ")
let { eventbus_subscribe } = require("eventbus")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { parse_json } = require("json")
let { is_android } = require("%sqstd/platform.nut")
let { needAdsLoad, rewardInfo, giveReward, onFinishShowAds, RETRY_LOAD_TIMEOUT, RETRY_INC_TIMEOUT,
  isAnyAdsButtonAttached, providerPriorities, onShowAds
} = require("%rGui/ads/adsInternalState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { can_request_ads_consent } = require("%appGlobals/permissions.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")

let ads = is_android ? require("android.ads") : require("adsAndroidDbg.nut")
let sendAdsBqEvent = is_android ? require("%rGui/ads/sendAdsBqEvent.nut") : @(_, __, ___ = null) null
let { ADS_STATUS_LOADED, ADS_STATUS_SHOWN, ADS_STATUS_OK,
  isAdsInited, getProvidersStatus, addProviderInitWithPriority, setPriorityForProvider,
  isAdsLoaded, loadAds, showAds, requestConsent, showConsent
} = ads


let isInited = Watched(isAdsInited())
let isLoaded = Watched(isAdsLoaded())
let loadedProvider = hardPersistWatched("adsAndroid.loadedProvider", "")
let isAdsVisible = Watched(false)
let failInARow = hardPersistWatched("adsAndroid.failsInARow", 0)

let consent = hardPersistWatched("adsAndroid.consent", null)
let isConsentShowed = hardPersistWatched("adsAndroid.isConsentShowed", false)
let canLoad = Computed(@() (consent.get()?.canRequest ?? false) || !can_request_ads_consent.get())
let needAdsLoadExt = Computed(@() canLoad.get() && isInited.get() && needAdsLoad.get() && !isLoaded.get())
let needOpenConsent = keepref(Computed(@() can_request_ads_consent.get() && !isConsentShowed.get()
  && isAnyAdsButtonAttached.get()))

function initProviders() {
  if (!canLoad.get())
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
canLoad.subscribe(@(_) initProviders())

let statusNames = {}
let consentNames = {}
foreach(id, val in ads)
  if (type(val) != "integer")
    continue
  else if (id.startswith("ADS_STATUS_"))
    statusNames[val] <- id
  else if (id.startswith("CONSENT_"))
    consentNames[val] <- id
let getStatusName = @(v) statusNames?[v] ?? v
let getConsentName = @(v) consentNames?[v] ?? v

eventbus_subscribe("android.ads.onInit", function(msg) {
  let { status, provider } = msg
  if (status != ADS_STATUS_OK)
    return
  logA($"Provider {provider} inited")
  isInited(true)
})

eventbus_subscribe("android.ads.onConsentRequest", function(msg) {
  logA("Request consent result = ", msg.__merge({ status = getConsentName(msg?.status) }))
  sendUiBqEvent("ads_consent", { id = "request_result", status = getConsentName(msg?.status) })
  consent.set(msg)
})
eventbus_subscribe("android.ads.onShowConsent", function(msg) {
  logA("Show consent result = ", msg.__merge({ status = getConsentName(msg?.status) }))
  sendUiBqEvent("ads_consent", { id = "show_result", status = getConsentName(msg?.status) })
  consent.set(msg)
})

if (consent.get() == null)
  requestConsent(false)
needOpenConsent.subscribe(function(v) {
  if (!v)
    return
  sendUiBqEvent("ads_consent", { id = "request_on_enter_window_with_ads" })
  requestConsent(true)
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
  if (canLoad.get())
    return false
  sendUiBqEvent("ads_consent", { id = "show_on_try_watch_ads" })
  showConsent()
  return true
}

return {
  isAdsAvailable = Computed(@() true)
  isAdsVisible
  canShowAds = isLoaded
  showAdsForReward
  onTryShowNotAvailableAds
}
