from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import defer
from "%appGlobals/loginState.nut" import LOGIN_STATE
from "%rGui/login/legalState.nut" import isLoginAllowed


let { export, finalizeStage } = require("mkStageBase.nut")("legalAccept",
  LOGIN_STATE.AUTH_AND_UPDATED | LOGIN_STATE.ONLINE_SETTINGS_AVAILABLE,
  LOGIN_STATE.LEGAL_ACCEPTED)

isLoginAllowed.subscribe(@(v) v ? defer(finalizeStage) : null)

function start() {
  if (isLoginAllowed.get())
    finalizeStage()
}

return export.__merge({
  start
  restart = start
})
