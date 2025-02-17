from "%scripts/dagui_natives.nut" import is_online_available
from "%scripts/dagui_library.nut" import *
let logMC = log_with_prefix("[MATCHING_CONNECT] ")
let { format } = require("string")
let { register_command } = require("console")
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { dgs_get_settings } = require("dagor.system")
let { isDownloadedFromGooglePlay, getPackageName } = require("android.platform")
let { shell_execute } = require("dagor.shell")
let { BAN_USER_INFINITE_PENALTY } = require("penalty")
let { get_time_msec } = require("dagor.time")
let { resetTimeout } = require("dagor.workcycle")
let { is_ios } = require("%sqstd/platform.nut")
let { canLogout, startLogout, startRelogin } = require("%scripts/login/loginStart.nut")
let { isMatchingOnline } = require("%appGlobals/loginState.nut")
let { wndStartActiveMsec, wndStartInactiveMsec, windowActive } = require("%appGlobals/windowState.nut")
let exitGame = require("%scripts/utils/exitGame.nut")
let { openFMsgBox, closeFMsgBox, subscribeFMsgBtns } = require("%appGlobals/openForeignMsgBox.nut")
let { getErrorMsgParams } = require("%scripts/utils/errorMsgBox.nut")
let { sendErrorBqEvent, sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { SERVER_ERROR_INVALID_VERSION, CLIENT_ERROR_CONNECTION_CLOSED } = require("matching.errors")
let matching = require("%appGlobals/matching_api.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { isDownloadedFromSite } = require("%appGlobals/clientState/clientState.nut")


let RELOGIN_MIN_INACTIVE_TIME = 120
let RELOGIN_TIME_AFTER_INACTIVE = 30

local needReloginOnWindowActivate = false

isMatchingOnline(is_online_available())

subscribeFMsgBtns({
  matchingConnectCancel = @(_) openFMsgBox({
    uid = "no_online_warning",
    text = loc("mainmenu/noOnlineWarning")
  })
  matchingExitGame = @(_) exitGame()

  function exitAndLinkToStore (_) {
    let url = dgs_get_settings()?.storeUrl
    if (url != null)
      shell_execute({ cmd = "action", file = url })
    exitGame()
  }

  function exitGameForUpdate(_) {
    if (is_ios)
      shell_execute({ cmd = "open", file = "itms-apps://itunes.apple.com/app/apple-store/id1577525428?mt=8" })
    else if (isDownloadedFromGooglePlay())
      shell_execute({ cmd = "action", file = $"market://details?id={getPackageName()}" })
    else if (isDownloadedFromSite)
      eventbus_send("fMsgBox.onClick.tryToDownloadApkFromSite", null)
    else
      eventbus_send("fMsgBox.onClick.exitAndLinkToStore", null)
  }
})

function showMatchingConnectProgress() {
  if (isMatchingOnline.value)
    return
  openFMsgBox({
    uid = "matching_connect_progressbox",
    text = loc("yn1/connecting_msg"),
    buttons = [{ id = "cancel", eventId = "matchingConnectCancel", isCancel = true }],
    isPersist = true
  })
}

function destroyConnectProgressMessages() {
  closeFMsgBox("no_online_warning")
  closeFMsgBox("matching_connect_progressbox")
}

let leaveQueueImpl = @() eventbus_send("leaveQueue", {})

let getLogoutButtons = @(forceExit) forceExit || !canLogout()
  ? [{ id = "exit", eventId = "matchingExitGame", styleId = "PRIMARY", isDefault = true }]
  : [{ id = "ok", styleId = "PRIMARY", isDefault = true }]

matching.subscribe("mrpc.punish_client", function(p, send_resp) {
  if (canLogout())
    startLogout()
  send_resp(null)

  let { message = "", duration = 0, start = 0 } = p?.details
  if (duration.tointeger() >= BAN_USER_INFINITE_PENALTY) {
    openFMsgBox({
      text = "\n\n".concat(
        loc("charServer/ban/permanent"),
        message)
      buttons = getLogoutButtons(false)
      isPersist = true
    })
    return
  }

  let durationSec = duration.tointeger()
  let startSec = start.tointeger()
  openFMsgBox({
    text = "\n".concat(
      format(loc("charServer/ban/timed"), secondsToHoursLoc(durationSec)),
      serverTime.get() <= 0 ? ""
        : format(loc("charServer/ban/timeLeft"),
            secondsToHoursLoc(startSec + durationSec - serverTime.get())),
      " ",
      message
    )
    buttons = getLogoutButtons(false)
    isPersist = true
  })
})

let customErrorHandlers = {
  [SERVER_ERROR_INVALID_VERSION] = function(_, __, ___) {
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
  },
  [CLIENT_ERROR_CONNECTION_CLOSED] = function(_, __, ___) {
    leaveQueueImpl()
  }
}

windowActive.subscribe(function(v) {
  if (!v || !needReloginOnWindowActivate)
    return
  needReloginOnWindowActivate = false
  logMC("Start relogin on window activate")
  startRelogin()
})

function silentReloginInsteadLogout() {
  if (!windowActive.get()) {
    logMC("Start logout with pending relogin on disconnect while window not active")
    startLogout()
    needReloginOnWindowActivate = true
    return true
  }
  let time = get_time_msec()
  let needRelogin = (time - wndStartActiveMsec.get() <= 1000 * RELOGIN_TIME_AFTER_INACTIVE
    && wndStartActiveMsec.get() - wndStartInactiveMsec.get() >= 1000 * RELOGIN_MIN_INACTIVE_TIME)
  if (needRelogin) {
    logMC("Start silent relogin because of disconnect after long window inactive")
    startRelogin()
  }
  return needRelogin
}

function logoutWithMsgBox(reason, message, reasonDomain, forceExit = false) {
  logMC($"{forceExit ? "exit" : "logout"}WithMsgBox: reason = {format("0x%X", reason)}, message = {message}, domain = {reasonDomain}")
  destroyConnectProgressMessages()
  let handler = customErrorHandlers?[reason]
  if (handler != null) {
    handler(message, reasonDomain, forceExit)
    return
  }

  if (!forceExit && canLogout()) {
    if (silentReloginInsteadLogout())
      return
    startLogout()
  }

  let msg = getErrorMsgParams(reason)
  sendErrorLocIdBqEvent(msg.bqLocId)

  openFMsgBox(msg
    .__update({
      text = (message ?? "") == "" ? msg.text : $"{msg.text}\n\n{message}"
      buttons = getLogoutButtons(forceExit)
      isPersist = true
    }))
}

function exitForDownloadApkMsgBox(message) {
  destroyConnectProgressMessages()
  sendErrorBqEvent("Exit for download Apk")
  openFMsgBox({
    uid = "exitForDownloadApkMessageBox"
    text = message
    buttons = [{ id = "exit", eventId = "matchingExitGame", styleId = "PRIMARY", isDefault = true }]
    isPersist = true
  })
}

eventbus_subscribe("on_online_unavailable", function(_) {
  logMC("on_online_unavailable")
  isMatchingOnline(false)
})

eventbus_subscribe("on_online_available", function on_online_available(...) {
  logMC("on_online_available")
  isMatchingOnline(true)
  destroyConnectProgressMessages()
  eventbus_send("onMatchingOnlineAvailable", null)
})

eventbus_subscribe("logout_with_msgbox", @(params)
  logoutWithMsgBox(params.reason, params?.message, params.reasonDomain, false))

eventbus_subscribe("exit_queue_with_msgbox", @(params)
  logoutWithMsgBox(params.reason, params?.message, params.reasonDomain, false))

eventbus_subscribe("exit_with_msgbox", @(params)
  logoutWithMsgBox(params.reason, params?.message, params.reasonDomain, true))

eventbus_subscribe("exit_for_download_apk", @(params) exitForDownloadApkMsgBox(params.message))

register_command(
  @() logoutWithMsgBox(SERVER_ERROR_INVALID_VERSION, "Test invalid version", null, false),
  "debug.matchingLogoutInvalidVersion")

register_command(
  @(time) resetTimeout(time, @() logoutWithMsgBox(0x80002008, null, "matching", false)),
  "debug.matchingPendingDisconnectLogout")

return {
  isMatchingOnline
  showMatchingConnectProgress
}
