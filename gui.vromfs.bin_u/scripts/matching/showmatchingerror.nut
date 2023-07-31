from "%scripts/dagui_library.nut" import *


let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { replace } = require("%sqstd/string.nut")
let { isDownloadedFromGooglePlay } = require("android.platform")
let { sendErrorBqEvent, sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")

let customErrorHandlers = {
  [SERVER_ERROR_INVALID_VERSION] = function onInvalidVersion() {
    sendErrorBqEvent("Downoad new version (optional)")
    openFMsgBox({
      uid = "errorMessageBox"
      text = loc(isDownloadedFromGooglePlay() ? "updater/newVersion/desc/android"
        : "updater/newVersion/desc")
      buttons = [
        { id = "cancel", isCancel = true }
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
  if (response.error in customErrorHandlers) {
    customErrorHandlers[response.error]()
    return
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