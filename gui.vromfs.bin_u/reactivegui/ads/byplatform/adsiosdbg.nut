from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { eventbus_send } = require("eventbus")
let { setTimeout } = require("dagor.workcycle")
let ads = require("ios.ads")
let { ADS_STATUS_LOADED = 6, ADS_STATUS_SHOWN = 5, ADS_STATUS_NOT_INITED = 1, ADS_STATUS_DISMISS = 4, ADS_STATUS_OK = 8,
  CONSENT_REQUEST_NOT_REQUIRED = 1, CONSENT_REQUEST_OBTAINED = 3, CONSENT_REQUEST_REQUIRED = 2, CONSENT_REQUEST_UNKNOWN = 0
} = ads
let { object_to_json_string } = require("json")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { debugAdsWndParams } = require("%rGui/ads/adsInternalState.nut")


let debugAdsInited = persist("debugAdsInited", @() {})
let debugConsentRequired = hardPersistWatched("adsIOS.debugConsentRequired", false)
let debugConsentApprove = hardPersistWatched("adsIOS.debugConsentRequested", null)
let priorities = hardPersistWatched("adsIOS.debug.priorities", {})
let loadedProvider = hardPersistWatched("adsIOS.debug.loadedProvider", "")
local isDebugAdsLoaded = false
local debugAdsFailsCount = 0

let showConsent = @(eventId) setTimeout(0.01, @() openFMsgBox({
  text = "Debug Google Consent:\nDo you approve download ads?"
  buttons = [
    { id = "cancel", eventId = "adsIOS_cancelConsent", context = eventId, isCancel = true }
    { text = "Approve", eventId = "adsIOS_approveConsent", context = eventId, isDefault = true,
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
  setTimeout(0.01, @() eventbus_send(eventId, mkConsentResult()))

let requestConsent = @(showIfRequire)
  showIfRequire && debugConsentRequired.get() && debugConsentApprove.get() == null
    ? showConsent("ios.ads.onConsentRequest")
    : sendConsentResult("ios.ads.onConsentRequest")

subscribeFMsgBtns({
  function adsIOS_cancelConsent(eventId) {
    debugConsentApprove.set(false)
    sendConsentResult(eventId)
  }
  function adsIOS_approveConsent(eventId) {
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
  ADS_STATUS_LOADED
  ADS_STATUS_SHOWN
  ADS_STATUS_NOT_INITED
  ADS_STATUS_DISMISS
  ADS_STATUS_OK

  CONSENT_REQUEST_NOT_REQUIRED
  CONSENT_REQUEST_OBTAINED
  CONSENT_REQUEST_REQUIRED
  CONSENT_REQUEST_UNKNOWN

  setTestingMode = @(_) null
  isAdsInited = @() debugAdsInited.findvalue(@(v) v) ?? false
  getProvidersStatus = @() object_to_json_string(
    debugAdsInited.map(@(isInited, provider) { provider, isInited })
      .values())
  setPriorityForProvider = @(provider, priority) priorities.mutate(@(v) v[provider] <- priority)
  function addProviderInitWithPriority(provider, _, priority) {
    debugAdsInited[provider] <- true
    priorities.mutate(@(v) v[provider] <- priority)
    setTimeout(0.1, @() eventbus_send("ios.ads.onInit", { status = ADS_STATUS_OK, provider }))
  }
  isAdsLoaded = @() isDebugAdsLoaded
  function loadAds() {
    foreach (p, _ in sortProviderPriority(priorities.get())) {
      let provider = p
      if (debugAdsFailsCount <= 0) {
        setTimeout(3.0, @() sendSuccessedResponse(provider), {})
        break
      }
      debugAdsFailsCount--
      setTimeout(1.0, @() eventbus_send("ios.ads.onLoad",
        { status = ADS_STATUS_DISMISS, provider }), {})
    }
  }
  function showAds() {
    eventbus_send("ios.ads.onShow", { status = ADS_STATUS_SHOWN, provider = loadedProvider.get() })
    debugAdsWndParams({
      rewardEvent = "ios.ads.onReward"
      rewardData = { amount = 1, type = "debug", provider = loadedProvider.get() }
      finishEvent = "ios.ads.onShow"
      finishData = { status = ADS_STATUS_DISMISS, provider = loadedProvider.get() }
    })
  }
  requestConsent
  showConsent = @() showConsent("ios.ads.onShowConsent")
})