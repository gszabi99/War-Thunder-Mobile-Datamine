from "%scripts/dagui_library.nut" import *
let { subscribe } = require("eventbus")
let { LOGIN_STATE } = require("%appGlobals/loginState.nut")

let { onlyActiveStageCb, export, finalizeStage
} = require("mkStageBase.nut")("online_settings",
  LOGIN_STATE.AUTHORIZED,
  LOGIN_STATE.ONLINE_SETTINGS_AVAILABLE)

let finalize = onlyActiveStageCb(finalizeStage)
subscribe("onUpdateProfile", @(_) finalize())

return export
