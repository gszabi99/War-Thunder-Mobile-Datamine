//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { loginState } = require("%appGlobals/loginState.nut")
let { send } = require("eventbus")

let function mkStageBase(id, reqState, finishState) {
  let logStage = log_with_prefix($"[LOGIN][{id}] ")

  let function interruptStage(errData) {
    logStage("Failed. errData: ", errData)
    send("login.interrupt", errData.__merge({ stage = id }))
  }
  let function finalizeStage() {
    logStage("Success")
    loginState(loginState.value | finishState)
  }

  let onlyActiveStageCb = @(cb) function(...) {
    if ((loginState.value & reqState) != reqState)
      logStage("Ignore stage callback, because of not ready (login interrupted?)")
    else if ((loginState.value & finishState) == finishState)
      logStage("Ignore stage callback, because of already completed.")
    else
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