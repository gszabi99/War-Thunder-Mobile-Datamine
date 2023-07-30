from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let { LOGIN_STATE } = require("%appGlobals/loginState.nut")

let { onlyActiveStageCb, export, finalizeStage
} = require("mkStageBase.nut")("online_settings",
  LOGIN_STATE.AUTHORIZED,
  LOGIN_STATE.ONLINE_SETTINGS_AVAILABLE)

const EATT_UNKNOWN = -1

let finalize = onlyActiveStageCb(finalizeStage)
::onUpdateProfile <- @(_taskId, _action, _transactionType = EATT_UNKNOWN) //code callback on profile update
  finalize()

return export
