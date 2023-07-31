//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { loginState } = require("%appGlobals/loginState.nut")
let { send } = require("eventbus")

let function mkStageBase(id, reqState, finishState) {
  let logStage = log_with_prefix($"[LOGIN][{id}] ")

  let function canContinueWithLog(prefix) {
    if ((loginState.value & reqState) != reqState)
      logStage($"{prefix}, because of not ready (login interrupted?)")
    else if ((loginState.value & finishState) == finishState)
      logStage($"{prefix}, because of already completed.")
    else
      return true
    return false
  }

  let function interruptStage(errData) {
    if (!canContinueWithLog("Ignore interrupt stage"))
      return
    logStage("Failed. errData: ", errData)
    send("login.interrupt", errData.__merge({ stage = id }))
  }
  let function finalizeStage() {
    if (!canContinueWithLog("Ignore finalize stage"))
      return
    logStage("Success")
    loginState(loginState.value | finishState)
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