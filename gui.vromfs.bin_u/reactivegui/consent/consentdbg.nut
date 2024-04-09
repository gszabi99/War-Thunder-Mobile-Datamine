from "%globalsDarg/darg_library.nut" import *
let { setTimeout } = require("dagor.workcycle")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { eventbus_send } = require("eventbus")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let consent = require_optional("consent") ?? {}
let { CONSENT_GIVEN = 0, CONSENT_NOT_REQUIRED = 1 } = consent

let debugConsentGDPR = hardPersistWatched("consent.debugConsentGDPR", true)
let debugConsentGiven = hardPersistWatched("consent.debugConsentGiven", false)
let debugConsentAcceptedAllDefault = hardPersistWatched("consent.debugConsentAcceptedAllDefault", true)

let function onPartialConsent() {
  debugConsentGiven.set(true)
  debugConsentAcceptedAllDefault.set(false)
  eventbus_send("consent.onConsentShow", { status = CONSENT_GIVEN } )
}

let function onFullConsent() {
  debugConsentGiven.set(true)
  debugConsentAcceptedAllDefault.set(true)
  eventbus_send("consent.onConsentShow", { status = CONSENT_GIVEN } )
}

let showConsentFormDbg = @(force) setTimeout(0.01, @() !force
  ? eventbus_send("consent.onConsentShow", { status = CONSENT_NOT_REQUIRED } )
  : openMsgBox({
    text = "Debug Consent:\nUser choose Full consent approve or partial?"
    buttons = [
      { text = "Partial consent", cb = @() onPartialConsent() }
      { text = "Full consent",  cb = @() onFullConsent() }
    ]
  }))


return consent.__merge({
  showConsentForm =  @(force) showConsentFormDbg(force)
  isGDPR = @() debugConsentGDPR.get()
  isConsentInited = @() true
  isConsentGiven = @() debugConsentGiven.get()
  isConsentAcceptedForAll = @() debugConsentAcceptedAllDefault.get()
})
