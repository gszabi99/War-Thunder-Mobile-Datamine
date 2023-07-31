from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this
let { defer } = require("dagor.workcycle")
let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { isLoginAllowed } = require("%scripts/legalState.nut")

let { onlyActiveStageCb, export, finalizeStage
} = require("mkStageBase.nut")("legalAccept",
  LOGIN_STATE.AUTH_AND_UPDATED | LOGIN_STATE.ONLINE_SETTINGS_AVAILABLE,
  LOGIN_STATE.LEGAL_ACCEPTED)

let finalize = onlyActiveStageCb(finalizeStage)
isLoginAllowed.subscribe(@(v) v ? defer(@() finalize()) : null)

let function start() {
  if (isLoginAllowed.value)
    finalize()
}

return export.__merge({
  start
  restart = start
})
