from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { get_all_configs } = require("%appGlobals/pServer/pServerApi.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

let { onlyActiveStageCb, export, finalizeStage, interruptStage
} = require("mkStageBase.nut")("configs", LOGIN_STATE.AUTH_AND_UPDATED, LOGIN_STATE.CONFIGS_RECEIVED)

let start = @() get_all_configs(onlyActiveStageCb(function(res) {
  if (res?.error != null) {
    interruptStage(res)
    openFMsgBox({ text = loc($"error/{res.error}", res.error) })
  }
  else
    finalizeStage()
}))

return export.__merge({
  start
  restart = start
})