from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let { setChardToken } = require("chard")
let { getPlayerToken } = require("auth_wt")
let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { APP_ID, CONTACTS_GAME_ID } = require("%appGlobals/gameIdentifiers.nut")
let contacts = require("contacts")
let { errorMsgBox } = require("%scripts/utils/errorMsgBox.nut")
let { getSysInfo } = require("%scripts/login/sysInfo.nut")
let { applyRights } = require("%scripts/login/applyRights.nut")
let { rightsError } = require("%appGlobals/permissions/userRights.nut")

let { onlyActiveStageCb, export, finalizeStage, interruptStage
} = require("mkStageBase.nut")("contact", LOGIN_STATE.AUTHORIZED, LOGIN_STATE.LOGGED_INTO_CONTACTS)

let function start() {
  let request = {
    action = "cln_cs_login"
    headers = { token = getPlayerToken(), appid = APP_ID },
    data = {
      game = CONTACTS_GAME_ID
      sysinfo = getSysInfo()
    }
  }

  contacts.request(request, onlyActiveStageCb(function(result) {
    let errorStr = result?.error ?? result?.result?.error
    if (errorStr != null) {
      interruptStage({ error = errorStr })
      errorMsgBox(errorStr,
        [
          { id = "exit", eventId = "loginExitGame", hotkeys = ["^J:X"] }
          { id = "tryAgain", isPrimary = true, isDefault = true }
        ])
      return
    }

    rightsError(null)
    applyRights(result)

    setChardToken(result?.chardToken ?? 0)
    finalizeStage()
  }))
}

return export.__merge({
  start
  restart = start
})