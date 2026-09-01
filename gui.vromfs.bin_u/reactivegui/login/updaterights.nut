from "%globalsDarg/darg_library.nut" import *
from "auth_wt" import getPlayerTokenGlobal
import "contacts" as client
from "dagor.workcycle" import setInterval, clearTimer
from "%appGlobals/gameIdentifiers.nut" import APP_ID
from "%appGlobals/loginState.nut" import isContactsLoggedIn
from "%appGlobals/permissions/applyRights.nut" import applyRights
from "%appGlobals/permissions/userRights.nut" import rights, rightsError
from "types" import String


const UPDATE_TIMEOUT = 60 * 60 

function updateRightsImpl() {
  if (!isContactsLoggedIn.get())
    return

  let rqData = {
    action = "cln_get_user_rights"
    headers = { token = getPlayerTokenGlobal(), appid = APP_ID },
  }

  client.request(rqData, function(result) {
    if (!isContactsLoggedIn.get())
      return
    let errorStr = result instanceof String ? result : (result?.error ?? result?.result.error)
    if (errorStr != null) {
      log("ERROR: invalid cln_get_user_rights result:", errorStr)
      rightsError.set(errorStr)
      return
    }

    rightsError.set(null)
    applyRights(result)
  })
}
setInterval(UPDATE_TIMEOUT, updateRightsImpl)

isContactsLoggedIn.subscribe(function(val) {
  if (val) {
    clearTimer(updateRightsImpl)
    setInterval(UPDATE_TIMEOUT, updateRightsImpl)
  }
  else {
    rights.set({})
  }
})


