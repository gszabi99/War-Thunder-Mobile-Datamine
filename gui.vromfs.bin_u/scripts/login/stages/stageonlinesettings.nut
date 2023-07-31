from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this
let { subscribe } = require("eventbus")
let { LOGIN_STATE } = require("%appGlobals/loginState.nut")

let { onlyActiveStageCb, export, finalizeStage
} = require("mkStageBase.nut")("online_settings",
  LOGIN_STATE.AUTHORIZED,
  LOGIN_STATE.ONLINE_SETTINGS_AVAILABLE)

const EATT_UNKNOWN = -1

let finalize = onlyActiveStageCb(finalizeStage)
subscribe("onUpdateProfile", @(_) finalize())

return export
