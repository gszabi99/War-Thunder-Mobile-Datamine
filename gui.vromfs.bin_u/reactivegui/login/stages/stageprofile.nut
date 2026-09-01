from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import defer
from "%appGlobals/loginState.nut" import LOGIN_STATE
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/pServer/bqClient.nut" import sendErrorLocIdBqEvent
from "%appGlobals/pServer/pServerApi.nut" import get_profile, registerHandler, localizePServerError
from "%rGui/login/sysInfo.nut" import getSysInfo


let { onlyActiveStageCb, export, finalizeStage, interruptStage
} = require("mkStageBase.nut")("profile", LOGIN_STATE.READY_TO_FULL_LOAD, LOGIN_STATE.PROFILE_RECEIVED)

registerHandler("onLoginGetProfile", onlyActiveStageCb(function(res, _) {
  if (res?.error != null) {
    defer(@() interruptStage(res)) 
    let { bqLocId, text } = localizePServerError(res.error)
    sendErrorLocIdBqEvent(bqLocId)
    openFMsgBox({ text })
  }
  else
    defer(finalizeStage) 
}))

let start = @() get_profile(getSysInfo(), "onLoginGetProfile")

return export.__merge({
  start
  restart = start
})