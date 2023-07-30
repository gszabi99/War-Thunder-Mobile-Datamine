//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let logMC = log_with_prefix("[MATCHING_CONNECT] ")
let { subscribe } = require("eventbus")
let { canLogout, startLogout } = require("%scripts/login/logout.nut")
let exitGame = require("%scripts/utils/exitGame.nut")
let { openFMsgBox, closeFMsgBox, subscribeFMsgBtns } = require("%appGlobals/openForeignMsgBox.nut")
let { getErrorMsgParams } = require("%scripts/utils/errorMsgBox.nut")

enum REASON_DOMAIN {
  MATCHING = "matching"
  CHAR = "char"
  AUTH = "auth"
}

let isMatchingOnline = Watched(::is_online_available())

subscribeFMsgBtns({
  matchingConnectCancel = @(_) openFMsgBox({
    uid = "no_online_warning",
    text = loc("mainmenu/noOnlineWarning")
  })
  matchingExitGame = @(_) exitGame()
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

let function logoutWithMsgBox(reason, message, _reasonDomain, forceExit = false) {
  destroyConnectProgressMessages()

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

  openFMsgBox(msg
    .__update({
      text = (message ?? "") == "" ? msg.text : $"{msg.text}\n\n{message}"
      buttons = [{ id, eventId, isPrimary = true, isDefault = true }]
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

return {
  isMatchingOnline
  showMatchingConnectProgress
}