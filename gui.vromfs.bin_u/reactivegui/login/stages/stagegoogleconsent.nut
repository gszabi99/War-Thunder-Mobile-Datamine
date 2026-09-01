from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import defer
from "%appGlobals/loginState.nut" import LOGIN_STATE, isGoogleConsentShowed


let { export, finalizeStage } = require("mkStageBase.nut")("google_consent",
  LOGIN_STATE.READY_FOR_GOOGLE_CONSENT,
  LOGIN_STATE.GOOGLE_CONSENT)

isGoogleConsentShowed.subscribe(@(v) v ? defer(finalizeStage) : null)

function start() {
  if (isGoogleConsentShowed.get())
    finalizeStage()
}

return export.__merge({
  start
  restart = start
})
