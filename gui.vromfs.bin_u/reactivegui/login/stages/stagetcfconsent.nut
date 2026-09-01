from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import defer
from "%appGlobals/loginState.nut" import LOGIN_STATE, isTcfConsentAllowLogin


let { export, finalizeStage } = require("mkStageBase.nut")("tcf_consent",
  LOGIN_STATE.READY_FOR_TCF_CONSENT,
  LOGIN_STATE.TCF_CONSENT)

isTcfConsentAllowLogin.subscribe(@(v) v ? defer(finalizeStage) : null)

function start() {
  if (isTcfConsentAllowLogin.get())
    finalizeStage()
}

return export.__merge({
  start
  restart = start
})
