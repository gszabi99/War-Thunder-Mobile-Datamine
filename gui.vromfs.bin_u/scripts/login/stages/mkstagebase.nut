
from "%scripts/dagui_library.nut" import *
let { loginState } = require("%appGlobals/loginState.nut")
let { eventbus_send } = require("eventbus")

function mkStageBase(id, reqState, finishState) {
  let logStage = log_with_prefix($"[LOGIN][{id}] ")

  function canContinueWithLog(prefix) {
    if ((loginState.get() & reqState) != reqState)
      logStage($"{prefix}, because of not ready (login interrupted?)")
    else if ((loginState.get() & finishState) == finishState)
      logStage($"{prefix}, because of already completed.")
    else
      return true
    return false
  }

  function interruptStage(errData) {
    if (!canContinueWithLog("Ignore interrupt stage"))
      return
    logStage("Failed. errData: ", errData)
    eventbus_send("login.interrupt", errData.__merge({ stage = id }))
  }
  function finalizeStage() {
    if (!canContinueWithLog("Ignore finalize stage"))
      return
    logStage("Success")
    loginState.set(loginState.get() | finishState)
  }

  let onlyActiveStageCb = @(cb) function(...) {
    if (canContinueWithLog("Ignore stage callback"))
      cb.acall([this].extend(vargv))
  }

  return {
    id
    reqState
    finishState

    logStage
    onlyActiveStageCb
    finalizeStage
    interruptStage

    export = { id, reqState, finishState, logStage }
  }
}

return mkStageBase