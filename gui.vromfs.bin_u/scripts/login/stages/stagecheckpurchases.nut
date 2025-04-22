from "%scripts/dagui_library.nut" import *

let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { check_purchases, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")

let { onlyActiveStageCb, export, finalizeStage, logStage
} = require("mkStageBase.nut")("check_purchases",
  LOGIN_STATE.PROFILE_RECEIVED | LOGIN_STATE.CONFIGS_RECEIVED | LOGIN_STATE.MATCHING_CONNECTED,
  LOGIN_STATE.PURCHASES_RECEIVED)

registerHandler("onLoginCheckPurchases", onlyActiveStageCb(function(res, _) {
  if (res?.error != null)
    logStage($"Failed: {res.error?.message ?? res.error}")
  finalizeStage() 
}))

let start = @() check_purchases("onLoginCheckPurchases")

return export.__merge({
  start
  restart = start
})