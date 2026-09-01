from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "ios.platform" import getTrackingPermission, ATT_GRANTED
from "%sqstd/platform.nut" import is_android, is_ios
from "%appGlobals/consent.nut" import isTcfConsentEnabled
from "%appGlobals/loginState.nut" import isReadyForGoogleConsent, goodleConsent, isAuthorized
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent
from "%appGlobals/permissions.nut" import google_consent_enabled
from "types" import Integer


let logC = log_with_prefix("[consent] ")


let ump = is_ios || is_android ? (require_optional("consent.googleump") ?? require(is_ios ? "ios.ads" : "android.ads"))
  : require("%rGui/ads/byPlatform/adsAndroidDbg.nut")
let { requestConsent } = ump

let isGoogleConsentEnabled = keepref(Computed(@()
     google_consent_enabled.get()
  && !isTcfConsentEnabled.get()
  && (!is_ios || getTrackingPermission() == ATT_GRANTED)))

let consentNames = {}
foreach(id, val in ump)
  if (!(val instanceof Integer))
    continue
  else if (id.startswith("CONSENT_"))
    consentNames[val] <- id
let getConsentName = @(v) consentNames?[v] ?? v


function onConsentResponse(bq_id, msg) {
  let { status = "" } = msg
  logC("Google consent request result = ", msg.__merge({ status = getConsentName(status) }))
  sendUiBqEvent("ads_consent_google", { id = bq_id, status = getConsentName(status) })
  goodleConsent.set(msg.__merge({ isShowed = true }))
}

isAuthorized.subscribe(@(v) v ? null : goodleConsent.set(null))
isReadyForGoogleConsent.subscribe(function(isReady) {
  if (!isReady)
    return
  if (!isGoogleConsentEnabled.get()) {
    logC("Google consent disabled")
    goodleConsent.set({ isShowed = true, canRequest = true })
    return
  }
  requestConsent(true)
})

eventbus_subscribe("consent.googleump.onConsentRequest", @(msg) onConsentResponse("request_result", msg))
eventbus_subscribe("consent.googleump.onConsentShow",    @(msg) onConsentResponse("show_result", msg))

eventbus_subscribe(is_ios ?  "ios.ads.onConsentRequest" : "android.ads.onConsentRequest", @(msg) onConsentResponse("request_result", msg))
eventbus_subscribe(is_ios ? "ios.ads.onConsentShow" : "android.ads.onConsentShow",    @(msg) onConsentResponse("show_result", msg))

