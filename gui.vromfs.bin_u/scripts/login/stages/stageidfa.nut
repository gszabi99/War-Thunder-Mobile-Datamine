from "%scripts/dagui_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let iOsPlaform = require("ios.platform")
let { requestTrackingPermission, getTrackingPermission, ATT_NOT_DETERMINED } = iOsPlaform
let { LOGIN_STATE } = require("%appGlobals/loginState.nut")

let { export, finalizeStage } = require("mkStageBase.nut")("ios_idfa",
  LOGIN_STATE.READY_FOR_IDFA,
  LOGIN_STATE.IOS_IDFA)


eventbus_subscribe("ios.platform.onPermissionTrackCallback", function(p) {
  let { value } = p
  local result = value
  foreach(id, val in iOsPlaform)
    if (val == value && id.startswith("ATT_")) {
      result = id
      break
    }
  log("ios.platform.onPermissionTrackCallback: ", result)
  finalizeStage()
})

function start() {
  if (getTrackingPermission() == ATT_NOT_DETERMINED)
    requestTrackingPermission()
  else
    finalizeStage()
}

return export.__merge({
  start
  restart = start
})



