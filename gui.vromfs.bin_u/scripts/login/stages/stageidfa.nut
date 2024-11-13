from "%scripts/dagui_library.nut" import *
let { defer } = require("dagor.workcycle")
let { eventbus_subscribe } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let iOsPlaform = require("ios.platform")
let { requestTrackingPermission, getTrackingPermission, ATT_NOT_DETERMINED } = iOsPlaform
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { LOGIN_STATE, isPreviewIDFAShowed, isReadyForShowPreviewIdfa, CONSENT_OPTIONS_SAVE_ID
} = require("%appGlobals/loginState.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { has_att_warmingup_scene } = require("%appGlobals/permissions.nut")

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

function isOurConsentAccepted() {
  let blk = get_local_custom_settings_blk()?[CONSENT_OPTIONS_SAVE_ID]
  if (!isDataBlock(blk))
    return false
  local res = false
  eachParam(blk, function(v) {
    if (v == true)
      res = true
  })
  return res
}

function start() {
  if (getTrackingPermission() == ATT_NOT_DETERMINED && isOurConsentAccepted()) {
    if (has_att_warmingup_scene.get())
      isReadyForShowPreviewIdfa.set(true)
    else
      request()
  }
  else
    finalizeStage()
}

return export.__merge({
  start
  restart = start
})
