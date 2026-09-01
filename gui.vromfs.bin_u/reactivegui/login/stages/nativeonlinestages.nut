from "%globalScripts/onlineStageConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%appGlobals/loginState.nut" import LOGIN_STATE
from "%appGlobals/pServer/bqClient.nut" import sendLoadingStageBqEvent
from "online" import get_online_client_cur_state
import "mkStageBase.nut" as mkStageBase


let actions = {}

eventbus_subscribe("online_init_stage_finished",  @(evt) actions?[evt?.stage]())

let finalize = @(stage, finalizeStage) function() {
  if (stage != null)
    sendLoadingStageBqEvent(stage)

  finalizeStage()
}

function mkStage(id, nativeState, finalState, bqEvent = null) {
  let { onlyActiveStageCb, export, finalizeStage
  } = mkStageBase(id, LOGIN_STATE.AUTHORIZED, finalState)

  actions[nativeState] <- onlyActiveStageCb(finalize(bqEvent, finalizeStage))

  function checkReceived() {
    if (nativeState & get_online_client_cur_state())
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