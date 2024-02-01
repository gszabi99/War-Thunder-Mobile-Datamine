from "%scripts/dagui_library.nut" import *
let { setChardToken } = require("chard")
let { getPlayerToken } = require("auth_wt")
let contacts = require("contacts")
let { BAN_USER_INFINITE_PENALTY } = require("penalty")
let { format } =  require("string")
let { APP_ID, CONTACTS_GAME_ID } = require("%appGlobals/gameIdentifiers.nut")
let { getSysInfo } = require("%scripts/login/sysInfo.nut")
let { applyRights } = require("%scripts/login/applyRights.nut")
let { rightsError } = require("%appGlobals/permissions/userRights.nut")
let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let charClientEvent = require("%scripts/charClientEvent.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { errorMsgBox } = require("%scripts/utils/errorMsgBox.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")


let { onlyActiveStageCb, export, finalizeStage, interruptStage
} = require("mkStageBase.nut")("contact", LOGIN_STATE.AUTHORIZED, LOGIN_STATE.CONTACTS_LOGGED_IN)
let { request, registerHandler } = charClientEvent("contacts", contacts)

let customErrorMsg = {
  ["Game is under maintenance"] = @(_) openFMsgBox({ text = loc("matching/SERVER_ERROR_MAINTENANCE") }),

  function BANNED(res) {
    let { message = "", duration = 0, start = 0 } = res?.details
    if (duration.tointeger() >= BAN_USER_INFINITE_PENALTY) {
      openFMsgBox({
        text = "\n\n".concat(
          loc("charServer/ban/permanent"),
          message)
      })
      return
    }

    let durationSec = duration.tointeger() / 1000
    let startSec = start.tointeger() / 1000
    openFMsgBox({
      text = "\n".concat(
        format(loc("charServer/ban/timed"), secondsToHoursLoc(durationSec)),
        serverTime.value <= 0 ? ""
          : format(loc("charServer/ban/timeLeft"),
              secondsToHoursLoc(startSec + durationSec - serverTime.value)),
        " ",
        message
      )
    })
  }
}

function onLoginResult(result) {
  // On success, it is in "result", on error it is in "result.result"
  if ("result" in result)
    result = result.result

  let errStr = result?.error
  let isSuccess = !errStr
  if (!isSuccess) {
    interruptStage({ error = errStr })
    if (errStr in customErrorMsg)
      customErrorMsg[errStr](result)
    else
      errorMsgBox(errStr,
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
}

registerHandler("cln_cs_login", @(res) onlyActiveStageCb(onLoginResult)(res))

let start = @() request("cln_cs_login",
  {
    headers = { token = getPlayerToken(), appid = APP_ID },
    data = {
      game = CONTACTS_GAME_ID
      sysinfo = getSysInfo()
    }
  })

return export.__merge({
  start
  restart = start
})