from "%scripts/dagui_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { get_all_configs, get_cur_time, registerHandler, localizePServerError
} = require("%appGlobals/pServer/pServerApi.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")

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