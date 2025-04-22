from "%scripts/dagui_library.nut" import *
let { defer } = require("dagor.workcycle")
let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { get_profile, registerHandler, localizePServerError } = require("%appGlobals/pServer/pServerApi.nut")
let { getSysInfo } = require("%scripts/login/sysInfo.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")

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