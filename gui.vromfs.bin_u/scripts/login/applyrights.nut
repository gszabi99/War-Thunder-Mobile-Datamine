from "%scripts/dagui_library.nut" import *
let logR = log_with_prefix("[RIGHTS] ")
let { readPermissions, readPenalties } = require("%appGlobals/permissions/permission_utils.nut")
let { rights } = require("%appGlobals/permissions/userRights.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")

function applyRights(result) {
  let { clientPermJwt = null, dedicatedPermJwt = null, penaltiesJwt = null } = result
  let curP = rights.value
  if (clientPermJwt == null && dedicatedPermJwt == null && penaltiesJwt == null
      && curP?.penaltiesJwt == null && curP?.dedicatedPermJwt == null && curP?.permissions == null) {
    logR("Failed to apply permissions, because no data.")
    return
  }

  logR("Apply permissions")
  rights({
    permissions = readPermissions(clientPermJwt, myUserId.value)
    penalties = readPenalties(penaltiesJwt, myUserId.value)
    penaltiesJwt
    dedicatedPermJwt
  })
}

return {
  applyRights
}
