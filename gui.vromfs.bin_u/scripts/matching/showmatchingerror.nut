from "%scripts/dagui_library.nut" import *
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { replace } = require("%sqstd/string.nut")
let { isDownloadedFromGooglePlay } = require("android.platform")
let { sendErrorBqEvent, sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { is_ios } = require("%sqstd/platform.nut")

let customErrorHandlers = {
  [SERVER_ERROR_INVALID_VERSION & 0xFFFFFFFF] = function onInvalidVersion() {
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
  [SERVER_ERROR_PROTOCOL_MISMATCH & 0xFFFFFFFF] = function onProtocolMismatch() {
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
}

let function showMatchingError(response) {
  if (response.error == OPERATION_COMPLETE)
    return false
  if (::disable_network())
    return true
  if ((response.error & 0xFFFFFFFF) in customErrorHandlers) {
    customErrorHandlers[response.error & 0xFFFFFFFF]()
    return true
  }

  let errorId = response?.error_id ?? ::matching.error_string(response.error)
  let locId = "".concat("matching/", replace(errorId, ".", "_"))
  local text = loc(locId)
  if ("error_message" in response)
    text = $"{text}\n<B>{response.error_message}</B>"

  sendErrorLocIdBqEvent(locId)
  openFMsgBox({ text,
    uid = "sessionLobby_error",
    isPersist = true,
    viewType = "errorMsg",
    debugString = getroottable()?["LAST_SESSION_DEBUG_INFO"]
  })
  return true
}

return showMatchingError