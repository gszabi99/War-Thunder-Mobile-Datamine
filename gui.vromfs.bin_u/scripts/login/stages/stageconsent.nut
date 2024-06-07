from "%scripts/dagui_library.nut" import *
let { defer } = require("dagor.workcycle")
let { LOGIN_STATE, isConsentAllowLogin } = require("%appGlobals/loginState.nut")

let { export, finalizeStage } = require("mkStageBase.nut")("consentWnd",
  LOGIN_STATE.LEGAL_ACCEPTED,
  LOGIN_STATE.CONSENT_WND)

isConsentAllowLogin.subscribe(@(v) v ? defer(finalizeStage) : null)

function start() {
  if (isConsentAllowLogin.get())
    finalizeStage()
}

return export.__merge({
  start
  restart = start
})
