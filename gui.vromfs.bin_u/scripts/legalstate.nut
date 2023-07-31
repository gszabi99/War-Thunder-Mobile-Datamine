from "%scripts/dagui_library.nut" import *
let DataBlock  = require("DataBlock")
let { subscribe } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { request, HTTP_SUCCESS } = require("dagor.http")
let { parse_json } = require("json")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isOnlineSettingsAvailable, legalListForApprove, isAuthorized } = require("%appGlobals/loginState.nut")
let { legalToApprove } = require("%appGlobals/legal.nut")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { saveProfile } = require("%scripts/clientState/saveProfile.nut")
let { sendErrorBqEvent } = require("%appGlobals/pServer/bqClient.nut")

const VERSIONS_ID = "legalVersions"
const VERSIONS_URL = "https://legal.gaijin.net/api/v1/getversions?filter=default,gamerules,gamerules-wtm,wtm-compliance-policy"
const VERSIONS_RESP_ID = "legalVersion.result"

let acceptedVersions = Watched(null)
let isLoginAllowed = Computed(@() legalToApprove.findvalue(@(_, id) id in acceptedVersions.value) != null)
let requiredVersions = hardPersistWatched("requiredVersions")
let lastVersionsError = hardPersistWatched("lastVersionsError")
let needApprove = Computed(@() !isOnlineSettingsAvailable.value ? {}
  : legalToApprove.map(@(_, id) id in requiredVersions.value && requiredVersions.value?[id] != acceptedVersions.value?[id]))
let isFailedToGetLegalVersions = Computed(@() requiredVersions.value == null && lastVersionsError.value != null)
let needInterruptLoginByFailedLegal = Computed(@() isFailedToGetLegalVersions.value
  && acceptedVersions.value != null && !isLoginAllowed.value)

let function loadAcceptedVersions() {
  let blk = get_local_custom_settings_blk()
  let versionsBlk = blk?[VERSIONS_ID]
  let res = {}
  if (isDataBlock(versionsBlk))
    eachParam(versionsBlk, @(v, k) res[k] <- v)
  acceptedVersions(res)
}

let function saveAcceptedVersions() {
  if (acceptedVersions.value == null) //not inited
    return
  let blk = get_local_custom_settings_blk()
  let versionsBlk = DataBlock()
  foreach(k, v in acceptedVersions.value)
    versionsBlk[k] <- v
  blk[VERSIONS_ID] = versionsBlk
  saveProfile()
}

if (isOnlineSettingsAvailable.value)
  loadAcceptedVersions()
isOnlineSettingsAvailable.subscribe(@(v) v ? loadAcceptedVersions() : acceptedVersions(null))

if (!isEqual(needApprove.value, legalListForApprove.value))
  legalListForApprove(needApprove.value)
needApprove.subscribe(@(v) legalListForApprove(v))

subscribe("acceptAllLegals", function(_) {
  if (!isOnlineSettingsAvailable.value || acceptedVersions.value == null)
    return
  let versions = clone acceptedVersions.value
  foreach(id, need in needApprove.value)
    if (need && id in requiredVersions.value)
      versions[id] <- requiredVersions.value[id]
  acceptedVersions(versions)
  saveAcceptedVersions()
})

subscribe(VERSIONS_RESP_ID, function(response) {
  let { status = -1, http_code = -1, body = null } = response
  let hasError = status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code
  if (hasError) {
    if (requiredVersions.value == null)
      lastVersionsError({ status, http_code })
    return
  }
  local result = null
  try {
    result = body != null ? parse_json(body.as_string()) : null
  }
  catch(e) {}
  if (result?.status == "OK") {
    requiredVersions(result?.result)
    lastVersionsError(null)
  } else
    lastVersionsError({ status = result?.status, isParsingError = true })
})

let function requestVersionsOnce() {
  if (requiredVersions.value != null)
    return
  request({
    method = "GET"
    url = VERSIONS_URL
    respEventId = VERSIONS_RESP_ID
  })
}
if (isAuthorized.value)
  requestVersionsOnce()
isAuthorized.subscribe(@(v) v ? requestVersionsOnce() : null)

let function sendLegalErroToBq() {
  if (lastVersionsError.value == null)
    return
  let { status = null, http_code = -1, isParsingError = false } = lastVersionsError.value
  if (isParsingError)
    sendErrorBqEvent("Failed to parse legal versions", { status = status?.tostring() ?? "null" })
  else
    sendErrorBqEvent("Failed to get legal versions", { status = status?.tostring() ?? "null", params = http_code.tostring() })
}


register_command(
  function() {
    if (!isOnlineSettingsAvailable.value)
      return console_print("Unable to reset while online settings is not available")
    let blk = get_local_custom_settings_blk()
    if (VERSIONS_ID not in blk)
      return console_print("Already empty")
    blk.removeBlock(VERSIONS_ID)
    acceptedVersions({})
    saveProfile()
    return console_print("Success")
  }
  "debug.legalReset")

return {
  isLoginAllowed
  sendLegalErroToBq
  needInterruptLoginByFailedLegal
}
