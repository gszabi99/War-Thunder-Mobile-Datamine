from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%appGlobals/loginState.nut" import LOGIN_STATE


let { onlyActiveStageCb, export, finalizeStage
} = require("mkStageBase.nut")("online_settings",
  LOGIN_STATE.AUTHORIZED,
  LOGIN_STATE.ONLINE_SETTINGS_AVAILABLE)

let finalize = onlyActiveStageCb(finalizeStage)
eventbus_subscribe("onUpdateProfile", @(_) finalize())

return export
