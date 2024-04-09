from "%globalsDarg/darg_library.nut" import *
let logC = log_with_prefix("[Consent] ")
let { eventbus_subscribe } = require("eventbus")
let { can_request_ads_consent } = require("%appGlobals/permissions.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { is_pc } = require("%sqstd/platform.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { isAnyAdsButtonAttached } = require("%rGui/ads/adsInternalState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let consent = is_pc ? require("consentDbg.nut") : (require_optional("consent") ?? {})
let { isConsentAcceptedForAll = @() true, isGDPR = @() false, showConsentForm = @(_) null, isConsentInited = @() true } = consent

let isConsentSuggestShowed = hardPersistWatched("conent.showed", false)
let isConsentRequired = hardPersistWatched("consent.required", isGDPR() && isConsentInited() && !isConsentAcceptedForAll())
let consentUpdated = hardPersistWatched("consent.updated", 0)

let needOpenConsent = keepref(Computed(@() can_request_ads_consent.get() && isConsentRequired.get()
  && isAnyAdsButtonAttached.get() && !isConsentSuggestShowed.get()))

let consentNames = {}
foreach(id, val in consent)
  if (type(val) != "integer")
    continue
  else if (id.startswith("CONSENT_"))
    consentNames[val] <- id
let getConsentName = @(v) consentNames?[v] ?? v

let function showConsent(force) {
  if (isGDPR())
    showConsentForm(force)
}

needOpenConsent.subscribe(function(v) {
  if (!v)
    return
  sendUiBqEvent("ads_consent", { id = "request_show_consent_suggest" })
  isConsentSuggestShowed.set(true)
  openMsgBox({
    uid = "consentSuggestMsgBox"
    text = loc("msgBox/consent_txt")
    buttons = [
      { text = loc("msgbox/btn_later"), id = "cancel", isCancel = true }
      { text = loc("msgBox/btn_open_consent"), id = "open_consent", styleId = "PRIMARY", isDefault = true, cb = @() showConsent(true) }
    ]
  })
})

eventbus_subscribe("consent.onConsentShow", function(msg) {
  if (!isGDPR())
    return
  logC("state = ", msg.__merge({ status = getConsentName(msg?.status) }))
  logC($"all accepted = {isConsentAcceptedForAll()}")
  sendUiBqEvent("ads_consent", { id = "show_result", status = getConsentName(msg?.status) })
  sendUiBqEvent("ads_consent", { id = "accept_all", status = isConsentAcceptedForAll() ? "true" : "false" })

  isConsentRequired.set(isGDPR() && isConsentInited() && !isConsentAcceptedForAll())
  consentUpdated.set(consentUpdated.get() + 1)
})

return {
  consentUpdated
  showConsent
  isGDPR
}
