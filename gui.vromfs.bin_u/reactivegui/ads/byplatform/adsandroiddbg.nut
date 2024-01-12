from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { setTimeout } = require("dagor.workcycle")
let ads = require("android.ads")
let { ADS_STATUS_LOADED, ADS_STATUS_SHOWN, ADS_STATUS_NOT_INITED, ADS_STATUS_DISMISS, ADS_STATUS_OK,
  CONSENT_REQUEST_NOT_REQUIRED = 1, CONSENT_REQUEST_OBTAINED = 3, CONSENT_REQUEST_REQUIRED = 2, CONSENT_REQUEST_UNKNOWN = 0
} = ads
let { json_to_string } = require("json")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { debugAdsWndParams } = require("%rGui/ads/adsInternalState.nut")


let DBG_PROVIDER = "pc_debug"
let debugAdsInited = persist("debugAdsInited", @() {})
let debugConsentRequired = hardPersistWatched("adsAndroid.debugConsentRequired", false)
let debugConsentApprove = hardPersistWatched("adsAndroid.debugConsentRequested", null)
local isDebugAdsLoaded = false

let showConsent = @(eventId) setTimeout(0.01, @() openFMsgBox({
  text = "Debug Contest:\nDo you approve download ads?"
  buttons = [
    { id = "cancel", eventId = "adsAndroid_cancelConsent", context = eventId, isCancel = true }
    { text = "Approve", eventId = "adsAndroid_approveConsent", context = eventId, isDefault = true,
      styleId = "PRIMARY" }
  ]
}))

let mkConsentResult = @() {
  status = !debugConsentRequired.get() ? CONSENT_REQUEST_NOT_REQUIRED
    : debugConsentApprove.get() == null ? CONSENT_REQUEST_REQUIRED
    : debugConsentApprove.get() ? CONSENT_REQUEST_OBTAINED
    : CONSENT_REQUEST_UNKNOWN
  canRequest = !debugConsentRequired.get() || debugConsentApprove.get()
  canShowPrivacy = true
  errorCode = ""
}

let sendConsentResult = @(eventId)
  setTimeout(0.01, @() send(eventId, mkConsentResult()))

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

return ads.__merge({
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
    setTimeout(2.0, function() {
      isDebugAdsLoaded = false
      send("android.ads.onLoad",  //simulate fail ads
        { status = ADS_STATUS_DISMISS, provider = "pc_debug_fail" })
      setTimeout(3.0, function() {
        isDebugAdsLoaded = debugAdsInited.findvalue(@(v) v) ?? false
        send("android.ads.onLoad",
          { status = isDebugAdsLoaded ? ADS_STATUS_LOADED : ADS_STATUS_NOT_INITED, provider = DBG_PROVIDER })
      }, {})
    }, {})
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
  requestConsent
  showConsent = @() showConsent("android.ads.onShowConsent")
})