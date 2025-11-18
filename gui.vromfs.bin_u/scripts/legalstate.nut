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
let isLoginAllowed = Computed(@() legalToApprove.findvalue(@(_, id) id in acceptedVersions.get()) != null)
let requiredVersionsRaw = hardPersistWatched("requiredVersionsRaw")
let lastVersionsError = hardPersistWatched("lastVersionsError")
let isFailedToGetLegalVersions = Computed(@() requiredVersionsRaw.get() == null && lastVersionsError.get() != null)
let requiredVersions = Computed(@() isFailedToGetLegalVersions.get() ? versionsFallback : requiredVersionsRaw.get())
let needApprove = Computed(@() !isOnlineSettingsAvailable.get() ? {}
  : legalToApprove.map(@(_, id) id in requiredVersions.get()
      && (id not in acceptedVersions.get() || requiredVersions.get()[id] > acceptedVersions.get()[id])))

function loadAcceptedVersions() {
  let blk = get_local_custom_settings_blk()
  let versionsBlk = blk?[VERSIONS_ID]
  let res = {}
  if (isDataBlock(versionsBlk))
    eachParam(versionsBlk, @(v, k) res[k] <- v)
  acceptedVersions.set(res)
}

function saveAcceptedVersions() {
  if (acceptedVersions.get() == null) 
    return
  let blk = get_local_custom_settings_blk()
  let versionsBlk = DataBlock()
  foreach(k, v in acceptedVersions.get())
    versionsBlk[k] <- v
  blk[VERSIONS_ID] = versionsBlk
  saveProfile()
}

if (isOnlineSettingsAvailable.get())
  loadAcceptedVersions()
isOnlineSettingsAvailable.subscribe(@(v) v ? loadAcceptedVersions() : acceptedVersions.set(null))

if (!isEqual(needApprove.get(), legalListForApprove.get()))
  legalListForApprove.set(needApprove.get())
needApprove.subscribe(@(v) legalListForApprove.set(v))

eventbus_subscribe("acceptAllLegals", function(_) {
  if (!isOnlineSettingsAvailable.get() || acceptedVersions.get() == null)
    return
  let versions = clone acceptedVersions.get()
  foreach(id, need in needApprove.get())
    if (need && id in requiredVersions.get())
      versions[id] <- requiredVersions.get()[id]
  acceptedVersions.set(versions)
  saveAcceptedVersions()
})

local isBadPageLogged = false
eventbus_subscribe(VERSIONS_RESP_ID, function(response) {
  let { status = -1, http_code = -1, body = null } = response
  let hasError = status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code
  if (hasError || body == null) {
    if (requiredVersionsRaw.get() == null)
      lastVersionsError.set({ status, http_code })
    return
  }
  local result = null
  let bodyStr = body.as_string()
  if (bodyStr.startswith("<")) { 
    if (!isBadPageLogged)
      log($"LegalState: Request versions result is html page instead of data:\n{bodyStr}")
    isBadPageLogged = true
    lastVersionsError.set({ status = "Page instead of versions", isParsingError = true })
    return
  }

  try {
    result = body != null ? parse_json(bodyStr) : null
  }
  catch(e) {}
  if (result?.status == "OK") {
    requiredVersionsRaw.set(result?.result)
    lastVersionsError.set(null)
  } else
    lastVersionsError.set({ status = result?.status, isParsingError = true })
})

function requestVersionsOnce() {
  if (requiredVersionsRaw.get() != null)
    return
  httpRequest({
    method = "GET"
    url = VERSIONS_URL
    respEventId = VERSIONS_RESP_ID
  })
}
if (isAuthorized.get())
  requestVersionsOnce()
isAuthorized.subscribe(@(v) v ? requestVersionsOnce() : null)

register_command(
  function() {
    if (!isOnlineSettingsAvailable.get())
      return console_print("Unable to reset while online settings is not available")
    let blk = get_local_custom_settings_blk()
    if (VERSIONS_ID not in blk)
      return console_print("Already empty")
    blk.removeBlock(VERSIONS_ID)
    acceptedVersions.set({})
    saveProfile()
    return console_print("Success")
  }
  "debug.legalReset")

return {
  isLoginAllowed
}
