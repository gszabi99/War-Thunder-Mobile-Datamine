from "%scripts/dagui_library.nut" import *
let { defer } = require("dagor.workcycle")
let { LOGIN_STATE, isGoogleConsentShowed } = require("%appGlobals/loginState.nut")

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
