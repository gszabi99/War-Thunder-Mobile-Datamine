from "%globalsDarg/darg_library.nut" import *
from "app" import get_cur_circuit_name
from "auth_wt" import getPlayerTokenGlobal, get_user_info
from "chard" import setChardToken
from "penalty" import BAN_USER_INFINITE_PENALTY
from "string" import format
from "eventbus" import eventbus_send
from "%appGlobals/clientState/initialState.nut" import projectId
from "%appGlobals/curCircuitOverride.nut" import addPublisherToHeaders
from "%appGlobals/gameIdentifiers.nut" import APP_ID, CONTACTS_GAME_ID
from "%appGlobals/loginState.nut" import LOGIN_STATE
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/permissions/applyRights.nut" import applyRights
from "%appGlobals/permissions/userRights.nut" import rightsError
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "guiScriptUtils" import get_player_user_id
from "%rGui/login/sysInfo.nut" import getSysInfo
from "%appGlobals/errorMsgBox.nut" import errorMsgBox
from "%rGui/contacts/contactsClient.nut" import contactsRequest, contactsRegisterHandler


let openUrl = @(baseUrl) eventbus_send("openUrl", { baseUrl })

let { onlyActiveStageCb, export, finalizeStage, interruptStage
} = require("mkStageBase.nut")("contact", LOGIN_STATE.AUTHORIZED, LOGIN_STATE.CONTACTS_LOGGED_IN)




let reqAccessUrl = "https://central-admin.gaijin.net/projects/{project}/groups/{group}?modal=addUser&uid={userId}"
  .subst({ project = projectId, group = "692d4437b16be2784ae27da6" })

let customErrorMsg = {
  ["Game is under maintenance"] = @(_) openFMsgBox({ text = loc("matching/SERVER_ERROR_MAINTENANCE") }),
  function ACCESS_DENIED_DUE_NO_ROLE(_) {
    openFMsgBox({ text = loc("matching/ACCESS_DENIED_DUE_NO_ROLE", {uid = get_user_info()?.userId.tostring() ?? "n/a"}) })
    if (get_cur_circuit_name().indexof("production") == null)
      openUrl(reqAccessUrl.subst({ userId = get_player_user_id() }))
  },

  function BANNED(res) {
    let { message = "", duration = 0, start = 0 } = res?.details
    let userId = get_user_info()?.userId.tostring() ?? ""
    if (duration.tointeger() >= BAN_USER_INFINITE_PENALTY) {
      openFMsgBox({
        text = "\n\n".concat(
          loc("charServer/ban/permanent"),
          message)
        viewType = "accStatusMsg"
        userId
      })
      return
    }

    let durationSec = duration.tointeger() / 1000
    let startSec = start.tointeger() / 1000
    openFMsgBox({
      text = "\n".concat(
        format(loc("charServer/ban/timed"), secondsToHoursLoc(durationSec)),
        serverTime.get() <= 0 ? ""
          : format(loc("charServer/ban/timeLeft"),
              secondsToHoursLoc(startSec + durationSec - serverTime.get())),
        " ",
        message
      )
      viewType = "accStatusMsg"
      userId
    })
  }
}

function onLoginResult(result) {
  
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

  rightsError.set(null)
  applyRights(result)
  setChardToken(result?.chardToken ?? 0)
  finalizeStage()
}

contactsRegisterHandler("cln_cs_login", @(res) onlyActiveStageCb(onLoginResult)(res))

let start = @() contactsRequest("cln_cs_login",
  {
    headers = addPublisherToHeaders({ token = getPlayerTokenGlobal(), appid = APP_ID }),
    data = {
      game = CONTACTS_GAME_ID
      sysinfo = getSysInfo()
    }
  })

return export.__merge({
  start
  restart = start
})