from "%scripts/dagui_library.nut" import *
let DataBlock  = require("DataBlock")
let { subscribe } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { isOnlineSettingsAvailable, legalListForApprove } = require("%appGlobals/loginState.nut")
let { legalToApprove } = require("%appGlobals/legal.nut")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { saveProfile } = require("%scripts/clientState/saveProfile.nut")

const VERSIONS_ID = "legalVersions"

let acceptedVersions = Watched({})
let isLoginAllowed = Computed(@() legalToApprove.findvalue(@(_, id) id in acceptedVersions.value) != null)
let requiredVersions = Watched({
  //FIXME: request this from https://legal.gaijin.net/api/v1/getversions?filter=default,gamerules,gamerules-wtm,wtm-compliance-policy
  privacypolicy = 1681821489
  termsofservice = 1681820778
})
let needApprove = Computed(@() !isOnlineSettingsAvailable.value ? {}
  : legalToApprove.map(@(_, id) requiredVersions.value?[id] != acceptedVersions.value?[id]))

let function loadAcceptedVersions() {
  let blk = get_local_custom_settings_blk()
  let versionsBlk = blk?[VERSIONS_ID]
  let res = {}
  if (isDataBlock(versionsBlk))
    eachParam(versionsBlk, @(v, k) res[k] <- v)
  acceptedVersions(res)
}

let function saveAcceptedVersions() {
  let blk = get_local_custom_settings_blk()
  let versionsBlk = DataBlock()
  foreach(k, v in acceptedVersions.value)
    versionsBlk[k] <- v
  blk[VERSIONS_ID] = versionsBlk
  saveProfile()
}

if (isOnlineSettingsAvailable.value)
  loadAcceptedVersions()
isOnlineSettingsAvailable.subscribe(@(v) v ? loadAcceptedVersions() : acceptedVersions({}))

if (!isEqual(needApprove.value, legalListForApprove.value))
  legalListForApprove(needApprove.value)
needApprove.subscribe(@(v) legalListForApprove(v))

subscribe("acceptAllLegals", function(_) {
  if (!isOnlineSettingsAvailable.value)
    return
  let versions = clone acceptedVersions.value
  foreach(id, need in needApprove.value)
    if (need && id in requiredVersions.value)
      versions[id] <- requiredVersions.value[id]
  acceptedVersions(versions)
  saveAcceptedVersions()
})

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
