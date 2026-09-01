from "%globalsDarg/darg_library.nut" import *
from "dagor.shell" import shell_execute
from "dagor.system" import dgs_get_settings, exit
from "%sqstd/platform.nut" import is_ios
from "%sqstd/string.nut" import utf8ToUpper
from "%globalsDarg/updaterUtils.nut" import totalSizeText
from "gradients.nut" import mkColoredGradientY, gradTranspDoubleSideX, gradDoubleTexOffset
from "updaterState.nut" import needUpdateMsg, needRestartMsg, needDownloadAcceptMsg, needNotEnoughDiskSpaceMsg,
  totalSizeBytes, freeDiskSpaceMB, requiredDiskSpaceMB, closeDownloadWarning, isFailedToGetVersion


let {
  isDownloadedFromGooglePlay = @() false,
  getPackageName = @() ""
  getBuildMarket = @() "googleplay"
} = require_optional("android.platform")
let { register_command  = @(_, __) null } = require_optional("console") 
let { send_counter = @(_, __, ___) null } = require_optional("statsd")
let isHuaweiBuild = getBuildMarket() == "appgallery"

const wndWidth = hdpx(1100)
const wndHeight = hdpx(550)
let wndHeaderHeight = evenPx(76)
const buttonHeight = hdpx(105)
const buttonMinWidth = hdpx(370)
const buttonsHGap = hdpx(64)
const buttonBorderWidth = hdpx(3)
const paddingX = hdpx(38)
const buttonTextWidth = buttonMinWidth - 2 * paddingX

let bgMessage = {
  rendObj = ROBJ_IMAGE
  image = mkColoredGradientY(0xFF304453, 0xFF030C13)
}

let bgHeader = {
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, hdpx(300)]
  color = 0x80505780
}

let msgBoxHeader = @(text) bgHeader.__merge({
  size = [ FLEX, wndHeaderHeight ]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text
  }.__update(fontSmall)
})

let msgBoxText = @(text) {
  size = FLEX
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = 0xFFC0C0C0
  text
}.__update(fontSmall)

let mkMsgBox = @(title, desc, buttons) bgMessage.__merge({
  size = const [ wndWidth, wndHeight ]
  flow = FLOW_VERTICAL
  children = [
    msgBoxHeader(title)
    {
      size = FLEX
      flow = FLOW_VERTICAL
      padding = [ 0, buttonsHGap, buttonsHGap, buttonsHGap ]
      children = [
        msgBoxText(desc),
        {
          size = FLEX_H
          halign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = { size = FLEX }
          children = buttons
        }
      ]
    }
  ]
})

function mkButton(text, onClick) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = const [SIZE_TO_CONTENT, buttonHeight]
    minWidth = buttonMinWidth
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_BOX
    fillColor = 0xFFB9B9B9
    behavior = Behaviors.Button
    sound = { click = "click" }
    onClick
    onElemState = @(v) stateFlags.set(v)
    brightness = stateFlags.get() & S_HOVER ? 1.25 : 1
    transform = {
      scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    children = {
      size = FLEX
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      rendObj = ROBJ_9RECT
      image = Picture($"ui/gameuiskin#gradient_button.svg")
      padding = buttonBorderWidth
      color = 0xFFEEEEEE
      children = {
        size = FLEX
        rendObj = ROBJ_BOX
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        clipChildren = true
        fillColor = 0xFF3A5D91
        children = [
          {
            size = FLEX
            rendObj = ROBJ_9RECT
            color = 0xFF7395CF
            image = Picture($"ui/gameuiskin#gradient_button.svg")
          }
          {
            size = const [buttonTextWidth, SIZE_TO_CONTENT]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text
            halign = ALIGN_CENTER
          }.__update(fontBoldTinyShaded)
        ]
      }
    }
  }
}

function openUpdateUrl() {
  send_counter("sq.app.stage", 1, { stage = "open_update_from_store_url" })

  if (isDownloadedFromGooglePlay())
    shell_execute({ cmd = "action", file = $"https://play.google.com/store/apps/details?id={getPackageName()}" })
  else if (isHuaweiBuild)
    shell_execute({ cmd = "action", file = "https://appgallery.huawei.com/app/C113458691" })
  else {
    let url = dgs_get_settings()?.storeUrl
    if (url != null)
      shell_execute({ cmd = is_ios ? "open" : "action", file = url })
  }
  
}

function openSupportUrl() {
  shell_execute({ cmd = "action", file = loc("url/feedback/support") }) 
  exit(0)
}

local updateLocId = isDownloadedFromGooglePlay() || isHuaweiBuild ? "updater/newVersion/desc/android"
  : "updater/newVersion/desc"
let updateMsg = mkMsgBox(loc("updater/newVersion/header"),
  loc(updateLocId, { market = isHuaweiBuild ? "AppGallery" : "Google Play" }),
  mkButton(utf8ToUpper(loc("updater/btnUpdate")), openUpdateUrl))
let restartMsg = mkMsgBox(loc("updater/newVersion/header"),
  loc("updater/restartForUpdate/desc"),
  mkButton(utf8ToUpper(loc("msgbox/btn_restart")), @() exit(0)))
let failedToGetVersonMsg = mkMsgBox(loc("updater/failedToGetVersion/header"),
  loc("updater/failedToGetVersion/desc"),
  [
    mkButton(utf8ToUpper(loc("mainmenu/support")), openSupportUrl)
    mkButton(utf8ToUpper(loc("msgbox/btn_exit")), @() exit(0))
  ])
let downloadMsg = @(bytes) mkMsgBox(loc("updater/downloadWarning/header"),
  loc("updater/downloadWarning/desc", { totalSizeBytes = totalSizeText(bytes) }),
  mkButton(utf8ToUpper(loc("msgbox/btn_confirm")),
    function() {
      needDownloadAcceptMsg.set(false)
      closeDownloadWarning()
    }))
let notEnoughDiskSpaceMsg = @(freeDiskSpace, requiredDiskSpace) mkMsgBox(loc("updater/notEnoughDiskSpace/header"),
  loc("updater/notEnoughDiskSpace/desc", { freeDiskSpace, requiredDiskSpace }),
  mkButton(utf8ToUpper(loc("msgbox/btn_ok")), @() exit(0)))

register_command(@() needUpdateMsg.set(!needUpdateMsg.get()), "debug.updateMessage")
register_command(@() needRestartMsg.set(!needRestartMsg.get()), "debug.restartMessage")
register_command(@() needDownloadAcceptMsg.set(!needDownloadAcceptMsg.get()), "debug.downloadMessage")
register_command(@() needNotEnoughDiskSpaceMsg.set(!needNotEnoughDiskSpaceMsg.get()), "debug.notEnoughDiskSpaceMessage")

return @() {
  watch = [needUpdateMsg, needRestartMsg, needDownloadAcceptMsg, needNotEnoughDiskSpaceMsg, totalSizeBytes, freeDiskSpaceMB, requiredDiskSpaceMB]
  pos = const [0, -hdpx(100)]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = isFailedToGetVersion.get() ? failedToGetVersonMsg
    : needUpdateMsg.get() ? updateMsg
    : needRestartMsg.get() ? restartMsg
    : needDownloadAcceptMsg.get() ? downloadMsg(totalSizeBytes.get())
    : needNotEnoughDiskSpaceMsg.get() ? notEnoughDiskSpaceMsg(freeDiskSpaceMB.get(), requiredDiskSpaceMB.get())
    : null
}