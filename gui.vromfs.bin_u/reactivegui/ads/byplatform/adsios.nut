from "%globalsDarg/darg_library.nut" import *
let { send, subscribe } = require("eventbus")
let { setTimeout, resetTimeout, clearTimer } = require("dagor.workcycle")
let { getCountryCode } = require("auth_wt")
let ads = require("ios.ads")
let { json_to_string, parse_json } = require("json")
let logA = log_with_prefix("[ADS] ")
let { is_ios } = require("%sqstd/platform.nut")
let { needAdsLoad, rewardInfo, giveReward, onFinishShowAds, RETRY_LOAD_TIMEOUT, RETRY_INC_TIMEOUT, debugAdsWndParams
} = require("%rGui/ads/adsInternalState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let sendAdsBqEvent = require("%rGui/ads/sendAdsBqEvent.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let isDebug = !is_ios
let DBG_PROVIDER = "pc_debug"
let { DBGLEVEL } = require("dagor.system")
let { ADS_STATUS_LOADED = 6, ADS_STATUS_SHOWN = 5, ADS_STATUS_NOT_INITED = 1, ADS_STATUS_DISMISS = 4, ADS_STATUS_OK = 8
} = ads
let debugAdsInited = persist("debugAdsInited", @() {})
local isDebugAdsLoaded = false
let { setTestingMode, isAdsInited, getProvidersStatus, addProviderInitWithPriority, setPriorityForProvider,
  isAdsLoaded, loadAds, showAds
} = !isDebug ? ads
: {
      setTestingMode = @(_) null
      isAdsInited = @() debugAdsInited.findvalue(@(v) v) ?? false
      getProvidersStatus = @() json_to_string(
        debugAdsInited.map(@(provider, isInited) { provider, isInited })
          .values())
      setPriorityForProvider = @(_, __) null
      function addProviderInitWithPriority(provider, _, __) {
        debugAdsInited[provider] <- true
        setTimeout(0.1, @() send("ios.ads.onInit", { status = ADS_STATUS_OK, provider }))
      }
      isAdsLoaded = @() isDebugAdsLoaded
      function loadAds() {
        isDebugAdsLoaded = false
        setTimeout(2.0, function() {
          isDebugAdsLoaded = false
          send("ios.ads.onLoad",  //simulate fail ads
            { status = ADS_STATUS_DISMISS, provider = "pc_debug_fail" })
          setTimeout(3.0, function() {
            isDebugAdsLoaded = debugAdsInited.findvalue(@(v) v) ?? false
            send("ios.ads.onLoad",
              { status = isDebugAdsLoaded ? ADS_STATUS_LOADED : ADS_STATUS_NOT_INITED, provider = DBG_PROVIDER })
          }, {})
        }, {})
      }
      function showAds() {
        send("ios.ads.onShow", { status = ADS_STATUS_SHOWN, provider = DBG_PROVIDER })
        debugAdsWndParams({
          rewardEvent = "ios.ads.onReward"
          rewardData = { amount = 1, type = "debug", provider = DBG_PROVIDER }
          finishEvent = "ios.ads.onShow"
          finishData = { status = ADS_STATUS_DISMISS, provider = DBG_PROVIDER }
        })
      }
    }

let isInited = Watched(isAdsInited())
let isLoaded = Watched(isAdsLoaded())
let failInARow = hardPersistWatched("adsAndroid.failsInARow", 0)
let needAdsLoadExt = Computed(@() isInited.value && needAdsLoad.value && !isLoaded.value)
let allProviders = keepref(Computed(@() !isLoggedIn.value ? {}
  : serverConfigs.value?.adsCfg.iOS ?? {}))

let function initProviders(providers) {
  if (providers.len() == 0) {
    logA("Empty ad provider list received")
    return
  }
  setTestingMode(DBGLEVEL > 0)
  let countryCode = getCountryCode()
  logA($"Init providers for {countryCode}")
  let pStatus = parse_json(getProvidersStatus())
  let initedProviders = {}
  foreach(info in pStatus)
    if (info.isInited)
      initedProviders[info.provider] <- true

  foreach(id, _ in initedProviders)
    if (id not in providers)
      setPriorityForProvider(id, -1) //switch of provider missing in config

  foreach(id, p in providers) {
    let priority = p?.priorityByRegion[countryCode] ?? p.priority
    if (id in initedProviders)
      setPriorityForProvider(id, priority)
    else if (priority >= 0)
      addProviderInitWithPriority(id, p.key, priority)
  }
}
initProviders(allProviders.value)
allProviders.subscribe(initProviders)

let statusNames = {}
foreach(id, val in ads)
  if (type(val) == "integer" && id.startswith("ADS_STATUS_"))
    statusNames[val] <- id
let getStatusName = @(v) statusNames?[v] ?? v

subscribe("ios.ads.onInit", function(msg) {
  let { status, provider } = msg
  if (status != ADS_STATUS_OK)
    return
  logA($"Provider {provider} inited")
  isInited(true)
})

local isLoadStarted = false
let function startLoading() {
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
let function retryLoad() {
  isRetryQueued = false
  if (!needAdsLoadExt.value || isLoadStarted)
    return
  logA($"Retry loading")
  isLoadStarted = true
  loadAds()
  sendAdsBqEvent("load_retry", "", false)
}

subscribe("ios.ads.onLoad",function (params) {
  let { status, provider = "unknown" } = params
  logA($"onLoad {getStatusName(status)}")
  isLoadStarted = false
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

subscribe("ios.ads.onShow",function (params) { //we got this event on start ads show, and on finish
  let { status, provider = "unknown" } = params
  logA($"onShow {getStatusName(status)}:", rewardInfo.value?.bqId, rewardInfo.value?.bqParams)
  if (status == ADS_STATUS_SHOWN)
    sendAdsBqEvent("show_start", provider)
  else {
    isLoaded(false)
    onFinishShowAds()
    sendAdsBqEvent("show_stop", provider)
  }
})

subscribe("ios.ads.onReward", function (params) {
  let { provider = "unknown" } = params
  logA($"onReward {params.amount} {params.type}:", rewardInfo.value?.bqId, rewardInfo.value?.bqParams)
  giveReward()
  sendAdsBqEvent("receive_reward", provider)
})


let function showAdsForReward(rInfo) {
  if (!isLoaded.value)
    return
  rewardInfo(rInfo)
  showAds()
}

return {
  isAdsAvailable = isInited
  canShowAds = isLoaded
  showAdsForReward
}
