from "%scripts/dagui_library.nut" import *
let { defer } = require("dagor.workcycle")
let { eventbus_subscribe } = require("eventbus")
let iOsPlaform = require("ios.platform")
let { requestTrackingPermission, getTrackingPermission, ATT_NOT_DETERMINED } = iOsPlaform
let { LOGIN_STATE, isPreviewIDFAShowed, isReadyForShowPreviewIdfa } = require("%appGlobals/loginState.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")

let { export, finalizeStage } = require("mkStageBase.nut")("ios_idfa",
  LOGIN_STATE.READY_FOR_IDFA,
  LOGIN_STATE.IOS_IDFA)

function request() {
  sendUiBqEvent("ads_consent_idfa", { id = "request_permission" })
  requestTrackingPermission()
}

isPreviewIDFAShowed.subscribe(@(v) v ? defer(request) : null)

eventbus_subscribe("ios.platform.onPermissionTrackCallback", function(p) {
  let { value } = p
  local result = value
  foreach(id, val in iOsPlaform)
    if (val == value && id.startswith("ATT_")) {
      result = id
      break
    }
  log("ios.platform.onPermissionTrackCallback: ", result)
  sendUiBqEvent("ads_consent_idfa", { id = "request_result", status = result.tostring() })
  finalizeStage()
})

function start() {
  if (getTrackingPermission() == ATT_NOT_DETERMINED)
    isReadyForShowPreviewIdfa.set(true)
  else
    finalizeStage()
}

return export.__merge({
  start
  restart = start
})
