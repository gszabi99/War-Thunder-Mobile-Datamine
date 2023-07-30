//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { isLoggedIntoContacts } = require("%appGlobals/loginState.nut")
let { rights, rightsError } = require("%appGlobals/permissions/userRights.nut")
let { setInterval, clearTimer } = require("dagor.workcycle")
let client = require("contacts")
let { getPlayerToken } = require("auth_wt")
let { APP_ID } = require("%appGlobals/gameIdentifiers.nut")
let { applyRights } = require("%scripts/login/applyRights.nut")

const UPDATE_TIMEOUT = 300 //5min

let function updateRightsImpl() {
  if (!isLoggedIntoContacts.value)
    return

  let rqData = {
    action = "cln_get_user_rights"
    headers = { token = getPlayerToken(), appid = APP_ID },
  }

  client.request(rqData, function(result) {
    if (!isLoggedIntoContacts.value)
      return
    let errorStr = result?.error ?? result?.result?.error
    if (errorStr != null) {
      log("ERROR: invalid cln_get_user_rights result:", errorStr)
      rightsError(errorStr)
      return
    }

    rightsError(null)
    applyRights(result)
  })
}
setInterval(UPDATE_TIMEOUT, updateRightsImpl)

isLoggedIntoContacts.subscribe(function(val) {
  if (val) {
    clearTimer(updateRightsImpl)
    setInterval(UPDATE_TIMEOUT, updateRightsImpl)
  }
  else {
    rights({})
  }
})


