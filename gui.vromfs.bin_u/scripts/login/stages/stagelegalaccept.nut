from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this
let { defer } = require("dagor.workcycle")
let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { isLoginAllowed, needInterruptLoginByFailedLegal, sendLegalErroToBq } = require("%scripts/legalState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

let { onlyActiveStageCb, export, finalizeStage, interruptStage
} = require("mkStageBase.nut")("legalAccept",
  LOGIN_STATE.AUTH_AND_UPDATED | LOGIN_STATE.ONLINE_SETTINGS_AVAILABLE,
  LOGIN_STATE.LEGAL_ACCEPTED)

let interrupt = onlyActiveStageCb(function() {
  interruptStage({ error = "Failed to get legal versions" })
  openFMsgBox({ text = loc("error/failedToGetLegalVersions") })
  sendLegalErroToBq()
})

isLoginAllowed.subscribe(@(v) v ? defer(finalizeStage) : null)
needInterruptLoginByFailedLegal.subscribe(@(v) v ? defer(@() interrupt()) : null)

let function start() {
  if (isLoginAllowed.value)
    finalizeStage()
  else if (needInterruptLoginByFailedLegal.value)
    defer(@() interrupt())
}

return export.__merge({
  start
  restart = start
})
