from "%scripts/dagui_library.nut" import *
let { defer } = require("dagor.workcycle")
let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { isLoginAllowed } = require("%scripts/legalState.nut")

let { export, finalizeStage } = require("mkStageBase.nut")("legalAccept",
  LOGIN_STATE.AUTH_AND_UPDATED | LOGIN_STATE.ONLINE_SETTINGS_AVAILABLE,
  LOGIN_STATE.LEGAL_ACCEPTED)

isLoginAllowed.subscribe(@(v) v ? defer(finalizeStage) : null)

let function start() {
  if (isLoginAllowed.value)
    finalizeStage()
}

return export.__merge({
  start
  restart = start
})
