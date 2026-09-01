from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "%appGlobals/loginState.nut" import LOGIN_STATE
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/pServer/bqClient.nut" import sendErrorLocIdBqEvent
from "%appGlobals/pServer/pServerApi.nut" import get_all_configs, get_cur_time, registerHandler, localizePServerError
from "%appGlobals/userstats/serverTime.nut" import isServerTimeValid


let { onlyActiveStageCb, export, finalizeStage, interruptStage
} = require("mkStageBase.nut")("configs", LOGIN_STATE.AUTHORIZED, LOGIN_STATE.CONFIGS_RECEIVED)

registerHandler("onLoginGetConfigs", onlyActiveStageCb(function(res, _) {
  if (res?.error != null) {
    deferOnce(@() interruptStage(res)) 
    let { bqLocId, text } = localizePServerError(res.error)
    sendErrorLocIdBqEvent(bqLocId)
    openFMsgBox({ text })
  }
  else
    deferOnce(finalizeStage) 
}))

function start() {
  if (!isServerTimeValid.get())
    get_cur_time()
  get_all_configs("onLoginGetConfigs")
}

return export.__merge({
  start
  restart = start
})