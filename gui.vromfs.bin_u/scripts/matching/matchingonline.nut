from "%scripts/dagui_library.nut" import *
let { format } = require("string")
let { register_command } = require("console")
let logMC = log_with_prefix("[MATCHING_CONNECT] ")
let { subscribe } = require("eventbus")
let { dgs_get_settings } = require("dagor.system")
let { isDownloadedFromGooglePlay, getPackageName } = require("android.platform")
let { shell_execute } = require("dagor.shell")
let { is_ios } = require("%sqstd/platform.nut")
let { canLogout, startLogout } = require("%scripts/login/logout.nut")
let { isMatchingOnline } = require("%appGlobals/loginState.nut")
let exitGame = require("%scripts/utils/exitGame.nut")
let { openFMsgBox, closeFMsgBox, subscribeFMsgBtns } = require("%appGlobals/openForeignMsgBox.nut")
let { getErrorMsgParams } = require("%scripts/utils/errorMsgBox.nut")
let { sendErrorBqEvent, sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { SERVER_ERROR_INVALID_VERSION } = require("matching.errors")

enum REASON_DOMAIN {
  MATCHING = "matching"
  CHAR = "char"
  AUTH = "auth"
}

isMatchingOnline(::is_online_available())

subscribeFMsgBtns({
  matchingConnectCancel = @(_) openFMsgBox({
    uid = "no_online_warning",
    text = loc("mainmenu/noOnlineWarning")
  })
  matchingExitGame = @(_) exitGame()

  function exitGameForUpdate(_) {
    if (is_ios)
      shell_execute({ cmd = "open", file = "itms-apps://itunes.apple.com/app/apple-store/id1577525428?mt=8" })
    else if (isDownloadedFromGooglePlay())
      shell_execute({ cmd = "action", file = $"market://details?id={getPackageName()}" })
    else {
      let url = dgs_get_settings()?.storeUrl
      if (url != null)
        shell_execute({ cmd = "action", file = url })
    }
    exitGame()
  }
})

let function showMatchingConnectProgress() {
  if (isMatchingOnline.value)
    return
  openFMsgBox({
    uid = "matching_connect_progressbox",
    text = loc("yn1/connecting_msg"),
    buttons = [{ id = "cancel", eventId = "matchingConnectCancel", isCancel = true }],
    isPersist = true
  })
}

let function destroyConnectProgressMessages() {
  closeFMsgBox("no_online_warning")
  closeFMsgBox("matching_connect_progressbox")
}

let customErrorHandlers = {
  [SERVER_ERROR_INVALID_VERSION] = function onInvalidVersion(_, __, ___) {
    sendErrorBqEvent("Downoad new version (required)")
    openFMsgBox({
      uid = "errorMessageBox"
      text = loc(isDownloadedFromGooglePlay() ? "updater/newVersion/desc/android"
        : "updater/newVersion/desc")
      buttons = [
        { text = loc("updater/btnUpdate"), eventId = "exitGameForUpdate",
          styleId = "PRIMARY", isDefault = true }
      ]
      isPersist = true
    })
  }
}

let function logoutWithMsgBox(reason, message, reasonDomain, forceExit = false) {
  logMC($"{forceExit ? "exit" : "logout"}WithMsgBox: reason = {format("0x%X", reason)}, message = {message}, domain = {reasonDomain}")
  destroyConnectProgressMessages()
  let handler = customErrorHandlers?[reason]
  if (handler != null) {
    handler(message, reasonDomain, forceExit)
    return
  }

  local needExit = forceExit
  if (!needExit) {
    if (canLogout())
      startLogout()
    else
      needExit = true
  }

  let id = needExit ? "exit" : "ok"
  let eventId = needExit ? "matchingExitGame" : null
  let msg = getErrorMsgParams(reason)
  sendErrorLocIdBqEvent(msg.bqLocId)

  openFMsgBox(msg
    .__update({
      text = (message ?? "") == "" ? msg.text : $"{msg.text}\n\n{message}"
      buttons = [{ id, eventId, styleId = "PRIMARY", isDefault = true }]
      isPersist = true
    }))
}

subscribe("on_online_unavailable", function(_) {
  logMC("on_online_unavailable")
  isMatchingOnline(false)
})

//methods called from the native code
::on_online_available <- function on_online_available() {
  logMC("on_online_available")
  isMatchingOnline(true)
  destroyConnectProgressMessages()
}

::logout_with_msgbox <- @(params)
  logoutWithMsgBox(params.reason, params?.message, params.reasonDomain, false)

::exit_with_msgbox <- @(params)
  logoutWithMsgBox(params.reason, params?.message, params.reasonDomain, true)

register_command(
  @() logoutWithMsgBox(SERVER_ERROR_INVALID_VERSION, "Test invalid version", null, false),
  "debug.matchingLogoutInvalidVersion")

return {
  isMatchingOnline
  showMatchingConnectProgress
}
