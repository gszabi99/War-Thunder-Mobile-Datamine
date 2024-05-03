from "%globalsDarg/darg_library.nut" import *
let logC = log_with_prefix("[Consent] ")
let { eventbus_subscribe } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { can_request_ads_consent } = require("%appGlobals/permissions.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { is_pc } = require("%sqstd/platform.nut")
let { openMsgBox, closeMsgBox } = require("%rGui/components/msgBox.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")

let { isAnyAdsButtonAttached } = require("%rGui/ads/adsInternalState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let consent = is_pc ? require("consentDbg.nut") : (require_optional("consent") ?? {})
let { isConsentAcceptedForAll = @() true, isGDPR = @() false, showConsentForm = @(_) null, isConsentInited = @() true } = consent


let MSG_UID = "consentSuggestMsgBox"

let isConsentSuggestShowed = hardPersistWatched("consent.showed", false)
let isConsentRequired = hardPersistWatched("consent.required", isGDPR() && isConsentInited() && !isConsentAcceptedForAll())
let consentUpdated = hardPersistWatched("consent.updated", 0)

let needOpenConsent = Computed(@() can_request_ads_consent.get() && isConsentRequired.get()
  && isAnyAdsButtonAttached.get() && !isConsentSuggestShowed.get())

let shouldOpenConsent = keepref(Computed(@() needOpenConsent.get() && !hasModalWindows.get()))

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

function openConsent() {
  if (!needOpenConsent.get())
    return

  sendUiBqEvent("ads_consent", { id = "request_show_consent_suggest" })
  openMsgBox({
    uid = MSG_UID
    text = loc("msgBox/consent_txt")
    buttons = [
      { text = loc("msgbox/btn_later"), id = "cancel", isCancel = true
        cb = @() isConsentSuggestShowed.set(true)
      }
      { text = loc("msgBox/btn_open_consent"), id = "open_consent", styleId = "PRIMARY", isDefault = true,
        function cb() {
          isConsentSuggestShowed.set(true)
          showConsent(true)
        }
      }
    ]
  })
}

shouldOpenConsent.subscribe(@(v) v ? deferOnce(openConsent) : null)
needOpenConsent.subscribe(@(v) !v ? closeMsgBox(MSG_UID) : null)

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
