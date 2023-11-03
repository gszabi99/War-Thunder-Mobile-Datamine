from "%scripts/dagui_library.nut" import *

let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { sendLoadingStageBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let mkStageBase = require("mkStageBase.nut")

let actions = {}

::online_init_stage_finished <- @(stage, ...) actions?[stage]() //from native code

let finalize = @(stage, finalizeStage) function() {
  if (stage != null)
    sendLoadingStageBqEvent(stage)

  finalizeStage()
}

let function mkStage(id, nativeState, finalState, bqEvent = null) {
  let { onlyActiveStageCb, export, finalizeStage
  } = mkStageBase(id, LOGIN_STATE.AUTHORIZED, finalState)

  actions[nativeState] <- onlyActiveStageCb(finalize(bqEvent, finalizeStage))

  let function checkReceived() {
    if (nativeState & ::get_online_client_cur_state())
      finalizeStage()
  }

  return export.__update({
    start = checkReceived
    restart = checkReceived
  })
}

return [
  mkStage("online_binaries_inited", ONLINE_BINARIES_INITED, LOGIN_STATE.ONLINE_BINARIES_INITED)
  mkStage("hangar_entered", HANGAR_ENTERED, LOGIN_STATE.HANGAR_LOADED, "hangar_entered")
]