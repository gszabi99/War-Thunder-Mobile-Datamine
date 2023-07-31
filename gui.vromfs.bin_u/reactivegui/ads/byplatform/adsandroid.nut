from "%globalsDarg/darg_library.nut" import *
let { send, subscribe } = require("eventbus")
let { setTimeout, resetTimeout } = require("dagor.workcycle")
let { getCountryCode } = require("auth_wt")
let ads = require("android.ads")
let { json_to_string, parse_json } = require("json")
let logA = log_with_prefix("[ADS] ")
let { is_android } = require("%sqstd/platform.nut")
let { needAdsLoad, rewardInfo, giveReward, onFinishShowAds, RETRY_LOAD_TIMEOUT, debugAdsWndParams
} = require("%rGui/ads/adsInternalState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let sendAdsBqEvent = require("%rGui/ads/sendAdsBqEvent.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let isDebug = !is_android
let DBG_PROVIDER = "pc_debug"
let debugAdsInited = persist("debugAdsInited", @() {})
local isDebugAdsLoaded = false
let { ADS_STATUS_LOADED, ADS_STATUS_SHOWN, ADS_STATUS_NOT_INITED, ADS_STATUS_DISMISS, ADS_STATUS_OK
} = ads
let { isAdsInited, getProvidersStatus, addProviderInitWithPriority, setPriorityForProvider,
  isAdsLoaded, loadAds, showAds
} = !isDebug ? ads
  : {
      isAdsInited = @() debugAdsInited.findvalue(@(v) v) ?? false
      getProvidersStatus = @() json_to_string(
        debugAdsInited.map(@(isInited, provider) { provider, isInited })
          .values())
      setPriorityForProvider = @(_, __) null
      function addProviderInitWithPriority(provider, _, __) {
        debugAdsInited[provider] <- true
        setTimeout(0.1, @() send("android.ads.onInit", { status = ADS_STATUS_OK, provider }))
      }
      isAdsLoaded = @() isDebugAdsLoaded
      function loadAds() {
        isDebugAdsLoaded = false
        setTimeout(5.0, function() {
          isDebugAdsLoaded = debugAdsInited.findvalue(@(v) v) ?? false
          send("android.ads.onLoad",
            { status = isDebugAdsLoaded ? ADS_STATUS_LOADED : ADS_STATUS_NOT_INITED, provider = DBG_PROVIDER })
        })
      }
      function showAds() {
        send("android.ads.onShow", { status = ADS_STATUS_SHOWN, provider = DBG_PROVIDER })
        debugAdsWndParams({
          rewardEvent = "android.ads.onReward"
          rewardData = { amount = 1, type = "debug", provider = DBG_PROVIDER }
          finishEvent = "android.ads.onShow"
          finishData = { status = ADS_STATUS_DISMISS, provider = DBG_PROVIDER }
        })
      }
    }

let isInited = Watched(isAdsInited())
let isLoaded = Watched(isAdsLoaded())
let needAdsLoadExt = Computed(@() isInited.value && needAdsLoad.value && !isLoaded.value)
let allProviders = keepref(Computed(@() !isLoggedIn.value ? {}
  : (serverConfigs.value?.adsCfg.android ?? {})))

let function initProviders(providers) {
  if (providers.len() == 0)
    return
  let countryCode = getCountryCode()
  logA($"Init providers for {countryCode}")
  let pStatus = parse_json(getProvidersStatus())
  let initedProviders = {}
  foreach (info in pStatus)
    if (info.isInited)
      initedProviders[info.provider] <- true

  foreach (id, _ in initedProviders)
    if (id not in providers)
      setPriorityForProvider(id, -1) //switch of provider missing in config

  foreach (id, p in providers) {
    let priority = p?.priorityByRegion[countryCode] ?? p.priority
    if (id in initedProviders)
      setPriorityForProvider(id, priority)
    else if (priority >= 0)
      addProviderInitWithPriority(id, p.key, priority)
  }
}
initProviders(allProviders.value)
allProviders.subscribe(initProviders)

subscribe("android.ads.onInit", function(msg) {
  let { status, provider } = msg
  if (status != ADS_STATUS_OK)
    return
  logA($"Provider {provider} inited")
  isInited(true)
})

let function startLoading() {
  logA($"Start loading")
  loadAds()
  sendAdsBqEvent("load_request", "", false)
}
if (needAdsLoadExt.value)
  startLoading()
needAdsLoadExt.subscribe(function(v) {
  if (v)
    startLoading()
})

let function retryLoad() {
  if (!needAdsLoadExt.value)
    return
  logA($"Retry loading")
  loadAds()
  sendAdsBqEvent("load_retry", "", false)
}

subscribe("android.ads.onLoad", function (params) {
  let { status, provider = "unknown" } = params
  logA($"Ads: onLoad {status}")
  isLoaded(status == ADS_STATUS_LOADED && isAdsLoaded())
  if (isLoaded.value) {
    sendAdsBqEvent("loaded", provider, false)
    return
  }

  if (needAdsLoadExt.value)
    resetTimeout(RETRY_LOAD_TIMEOUT, retryLoad)
  sendAdsBqEvent("load_failed", provider, false)
})

subscribe("android.ads.onShow", function (params) { //we got this event on start ads show, and on finish
  let { status, provider = "unknown" } = params
  logA($"Ads: onShow {status}")
  if (status == ADS_STATUS_SHOWN)
    sendAdsBqEvent("show_start", provider)
  else {
    isLoaded(false)
    onFinishShowAds()
    sendAdsBqEvent("show_stop", provider)
  }
})

subscribe("android.ads.onReward", function (params) {
  let { provider = "unknown" } = params
  logA($"Ads: onReward {params.amount} {params.type}")
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
