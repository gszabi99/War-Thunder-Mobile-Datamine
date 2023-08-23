from "%scripts/dagui_library.nut" import *
//-file:plus-string
let { format } = require("string")
let { doesLocTextExist } = require("dagor.localize")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { register_command } = require("console")
let { sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")

let curtomUrls = {
  [SERVER_ERROR_MAINTENANCE] = "https://www.wtmobile.com/news",
  ["CANNOT_LOGIN_WITH_LINKED_ACCOUNT"] = "",
}

let function matchingErrData(error_text) {
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

let function defErrData(res) {
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

let function errorCodeToString(error_code) {
  switch (error_code) {
    case YU2_TIMEOUT:
    case YU2_HOST_RESOLVE:
    case YU2_SSL_ERROR:
    case YU2_FAIL: // auth server is not available
      return "80130182"

    case YU2_WRONG_LOGIN:
    case YU2_WRONG_PARAMETER:
      return "80130183"

    case YU2_FROZEN: // account is frozen
      return "8111000E"

    case YU2_FROZEN_BRUTEFORCE:
      return "8111000F" // ERRCODE_AUTH_ACCOUNT_FROZEN_BRUTEFORCE

    case YU2_SSL_CACERT:
      return "80130184" // special error for this
  }

  return format("%X", error_code & 0xFFFFFFFF)
}

let function getErrorData(error_code) {
  local errCode = error_code
  if (type(error_code) != "string") {
    errCode = errorCodeToString(error_code)
    if (::matching.is_matching_error(error_code))
      return matchingErrData(::matching.error_string(error_code)).__update({ errCode })
  }
  return defErrData(errCode).__update({ errCode })
}

let function getErrorMsgParams(errCodeBase) {
  local { text, errCode, bqLocId } = getErrorData(errCodeBase)
  return {
    uid = "errorMessageBox"
    viewType = "errorMsg"
    text
    bqLocId
    moreInfoLink = curtomUrls?[errCodeBase] ?? "".concat(loc($"url/knowledgebase"), errCode)
    debugString = ("LAST_SESSION_DEBUG_INFO" in getroottable()) ? ::LAST_SESSION_DEBUG_INFO : null
  }
}

let function errorMsgBox(errCode, buttons, ovr = {}) {
  let params = getErrorMsgParams(errCode)
  sendErrorLocIdBqEvent(params.bqLocId)
  openFMsgBox(params.__update(ovr, { buttons }))
}


register_command(
  function() {
    ::LAST_SESSION_DEBUG_INFO <- "sid:12345678"
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