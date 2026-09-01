from "%globalsDarg/darg_library.nut" import *
from "android.platform" import isDownloadedFromGooglePlay, getPackageName, getBuildMarket
from "app" import exitGame
from "console" import register_command
from "dagor.shell" import shell_execute
from "dagor.system" import dgs_get_settings
from "dagor.time" import get_time_msec
from "dagor.workcycle" import resetTimeout
from "eventbus" import eventbus_subscribe, eventbus_send
from "matching.errors" import SERVER_ERROR_INVALID_VERSION, CLIENT_ERROR_CONNECTION_CLOSED
from "penalty" import BAN_USER_INFINITE_PENALTY
from "string" import format
from "%sqstd/platform.nut" import is_ios
from "%appGlobals/clientState/clientState.nut" import isDownloadedFromSite
from "%appGlobals/loginState.nut" import isMatchingOnline
from "%rGui/matching/matchingApi.nut" import matching_subscribe
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox, closeFMsgBox, subscribeFMsgBtns
from "%appGlobals/pServer/bqClient.nut" import sendErrorBqEvent, sendErrorLocIdBqEvent
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%appGlobals/windowState.nut" import wndStartActiveMsec, wndStartInactiveMsec, windowActive
from "online" import is_online_available
from "guiScriptUtils" import disable_network
from "%appGlobals/errorMsgBox.nut" import getErrorMsgParams


let logMC = log_with_prefix("[MATCHING_CONNECT] ")


let canLogout = @() !disable_network()
let startLogout = @() eventbus_send("logOut", {})
let startRelogin = @() eventbus_send("login.startRelogin", {})
let isHuaweiBuild = getBuildMarket() == "appgallery"

const RELOGIN_MIN_INACTIVE_TIME = 120
const RELOGIN_TIME_AFTER_INACTIVE = 30

local needReloginOnWindowActivate = false

isMatchingOnline.set(is_online_available())

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
      shell_execute({ cmd = "action", file = $"https://play.google.com/store/apps/details?id={getPackageName()}" })
    else if (isHuaweiBuild)
      shell_execute({ cmd = "action", file = "https://appgallery.huawei.com/app/C113458691" })
    else if (isDownloadedFromSite)
      eventbus_send("fMsgBox.onClick.tryToDownloadApkFromSite", null)
    else
      eventbus_send("fMsgBox.onClick.exitAndLinkToStore", null)
  }
})

function showMatchingConnectProgress() {
  if (isMatchingOnline.get())
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

matching_subscribe("mrpc.punish_client", function(p, send_resp) {
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
      text = (isDownloadedFromGooglePlay() || isHuaweiBuild)
              ? loc("updater/newVersion/desc/android", {market = isHuaweiBuild ? "AppGallery" : "Google Play"})
              : loc("updater/newVersion/desc")
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
  isMatchingOnline.set(false)
})

eventbus_subscribe("on_online_available", function on_online_available(...) {
  logMC("on_online_available")
  isMatchingOnline.set(true)
  destroyConnectProgressMessages()
  eventbus_send("onMatchingOnlineAvailable", null)
})

eventbus_subscribe("logout_with_msgbox", @(params)
  logoutWithMsgBox(params.reason, params?.message, params.reasonDomain, false))

eventbus_subscribe("exit_with_msgbox", @(params)
  logoutWithMsgBox(params.reason, params?.message, params.reasonDomain, true))

eventbus_subscribe("exit_queue_with_msgbox",
  function(_) {
    logMC("Leave queue on exit_queue_with_msgbox")
    destroyConnectProgressMessages()
    leaveQueueImpl()
  })

eventbus_subscribe("exit_for_download_apk", @(params) exitForDownloadApkMsgBox(params.message))

register_command(
  @() logoutWithMsgBox(SERVER_ERROR_INVALID_VERSION, "Test invalid version", null, false),
  "debug.matchingLogoutInvalidVersion")

register_command(
  @(time) resetTimeout(time, @() logoutWithMsgBox(0x80002008, null, "matching", false)),
  "debug.matchingPendingDisconnectLogout")

return {
  showMatchingConnectProgress
}
