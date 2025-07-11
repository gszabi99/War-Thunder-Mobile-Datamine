from "%scripts/dagui_library.nut" import *
let DataBlock  = require("DataBlock")
let { eventbus_subscribe } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { httpRequest, HTTP_SUCCESS } = require("dagor.http")
let { parse_json } = require("json")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isOnlineSettingsAvailable, legalListForApprove, isAuthorized } = require("%appGlobals/loginState.nut")
let { legalToApprove } = require("%appGlobals/legal.nut")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { saveProfile } = require("%scripts/clientState/saveProfile.nut")

const VERSIONS_ID = "legalVersions"
const VERSIONS_URL = "https://legal.gaijin.net/api/v1/getversions?filter=default,gamerules,gamerules-wtm,wtm-compliance-policy"
const VERSIONS_RESP_ID = "legalVersion.result"

let versionsFallback = {
  privacypolicy = 1681821489
  termsofservice = 1681820778
}

let acceptedVersions = Watched(null)
let isLoginAllowed = Computed(@() legalToApprove.findvalue(@(_, id) id in acceptedVersions.value) != null)
let requiredVersionsRaw = hardPersistWatched("requiredVersionsRaw")
let lastVersionsError = hardPersistWatched("lastVersionsError")
let isFailedToGetLegalVersions = Computed(@() requiredVersionsRaw.value == null && lastVersionsError.value != null)
let requiredVersions = Computed(@() isFailedToGetLegalVersions.value ? versionsFallback : requiredVersionsRaw.value)
let needApprove = Computed(@() !isOnlineSettingsAvailable.value ? {}
  : legalToApprove.map(@(_, id) id in requiredVersions.value
      && (id not in acceptedVersions.value || requiredVersions.value[id] > acceptedVersions.value[id])))

function loadAcceptedVersions() {
  let blk = get_local_custom_settings_blk()
  let versionsBlk = blk?[VERSIONS_ID]
  let res = {}
  if (isDataBlock(versionsBlk))
    eachParam(versionsBlk, @(v, k) res[k] <- v)
  acceptedVersions(res)
}

function saveAcceptedVersions() {
  if (acceptedVersions.value == null) 
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

eventbus_subscribe("acceptAllLegals", function(_) {
  if (!isOnlineSettingsAvailable.value || acceptedVersions.value == null)
    return
  let versions = clone acceptedVersions.value
  foreach(id, need in needApprove.value)
    if (need && id in requiredVersions.value)
      versions[id] <- requiredVersions.value[id]
  acceptedVersions(versions)
  saveAcceptedVersions()
})

eventbus_subscribe(VERSIONS_RESP_ID, function(response) {
  let { status = -1, http_code = -1, body = null } = response
  let hasError = status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code
  if (hasError || body == null) {
    if (requiredVersionsRaw.value == null)
      lastVersionsError({ status, http_code })
    return
  }
  local result = null
  let bodyStr = body.as_string()
  try {
    result = body != null ? parse_json(bodyStr) : null
  }
  catch(e) {}
  if (result?.status == "OK") {
    requiredVersionsRaw(result?.result)
    lastVersionsError(null)
  } else
    lastVersionsError({ status = result?.status, isParsingError = true })
})

function requestVersionsOnce() {
  if (requiredVersionsRaw.value != null)
    return
  httpRequest({
    method = "GET"
    url = VERSIONS_URL
    respEventId = VERSIONS_RESP_ID
  })
}
if (isAuthorized.value)
  requestVersionsOnce()
isAuthorized.subscribe(@(v) v ? requestVersionsOnce() : null)

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
}
