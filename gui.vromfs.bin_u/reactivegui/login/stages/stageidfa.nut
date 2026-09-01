from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "dagor.workcycle" import defer
from "eventbus" import eventbus_subscribe
import "ios.platform" as iOsPlatform
from "%sqstd/datablock.nut" import isDataBlock, eachParam
from "%appGlobals/consent.nut" import isTcfConsentEnabled
from "%appGlobals/loginState.nut" import LOGIN_STATE, isPreviewIDFAShowed, isReadyForShowPreviewIdfa,
  CONSENT_OPTIONS_SAVE_ID, TCF_CONSENT_ACCEPTED_SAVE_ID
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent
from "%appGlobals/permissions.nut" import has_att_warmingup_scene


let { requestTrackingPermission, getTrackingPermission, ATT_NOT_DETERMINED } = iOsPlatform

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
  foreach(id, val in iOsPlatform)
    if (val == value && id.startswith("ATT_")) {
      result = id
      break
    }
  log("ios.platform.onPermissionTrackCallback: ", result)
  sendUiBqEvent("ads_consent_idfa", { id = "request_result", status = result.tostring() })
  finalizeStage()
})

let isTcfConsentAccepted = @() get_local_custom_settings_blk()?[TCF_CONSENT_ACCEPTED_SAVE_ID] ?? false

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
  let isTrackingPermissionNotDetermined = getTrackingPermission() == ATT_NOT_DETERMINED
  if ((isTrackingPermissionNotDetermined && isTcfConsentEnabled.get() && isTcfConsentAccepted())
      || (isTrackingPermissionNotDetermined && !isTcfConsentEnabled.get() && isOurConsentAccepted())) {
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
