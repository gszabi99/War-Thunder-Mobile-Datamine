from "%scripts/dagui_library.nut" import *

let { setChardToken } = require("chard")
let { getPlayerToken } = require("auth_wt")
let contacts = require("contacts")
let { get_time_msec } = require("dagor.time")
let { resetTimeout } = require("dagor.workcycle")
let logC = log_with_prefix("[CONTACTS] ")
let { APP_ID, CONTACTS_GAME_ID } = require("%appGlobals/gameIdentifiers.nut")
let { getSysInfo } = require("%scripts/login/sysInfo.nut")
let { applyRights } = require("%scripts/login/applyRights.nut")
let { startLogout } = require("%scripts/login/logout.nut")
let { rightsError } = require("%appGlobals/permissions/userRights.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isAuthAndUpdated } = require("%appGlobals/loginState.nut")
let charClientEvent = require("%scripts/charClientEvent.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

const RETRY_LOGIN_MSEC = 5000 //120000

let isLoggedIntoContacts = hardPersistWatched("isLoggedIntoContacts", false)
let lastLoginErrorTime = hardPersistWatched("lastLoginErrorTime", -1)

let { request, registerHandler } = charClientEvent("contacts", contacts)

registerHandler("cln_cs_login", function(result) {
  if (!isAuthAndUpdated.value) {
    logC("Ignore login cb because of not auth")
    return
  }

  // On success, it is in "result", on error it is in "result.result"
  if ("result" in result)
    result = result.result

  let isSuccess = !result?.error
  isLoggedIntoContacts(isSuccess)
  lastLoginErrorTime(isSuccess ? -1 : get_time_msec())
  if (!isSuccess) {
    logC("Login cb error: ", result?.error)
    if (result.error == "Game is under maintenance") {
      openFMsgBox({ text = loc("matching/SERVER_ERROR_MAINTENANCE") })
      startLogout()
    }
    return
  }

  logC("Login success")
  rightsError(null)
  applyRights(result)
  setChardToken(result?.chardToken ?? 0)
})

let function loginContacts() {
  if (isLoggedIntoContacts.value || !isAuthAndUpdated.value)
    return

  logC("Login request")
  request("cln_cs_login",
    {
      headers = { token = getPlayerToken(), appid = APP_ID },
      data = {
        game = CONTACTS_GAME_ID
        sysinfo = getSysInfo()
      }
    })
}

isAuthAndUpdated.subscribe(@(v) v ? loginContacts() : isLoggedIntoContacts(false))

if (!isLoggedIntoContacts.value) {
  let timeLeft = lastLoginErrorTime.value <= 0 ? 0
    : lastLoginErrorTime.value + RETRY_LOGIN_MSEC - get_time_msec()
  if (timeLeft <= 0)
    loginContacts()
  else
    resetTimeout(0.001 * timeLeft, loginContacts)
}
lastLoginErrorTime.subscribe(function(t) {
  if (t > 0)
    resetTimeout(0.001 * RETRY_LOGIN_MSEC, loginContacts)
})

return {
  isLoggedIntoContacts
}
