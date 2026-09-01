from "%globalsDarg/darg_library.nut" import *
from "android.platform" import isDownloadedFromGooglePlay, getBuildMarket
from "eventbus" import eventbus_subscribe
from "matching.errors" import SERVER_ERROR_INVALID_VERSION, OPERATION_COMPLETE, SERVER_ERROR_PROTOCOL_MISMATCH,
  CLIENT_ERROR_OFFLINE, SERVER_ERROR_REQUEST_TIMEOUT, matching_error_string
from "%sqstd/platform.nut" import is_ios
from "%sqstd/string.nut" import replace
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride
from "%appGlobals/errorMsgBox.nut" import lastSessionDebugInfo
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/pServer/bqClient.nut" import sendErrorBqEvent, sendErrorLocIdBqEvent
from "guiScriptUtils" import disable_network


let isHuaweiBuild = getBuildMarket() == "appgallery"
let supportContact = getCurCircuitOverride("supportSite", "support.gaijin.net")

function errorHandlerRetryMessage(code) {
  let errorId = matching_error_string(code)
  let locId = $"matching/{errorId}"
  sendErrorLocIdBqEvent(locId)
  openFMsgBox({
    uid = "errorMessageBox"
    text = loc(locId, { support = supportContact })
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
    text = (isDownloadedFromGooglePlay() || isHuaweiBuild)
      ? loc("updater/newVersion/desc/android", {market = isHuaweiBuild ? "AppGallery" : "Google Play"})
      : is_ios ? loc("updater/newVersion/desc/iOS")
      : loc("updater/newVersion/desc")
    buttons = [
      { text = loc("updater/btnUpdate"), eventId = "exitGameForUpdate",
        styleId = "PRIMARY", isDefault = true }
    ]
    isPersist = true
  })
}

function showRestartForUpdateMsg() {
  sendErrorBqEvent("Restart to apply update (required)")
  openFMsgBox({
    uid = "errorMessageBox"
    text = loc("updater/restartForUpdate/desc")
    buttons = [
      { text = loc("msgbox/btn_restart"), eventId = "matchingExitGame",
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
      text = (isDownloadedFromGooglePlay() || isHuaweiBuild)
        ? loc("updater/newVersion/desc/android", {market = isHuaweiBuild ? "AppGallery" : "Google Play"})
        : is_ios ? loc("updater/newVersion/desc/iOS")
        : loc("updater/newVersion/desc")
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
  if ((response?.error ?? OPERATION_COMPLETE) == OPERATION_COMPLETE)
    return false
  if (disable_network())
    return true
  if (response.error in customErrorHandlers) {
    customErrorHandlers[response.error]()
    return true
  }

  let errorId = response?.error_id ?? matching_error_string(response.error)
  let locId = "".concat("matching/", replace(errorId, ".", "_"))
  local text = loc(locId, { support = supportContact })
  if ("error_message" in response)
    text = $"{text}\n<B>{response.error_message}</B>"

  sendErrorLocIdBqEvent(locId)
  openFMsgBox({ text,
    uid = "sessionLobby_error",
    isPersist = true,
    viewType = "errorMsg",
    debugString = lastSessionDebugInfo.get()
  })
  return true
}

eventbus_subscribe("showIncompatibleVersionMsg", @(_) showIncompatibleVersionMsg())
eventbus_subscribe("showRestartForUpdateMsg", @(_) showRestartForUpdateMsg())

return showMatchingError
