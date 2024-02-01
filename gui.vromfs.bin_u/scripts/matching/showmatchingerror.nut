from "%scripts/dagui_natives.nut" import disable_network
from "%scripts/dagui_library.nut" import *

let { get_last_session_debug_info } = require("%scripts/matchingRooms/sessionDebugInfo.nut")
let { eventbus_subscribe } = require("eventbus")
let { SERVER_ERROR_INVALID_VERSION, OPERATION_COMPLETE,
SERVER_ERROR_PROTOCOL_MISMATCH, CLIENT_ERROR_OFFLINE, SERVER_ERROR_REQUEST_TIMEOUT } = require("matching.errors")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { replace } = require("%sqstd/string.nut")
let { isDownloadedFromGooglePlay } = require("android.platform")
let { sendErrorBqEvent, sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { is_ios } = require("%sqstd/platform.nut")
let matching = require("%scripts/matching_api.nut")

function errorHandlerRetryMessage(code) {
  let errorId = matching.error_string(code)
  let locId = $"matching/{errorId}"
  sendErrorLocIdBqEvent(locId)
  openFMsgBox({
    uid = "errorMessageBox"
    text = loc(locId)
    buttons = [
      { id = "tryAgain", styleId = "PRIMARY", isDefault = true }
    ]
    isPersist = true
  })
}

function showIncompatibleVersionMsg() {
  sendErrorBqEvent("Download new version (required)")
  openFMsgBox({
    uid = "errorMessageBox"
    text = loc(isDownloadedFromGooglePlay() ? "updater/newVersion/desc/android"
      : is_ios ? "updater/newVersion/desc/iOS"
      : "updater/newVersion/desc")
    buttons = [
      { text = loc("updater/btnUpdate"), eventId = "exitGameForUpdate",
        styleId = "PRIMARY", isDefault = true }
    ]
    isPersist = true
  })
}

let customErrorHandlers = {
  [SERVER_ERROR_INVALID_VERSION] = function onInvalidVersion() {
    sendErrorBqEvent("Download new version (optional)")
    openFMsgBox({
      uid = "errorMessageBox"
      text = loc(isDownloadedFromGooglePlay() ? "updater/newVersion/desc/android"
        : is_ios ? "updater/newVersion/desc/iOS"
        : "updater/newVersion/desc")
      buttons = [
        { id = "cancel", isCancel = true }
        { text = loc("updater/btnUpdate"), eventId = "exitGameForUpdate",
          styleId = "PRIMARY", isDefault = true }
      ]
      isPersist = true
    })
  },
  [SERVER_ERROR_PROTOCOL_MISMATCH] = showIncompatibleVersionMsg,
  [CLIENT_ERROR_OFFLINE] = @() errorHandlerRetryMessage(CLIENT_ERROR_OFFLINE),
  [SERVER_ERROR_REQUEST_TIMEOUT] = @() errorHandlerRetryMessage(SERVER_ERROR_REQUEST_TIMEOUT)
}

function showMatchingError(response) {
  if (response.error == OPERATION_COMPLETE)
    return false
  if (disable_network())
    return true
  if (response.error in customErrorHandlers) {
    customErrorHandlers[response.error]()
    return true
  }

  let errorId = response?.error_id ?? matching.error_string(response.error)
  let locId = "".concat("matching/", replace(errorId, ".", "_"))
  local text = loc(locId)
  if ("error_message" in response)
    text = $"{text}\n<B>{response.error_message}</B>"

  sendErrorLocIdBqEvent(locId)
  openFMsgBox({ text,
    uid = "sessionLobby_error",
    isPersist = true,
    viewType = "errorMsg",
    debugString = get_last_session_debug_info()
  })
  return true
}

eventbus_subscribe("showIncompatibleVersionMsg", @(_) showIncompatibleVersionMsg())

return showMatchingError
