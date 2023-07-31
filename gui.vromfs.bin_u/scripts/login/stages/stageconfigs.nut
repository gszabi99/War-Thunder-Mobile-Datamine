from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this
let { defer } = require("dagor.workcycle")
let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { get_all_configs, registerHandler, localizePServerError
} = require("%appGlobals/pServer/pServerApi.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")

let { onlyActiveStageCb, export, finalizeStage, interruptStage
} = require("mkStageBase.nut")("configs", LOGIN_STATE.AUTH_AND_UPDATED, LOGIN_STATE.CONFIGS_RECEIVED)

registerHandler("onLoginGetConfigs", onlyActiveStageCb(function(res, _) {
  if (res?.error != null) {
    defer(@() interruptStage(res)) //sign_out has big sync time, so better to not do it on the same frame with pServer logerr
    let { bqLocId, text } = localizePServerError(res.error)
    sendErrorLocIdBqEvent(bqLocId)
    openFMsgBox({ text })
  }
  else
    finalizeStage()
}))

let start = @() get_all_configs("onLoginGetConfigs")

return export.__merge({
  start
  restart = start
})