from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { setTimeout } = require("dagor.workcycle")
let ads = require("android.ads")
let { ADS_STATUS_LOADED, ADS_STATUS_SHOWN, ADS_STATUS_NOT_INITED, ADS_STATUS_DISMISS, ADS_STATUS_OK} = ads
let { json_to_string } = require("json")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { debugAdsWndParams } = require("%rGui/ads/adsInternalState.nut")
let { chooseRandom } = require("%sqstd/rand.nut")


let debugAdsInited = persist("debugAdsInited", @() {})
let priorities = hardPersistWatched("adsAndroid.debug.priorities", {})
let loadedProvider = hardPersistWatched("adsAndroid.debug.loadedProvider", "")
local isDebugAdsLoaded = false

function calcLoadedProvider(list) {
  local priority = -1
  local allowed = []
  foreach(id, value in list) {
    if (value < 0 || value < priority)
      continue
    if (value == priority)
      allowed.append(id)
    else {
      allowed = [id]
      priority = value
    }
  }
  return allowed.len() == 0 ? null : chooseRandom(allowed)
}

return ads.__merge({
  isAdsInited = @() debugAdsInited.findvalue(@(v) v) ?? false
  getProvidersStatus = @() json_to_string(
    debugAdsInited.map(@(isInited, provider) { provider, isInited })
      .values())
  setPriorityForProvider = @(provider, priority) priorities.mutate(@(v) v[provider] <- priority)
  function addProviderInitWithPriority(provider, _, priority) {
    debugAdsInited[provider] <- true
    priorities.mutate(@(v) v[provider] <- priority)
    setTimeout(0.1, @() eventbus_send("android.ads.onInit", { status = ADS_STATUS_OK, provider }))
  }
  isAdsLoaded = @() isDebugAdsLoaded
  function loadAds() {
    isDebugAdsLoaded = false
    setTimeout(2.0, function() {
      isDebugAdsLoaded = false
      eventbus_send("android.ads.onLoad",  //simulate fail ads
        { status = ADS_STATUS_DISMISS, provider = "pc_debug_fail" })
      if (priorities.get().findvalue(@(v) v >= 0) == null)
        return
      setTimeout(3.0, function() {
        let provider = calcLoadedProvider(priorities.get())
        if (provider == null)
          return
        isDebugAdsLoaded = debugAdsInited.findvalue(@(v) v) ?? false
        loadedProvider.set(provider)
        eventbus_send("android.ads.onLoad",
          { status = isDebugAdsLoaded ? ADS_STATUS_LOADED : ADS_STATUS_NOT_INITED, provider = loadedProvider.get() })
      }, {})
    }, {})
  }
  function showAds() {
    eventbus_send("android.ads.onShow", { status = ADS_STATUS_SHOWN, provider = loadedProvider.get() })
    debugAdsWndParams({
      rewardEvent = "android.ads.onReward"
      rewardData = { amount = 1, type = "debug", provider = loadedProvider.get() }
      finishEvent = "android.ads.onShow"
      finishData = { status = ADS_STATUS_DISMISS, provider = loadedProvider.get() }
    })
  }
})