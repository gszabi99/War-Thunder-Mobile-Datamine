from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import defer
from "%appGlobals/loginState.nut" import LOGIN_STATE, isConsentAllowLogin


let { export, finalizeStage } = require("mkStageBase.nut")("consentWnd",
  LOGIN_STATE.READY_FOR_OUR_CONSENT,
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
