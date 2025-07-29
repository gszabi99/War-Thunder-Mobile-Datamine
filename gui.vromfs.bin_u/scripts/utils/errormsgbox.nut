from "%scripts/dagui_library.nut" import *

let { set_last_session_debug_info, get_last_session_debug_info } = require("%scripts/matchingRooms/sessionDebugInfo.nut")
let { format } = require("string")
let { doesLocTextExist } = require("dagor.localize")
let { SERVER_ERROR_MAINTENANCE, SERVER_ERROR_FORCE_DISCONNECT } = require("matching.errors")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { register_command } = require("console")
let { sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { authState } = require("%scripts/login/authState.nut")
let { SST_MAIL } = require("%appGlobals/loginState.nut")
let matching = require("%appGlobals/matching_api.nut")

let curtomUrls = {
  [SERVER_ERROR_MAINTENANCE] = "https://www.wtmobile.com/news",
  ["CANNOT_LOGIN_WITH_LINKED_ACCOUNT"] = "",
  [YU2_WRONG_2STEP_CODE] = loc($"url/profile/security"),
  [YU2_PROFILE_DELETED] = loc($"url/feedback/support"),
}

function matchingErrData(error_text) {
  let bqLocId = $"matching/{error_text}"
  return {
    bqLocId
    text = loc("yn1/error/fmt",
      {
        text = loc("yn1/connect_error"),
        err_msg = loc(bqLocId, error_text),
        err_code = ""
      })
  }
}

function defErrData(res) {
  let errCode = res == "0" ? "" : res
  let bqLocId = $"yn1/error/{errCode}"
  if (doesLocTextExist(bqLocId))
    return { bqLocId, text = loc(bqLocId) }

  return {
    bqLocId
    text = loc("yn1/error/fmt", {
      text = loc("yn1/connect_error", "")
      err_msg = $"0x{errCode}"
      err_code = ""
    })
  }
}

function errorCodeToString(error_code) {
  if ([YU2_TIMEOUT, YU2_HOST_RESOLVE, YU2_SSL_ERROR, YU2_FAIL].contains(error_code))
    return "80130182"
  else if ([YU2_WRONG_LOGIN,YU2_WRONG_PARAMETER].contains(error_code))
    return "80130183"
  else if (error_code == YU2_FROZEN) 
    return "8111000E"
  else if (error_code == YU2_FROZEN_BRUTEFORCE)
    return "8111000F" 

  else if (error_code == YU2_SSL_CACERT)
    return "80130184" 

  else if (error_code == YU2_WRONG_2STEP_CODE) {
    let { secStepType } = authState.get()
    return secStepType == SST_MAIL ? "YU2_WRONG_2STEP_CODE_EMAIL" : "YU2_WRONG_2STEP_CODE"
  }

  return format("%X", error_code & 0xFFFFFFFF)
}

function getErrorData(error_code) {
  local errCode = error_code
  if (type(error_code) != "string") {
    errCode = errorCodeToString(error_code)
    if (matching.is_matching_error(error_code))
      return matchingErrData(matching.error_string(error_code)).__update({ errCode })
  }
  return defErrData(errCode).__update({ errCode })
}

function getErrorMsgParams(errCodeBase) {
  local { text, errCode, bqLocId } = getErrorData(errCodeBase)
  return {
    uid = "errorMessageBox"
    viewType = "errorMsg"
    text
    bqLocId
    moreInfoLink = curtomUrls?[errCodeBase] ?? "".concat(loc($"url/knowledgebase"), errCode)
    debugString = get_last_session_debug_info()
  }
}

function errorMsgBox(errCode, buttons, ovr = {}) {
  let params = getErrorMsgParams(errCode)
  sendErrorLocIdBqEvent(params.bqLocId)
  openFMsgBox(params.__update(ovr, { buttons }))
}


register_command(
  function() {
    set_last_session_debug_info("sid:12345678")
    errorMsgBox(SERVER_ERROR_FORCE_DISCONNECT,
      [{ id = "exit", eventId = "matchingExitGame", styleId = "PRIMARY", isDefault = true }],
      { isPersist = true })
  },
  "debug.matchingError")
register_command(
  @() errorMsgBox(YU2_WRONG_LOGIN,
    [
      { id = "recovery", eventId = "loginRecovery", hotkeys = ["^J:X"] }
      { id = "exit", eventId = "loginExitGame", hotkeys = ["^J:Y"] }
      { id = "tryAgain", styleId = "PRIMARY", isDefault = true }
    ]),
  "debug.loginError")

return {
  errorMsgBox
  getErrorMsgParams
}