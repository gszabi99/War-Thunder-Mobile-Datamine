
from "%scripts/dagui_library.nut" import *
let { isContactsLoggedIn } = require("%appGlobals/loginState.nut")
let { rights, rightsError } = require("%appGlobals/permissions/userRights.nut")
let { setInterval, clearTimer } = require("dagor.workcycle")
let client = require("contacts")
let { getPlayerToken } = require("auth_wt")
let { APP_ID } = require("%appGlobals/gameIdentifiers.nut")
let { applyRights } = require("%scripts/login/applyRights.nut")

const UPDATE_TIMEOUT = 300 

function updateRightsImpl() {
  if (!isContactsLoggedIn.get())
    return

  let rqData = {
    action = "cln_get_user_rights"
    headers = { token = getPlayerToken(), appid = APP_ID },
  }

  client.request(rqData, function(result) {
    if (!isContactsLoggedIn.get())
      return
    let errorStr = result?.error ?? result?.result.error
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


