from "%globalsDarg/darg_library.nut" import *
let logA = log_with_prefix("[ADS] ")
let { eventbus_subscribe } = require("eventbus")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { parse_json } = require("json")
let { DBGLEVEL } = require("dagor.system")
let { is_ios } = require("%sqstd/platform.nut")
let { needAdsLoad, rewardInfo, giveReward, onFinishShowAds, RETRY_LOAD_TIMEOUT, RETRY_INC_TIMEOUT,
  providerPriorities, onShowAds
} = require("%rGui/ads/adsInternalState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let ads = is_ios ? require("ios.ads") : require("adsIosDbg.nut")
let sendAdsBqEvent = is_ios ? require("%rGui/ads/sendAdsBqEvent.nut") : @(_, __, ___ = null) null
let { ADS_STATUS_LOADED, ADS_STATUS_SHOWN, ADS_STATUS_OK,
  setTestingMode, isAdsInited, getProvidersStatus, addProviderInitWithPriority, setPriorityForProvider,
  isAdsLoaded, loadAds, showAds
} = ads

let {consentUpdated} = require("%rGui/consent/consentState.nut")

let isInited = Watched(isAdsInited())
let isLoaded = Watched(isAdsLoaded())
let loadedProvider = hardPersistWatched("adsIos.loadedProvider", "")
let isAdsVisible = Watched(false)
let failInARow = hardPersistWatched("adsIos.failsInARow", 0)

let needAdsLoadExt = Computed(@() isInited.get() && needAdsLoad.get() && !isLoaded.get())

function initProviders() {
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

consentUpdated.subscribe(function(_) {
  if (isLoaded.get() || !needAdsLoadExt.get())
    return
  clearTimer(retryLoad)
  failInARow(0)
  retryLoad()
})

eventbus_subscribe("ios.ads.onLoad",function (params) {
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

eventbus_subscribe("ios.ads.onShow",function (params) { //we got this event on start ads show, and on finish
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

eventbus_subscribe("ios.ads.onReward", function (params) {
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

return {
  isAdsAvailable = isInited
  isAdsVisible
  canShowAds = isLoaded
  showAdsForReward
}
