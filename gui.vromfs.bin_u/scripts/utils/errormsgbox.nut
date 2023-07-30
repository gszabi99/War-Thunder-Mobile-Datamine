from "%scripts/dagui_library.nut" import *
//-file:plus-string
//checked for explicitness
#no-root-fallback
#explicit-this

let { format } = require("string")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { register_command } = require("console")

let matchingErrMsg = @(error_text) loc("yn1/error/fmt",
  {
    text = loc("yn1/connect_error"),
    err_msg = loc("matching/" + error_text, error_text),
    err_code = ""
  })

let function defErrMsg(res) {
  local errCode = res == "0" ? "" : res
  local errMsg = loc("yn1/error/" + errCode, "")
  if (!errMsg.len()) {
    errMsg = $"0x{errCode}"
    errCode = ""
  }
  return loc("yn1/error/fmt", {
    text = loc("yn1/connect_error", "")
    err_msg = errMsg
    err_code = errCode
  })
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

  return format("%X", error_code)
}

let function getErrorData(error_code) {
  local errCode = error_code
  local text = null
  if (type(error_code) != "string") {
    errCode = errorCodeToString(error_code)
    if (::matching.is_matching_error(error_code))
      text = matchingErrMsg(::matching.error_string(error_code))
  }

  return { errCode, text = text ?? defErrMsg(errCode) }
}

let function getErrorMsgParams(errCodeBase) {
  local { text, errCode } = getErrorData(errCodeBase)
  return {
    uid = "errorMessageBox"
    viewType = "errorMsg"
    text
    moreInfoLink = "".concat(loc($"url/knowledgebase"), errCode)
    debugString = ("LAST_SESSION_DEBUG_INFO" in getroottable()) ? ::LAST_SESSION_DEBUG_INFO : null
  }
}

let errorMsgBox = @(errCode, buttons, ovr = {})
  openFMsgBox(getErrorMsgParams(errCode)
    .__update(ovr, { buttons }))


register_command(
  function() {
    ::LAST_SESSION_DEBUG_INFO <- "sid:12345678"
    errorMsgBox(SERVER_ERROR_FORCE_DISCONNECT,
      [{ id = "exit", eventId = "matchingExitGame", isPrimary = true, isDefault = true }],
      { isPersist = true })
  },
  "debug.matchingError")
register_command(
  @() errorMsgBox(YU2_WRONG_LOGIN,
    [
      { id = "recovery", eventId = "loginRecovery", hotkeys = ["^J:X"] }
      { id = "exit", eventId = "loginExitGame", hotkeys = ["^J:Y"] }
      { id = "tryAgain", isPrimary = true, isDefault = true }
    ]),
  "debug.loginError")

return {
  errorMsgBox
  getErrorMsgParams
}