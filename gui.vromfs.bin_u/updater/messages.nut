from "%globalsDarg/darg_library.nut" import *
let {
  isDownloadedFromGooglePlay = @() false,
  getPackageName = @() ""
} = require_optional("android.platform")
let { is_ios } = require("%sqstd/platform.nut")
let { register_command  = @(_, __) null } = require_optional("console") //only in debug mode
let { shell_execute } = require("dagor.shell")
let { dgs_get_settings, exit } = require("dagor.system")
let { send_counter = @(_, __, ___) null } = require_optional("statsd")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { needUpdateMsg, needRestartMsg } = require("updaterState.nut")


let wndWidth = hdpx(1100)
let wndHeight = hdpx(550)
let wndHeaderHeight = hdpx(105)
let buttonHeight = hdpx(105)
let buttonMinWidth = hdpx(370)
let buttonsHGap = hdpx(64)

let msgBoxHeader = @(text) {
  size = [ flex(), wndHeaderHeight ]
  rendObj = ROBJ_SOLID
  color = 0xFF1C2026
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text
  }.__update(fontSmall)
}

let msgBoxText = @(text) {
  size = flex()
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = 0xFFC0C0C0
  text
}.__update(fontSmall)

let mkMsgBox = @(title, desc, buttons) {
  size = [ wndWidth, wndHeight ]
  rendObj = ROBJ_SOLID
  color = 0xDC161B23
  flow = FLOW_VERTICAL
  children = [
    msgBoxHeader(title)
    {
      size = flex()
      flow = FLOW_VERTICAL
      padding = [ 0, buttonsHGap, buttonsHGap, buttonsHGap ]
      children = [
        msgBoxText(desc),
        {
          size = [ flex(), SIZE_TO_CONTENT ]
          halign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = { size = flex() }
          children = buttons
        }
      ]
    }
  ]
}

let patternImage = {
  size = [ph(100), ph(100)]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#button_pattern.svg:{buttonHeight}:{buttonHeight}:P")
  keepAspect = KEEP_ASPECT_NONE
  color = Color(0, 0, 0, 35)
}

let pattern = {
  size = flex()
  clipChildren = true
  flow = FLOW_HORIZONTAL
  children = array(7, patternImage)
}

function mkButton(text, onClick) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [SIZE_TO_CONTENT, buttonHeight]
    minWidth = buttonMinWidth
    fillColor = 0xFF0593AD
    borderColor = 0xFF236DB5
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_BOX
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    onClick
    brightness = stateFlags.value & S_HOVER ? 1.5 : 1
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    children = [
      pattern
      {
        size = flex()
        rendObj = ROBJ_9RECT
        image = Picture($"ui/gameuiskin#gradient_button.svg")
        color = 0xFF16B2E9
      }
      {
        rendObj = ROBJ_TEXT
        text
        fontFx = FFT_GLOW
        fontFxFactor = hdpx(64)
        fontFxColor = 0xFF000000
      }.__update(fontSmallAccented)
    ]
  }
}

function openUpdateUrl() {
  send_counter("sq.app.stage", 1, { stage = "open_update_from_store_url" })

  if (isDownloadedFromGooglePlay())
    shell_execute({ cmd = "action", file = $"market://details?id={getPackageName()}" })
  else {
    let url = dgs_get_settings()?.storeUrl
    if (url != null)
      shell_execute({ cmd = is_ios ? "open" : "action", file = url })
  }
  exit(0)
}

local updateLocId = isDownloadedFromGooglePlay() ? "updater/newVersion/desc/android"
  : "updater/newVersion/desc"
let updateMsg = mkMsgBox(loc("updater/newVersion/header"),
  loc(updateLocId),
  mkButton(utf8ToUpper(loc("updater/btnUpdate")), openUpdateUrl))
let restartMsg = mkMsgBox(loc("updater/newVersion/header"),
  loc("updater/restartForUpdate/desc"),
    mkButton(utf8ToUpper(loc("msgbox/btn_restart")), @() exit(0)))

register_command(@() needUpdateMsg(!needUpdateMsg.value), "debug.updateMessage")
register_command(@() needRestartMsg(!needRestartMsg.value), "debug.restartMessage")

return @() {
  watch = [needUpdateMsg, needRestartMsg]
  pos = [0, -hdpx(100)]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = needUpdateMsg.get() ? updateMsg
    : needRestartMsg.get() ? restartMsg
    : null
}