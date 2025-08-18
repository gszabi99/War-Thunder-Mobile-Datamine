from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { eventbus_send } = require("eventbus")
let { setTimeout } = require("dagor.workcycle")
let ads = require("android.ads")
let { ADS_STATUS_LOADED, ADS_STATUS_SHOWN, ADS_STATUS_NOT_INITED, ADS_STATUS_DISMISS, ADS_STATUS_OK,
  CONSENT_REQUEST_NOT_REQUIRED, CONSENT_REQUEST_OBTAINED, CONSENT_REQUEST_REQUIRED
} = ads
let { object_to_json_string } = require("json")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { debugAdsWndParams } = require("%rGui/ads/adsInternalState.nut")


let debugAdsInited = persist("debugAdsInited", @() {})
let debugConsentRequired = hardPersistWatched("adsAndroid.debugConsentRequired", false)
let debugConsentApprove = hardPersistWatched("adsAndroid.debugConsentRequested", null)
let priorities = hardPersistWatched("adsAndroid.debug.priorities", {})
let loadedProvider = hardPersistWatched("adsAndroid.debug.loadedProvider", "")
local isDebugAdsLoaded = false
local debugAdsFailsCount = 0

let showConsent = @(eventId) setTimeout(0.01, @() openFMsgBox({
  text = "Debug Google Consent:\nDo you approve download ads?"
  buttons = [
    { id = "cancel", eventId = "adsAndroid_cancelConsent", context = eventId, isCancel = true }
    { text = "Approve", eventId = "adsAndroid_approveConsent", context = eventId, isDefault = true,
      styleId = "PRIMARY" }
  ]
}))

let mkConsentResult = @() {
  status = !debugConsentRequired.get() ? CONSENT_REQUEST_NOT_REQUIRED
    : debugConsentApprove.get() == null ? CONSENT_REQUEST_REQUIRED
    : CONSENT_REQUEST_OBTAINED
  canRequest = !debugConsentRequired.get() || debugConsentApprove.get()
  canShowPrivacy = true
  errorCode = ""
}

let sendConsentResult = @(eventId)
  setTimeout(0.01, @() eventbus_send(eventId, mkConsentResult()))

let requestConsent = @(showIfRequire)
  showIfRequire && debugConsentRequired.get() && debugConsentApprove.get() == null
    ? showConsent("android.ads.onConsentRequest")
    : sendConsentResult("android.ads.onConsentRequest")

subscribeFMsgBtns({
  function adsAndroid_cancelConsent(eventId) {
    debugConsentApprove.set(false)
    sendConsentResult(eventId)
  }
  function adsAndroid_approveConsent(eventId) {
    debugConsentApprove.set(true)
    sendConsentResult(eventId)
  }
})

function sortProviderPriority(list) {
  local res = []
  foreach(id, value in list)
    res.append({ id = id, value = value })
  return res.sort(@(a, b) b.value <=> a.value).map(@(v) v.id)
}

function sendSuccessedResponse(provider) {
  isDebugAdsLoaded = debugAdsInited.findvalue(@(v) v) ?? false
  loadedProvider.set(provider)
  eventbus_send("android.ads.onLoad",
    { status = isDebugAdsLoaded ? ADS_STATUS_LOADED : ADS_STATUS_NOT_INITED, provider = loadedProvider.get() })
}

register_command(function(count) {
    debugAdsFailsCount = count
    log($"Fake debug fails seted: {debugAdsFailsCount}")
  },
  "ads.set_fake_debug_fails_for_provider")

return ads.__merge({
  isAdsInited = @() debugAdsInited.findvalue(@(v) v) ?? false
  getProvidersStatus = @() object_to_json_string(
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
    foreach (p in sortProviderPriority(priorities.get())) {
      let provider = p
      if (debugAdsFailsCount <= 0) {
        setTimeout(3.0, @() sendSuccessedResponse(provider), {})
        break
      }
      debugAdsFailsCount--
      setTimeout(1.0, @() eventbus_send("android.ads.onLoad",
        { status = ADS_STATUS_DISMISS, provider }), {})
    }
  }
  function showAds() {
    eventbus_send("android.ads.onShow", { status = ADS_STATUS_SHOWN, provider = loadedProvider.get() })
    debugAdsWndParams.set({
      rewardEvent = "android.ads.onReward"
      rewardData = { amount = 1, type = "debug", provider = loadedProvider.get() }
      finishEvent = "android.ads.onShow"
      finishData = { status = ADS_STATUS_DISMISS, provider = loadedProvider.get() }
    })
  }
  requestConsent
  showConsent = @() showConsent("android.ads.onShowConsent")
})