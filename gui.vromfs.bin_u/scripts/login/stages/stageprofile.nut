from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { get_profile } = require("%appGlobals/pServer/pServerApi.nut")
let { getSysInfo } = require("%scripts/login/sysInfo.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

let { onlyActiveStageCb, export, finalizeStage, interruptStage
} = require("mkStageBase.nut")("profile", LOGIN_STATE.AUTH_AND_UPDATED, LOGIN_STATE.PROFILE_RECEIVED)

let start = @() get_profile(getSysInfo(),
  onlyActiveStageCb(function(res) {
    if (res?.error != null) {
      interruptStage(res)
      openFMsgBox({ text = res.error })
    }
    else
      finalizeStage()
  }))

return export.__merge({
  start
  restart = start
})