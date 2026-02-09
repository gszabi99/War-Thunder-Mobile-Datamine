from "%globalsDarg/darg_library.nut" import *
let logC = log_with_prefix("[consent] ")

let { eventbus_subscribe } = require("eventbus")
let { is_android, is_ios } = require("%sqstd/platform.nut")
let ads = is_ios ? require("ios.ads")
  : is_android ? require("android.ads")
  : require("%rGui/ads/byPlatform/adsAndroidDbg.nut")
let { requestConsent } = ads
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isReadyForGoogleConsent, goodleConsent, isAuthorized } = require("%appGlobals/loginState.nut")
let { tcf_consent_enabled } = require("%appGlobals/permissions.nut")

let consentNames = {}
foreach(id, val in ads)
  if (type(val) != "integer")
    continue
  else if (id.startswith("CONSENT_"))
    consentNames[val] <- id
let getConsentName = @(v) consentNames?[v] ?? v


function onConsentResponse(bq_id, msg) {
  let { status = "" } = msg
  logC("Request google consent result = ", msg.__merge({ status = getConsentName(status) }))
  sendUiBqEvent("ads_consent_google", { id = bq_id, status = getConsentName(status) })
  goodleConsent.set(msg.__merge({ isShowed = true }))
}

isAuthorized.subscribe(@(v) v ? null : goodleConsent.set(null))
isReadyForGoogleConsent.subscribe(function(isReady) {
  if (!isReady)
    return
  if (tcf_consent_enabled.get()) {
    logC("Google consent disabled")
    goodleConsent.set({ isShowed = true, canRequest = false })
    return
  }
  requestConsent(true)
})

eventbus_subscribe("android.ads.onConsentRequest", @(msg) onConsentResponse("request_result", msg))
eventbus_subscribe("android.ads.onShowConsent",    @(msg) onConsentResponse("show_result", msg))
eventbus_subscribe("ios.ads.onConsentRequest",     @(msg) onConsentResponse("request_result", msg))
eventbus_subscribe("ios.ads.onShowConsent",        @(msg) onConsentResponse("show_result", msg))
