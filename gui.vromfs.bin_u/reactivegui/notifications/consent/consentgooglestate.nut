from "%globalsDarg/darg_library.nut" import *
let logC = log_with_prefix("[consent] ")

let { eventbus_subscribe } = require("eventbus")
let { is_android, is_ios } = require("%sqstd/platform.nut")

let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { can_request_ads_consent } = require("%appGlobals/permissions.nut")
let ads = is_ios ? require("ios.ads")
  : is_android ? require("android.ads")
  : require("%rGui/ads/byPlatform/adsAndroidDbg.nut")
let { CONSENT_REQUEST_NOT_REQUIRED, CONSENT_REQUEST_OBTAINED, requestConsent } = ads
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")

let consent = hardPersistWatched("google.consent", null)
let isGoogleConsentShowed = hardPersistWatched("google.isGoogleConsentShowed", false)
let isAdsAllowedForRequest = Computed(@() (consent.get()?.canRequest ?? false) || !can_request_ads_consent.get())

let consentNames = {}
foreach(id, val in ads)
  if (type(val) != "integer")
    continue
  else if (id.startswith("CONSENT_"))
    consentNames[val] <- id
let getConsentName = @(v) consentNames?[v] ?? v


function onConsentResponse(bq_id, msg) {
  logC("Request consent result = ", msg.__merge({ status = getConsentName(msg?.status) }))
  sendUiBqEvent("ads_consent", { id = bq_id, status = getConsentName(msg?.status) })
  consent.set(msg)
  isGoogleConsentShowed(msg?.status == CONSENT_REQUEST_NOT_REQUIRED || msg?.status == CONSENT_REQUEST_OBTAINED)
}

eventbus_subscribe("android.ads.onConsentRequest", @(msg) onConsentResponse("request_result", msg))
eventbus_subscribe("android.ads.onShowConsent",    @(msg) onConsentResponse("show_result", msg))
eventbus_subscribe("ios.ads.onConsentRequest",     @(msg) onConsentResponse("request_result", msg))
eventbus_subscribe("ios.ads.onShowConsent",        @(msg) onConsentResponse("show_result", msg))

return {
  isGoogleConsentShowed
  isAdsAllowedForRequest
  googleConsent = consent
  requestGoogleConsent = requestConsent
}