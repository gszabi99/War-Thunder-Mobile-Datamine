from "%globalScripts/logs.nut" import log_with_prefix
from "%appGlobals/permissions/permission_utils.nut" import readPermissions, readPenalties
from "%appGlobals/permissions/userRights.nut" import rights
from "%appGlobals/profileStates.nut" import myUserId


let logR = log_with_prefix("[RIGHTS] ")

function applyRights(result) {
  let { clientPermJwt = null, dedicatedPermJwt = null, penaltiesJwt = null } = result
  let curP = rights.get()
  if (clientPermJwt == null && dedicatedPermJwt == null && penaltiesJwt == null
      && curP?.penaltiesJwt == null && curP?.dedicatedPermJwt == null && curP?.permissions == null) {
    logR("Failed to apply permissions, because no data.")
    return
  }

  logR("Apply permissions")
  rights.set({
    permissions = readPermissions(clientPermJwt, myUserId.get())
    penalties = readPenalties(penaltiesJwt, myUserId.get())
    penaltiesJwt
    dedicatedPermJwt
  })
}

return {
  applyRights
}
