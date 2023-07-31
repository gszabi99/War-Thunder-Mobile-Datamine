from "%scripts/dagui_library.nut" import *

//checked for explicitness
#no-root-fallback
#explicit-this

let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { isDownloadedFromGooglePlay } = require("android.platform")

let customErrorHandlers = {
  [SERVER_ERROR_INVALID_VERSION] = function onInvalidVersion() {
    openFMsgBox({
      uid = "errorMessageBox"
      text = loc(isDownloadedFromGooglePlay() ? "updater/newVersion/desc/android"
        : "updater/newVersion/desc")
      buttons = [
        { id = "cancel", isCancel = true }
        { text = loc("updater/btnUpdate"), eventId = "exitGameForUpdate",
          isPrimary = true, isDefault = true }
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
  local text = loc("".concat("matching/", ::g_string.replace(errorId, ".", "_")))
  if ("error_message" in response)
    text = $"{text}\n<B>{response.error_message}</B>"

  openFMsgBox({ text,
    uid = "sessionLobby_error",
    isPersist = true,
    viewType = "errorMsg",
    debugString = getroottable()?["LAST_SESSION_DEBUG_INFO"]
  })
  return true
}

return showMatchingError