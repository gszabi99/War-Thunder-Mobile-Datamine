from "%scripts/dagui_library.nut" import *
let { defer } = require("dagor.workcycle")
let { LOGIN_STATE, isTcfConsentAllowLogin } = require("%appGlobals/loginState.nut")

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
