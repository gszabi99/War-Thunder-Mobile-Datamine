from "%globalsDarg/darg_library.nut" import *
let logM = log_with_prefix("[MSGBOX] ")
let { register_command } = require("console")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { addModalWindow, removeModalWindow } = require("modalWindows.nut")
let { textButton, buttonsHGap, mergeStyles } = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let closeWndBtn = require("%rGui/components/closeWndBtn.nut")
let { btnAUp, btnBEscUp, EMPTY_ACTION } = require("%rGui/controlsMenu/gpActBtn.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { locColorTable } = require("%rGui/style/stdColors.nut")

let wndWidthDefault = hdpx(1106) // 1-2 buttons
let wndWidthWide = hdpx(1500) // 3 buttons
let wndHeight = hdpx(652)
let wndHeaderHeight = hdpx(105)

let function mkBtn(b, wndUid) {
  let { id = "", text = null, cb = null, hotkeys = null, isCancel = false, isDefault = false,
    styleId = "COMMON" } = b
  let style = buttonStyles?[styleId]
  if (!style)
    logerr($"StyleId {styleId} doesn't exist in buttonStyles")

  return textButton(utf8ToUpper(text ?? loc($"msgbox/btn_{id}")),
    function onClick() {
      removeModalWindow(wndUid)
      cb?()
    },
    mergeStyles(style ?? buttonStyles.COMMON, {
      hotkeys = hotkeys
        ?? (isDefault ? [btnAUp]
          : isCancel ? [btnBEscUp]
          : null)
    }))
}

let mkMsgBoxBtnsSet = @(wndUid, btnsCfg) btnsCfg.map(@(b) mkBtn(b, wndUid))

let msgBoxText = @(text, ovr = {}) {
  size = flex()
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = 0xFFC0C0C0
  text
  colorTable = locColorTable
}.__update(fontSmall, ovr)

let msgBoxBg = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = 0xFF161B23
  stopMouse = true
}

let headerBg = {
  size = [ flex(), wndHeaderHeight ]
  rendObj = ROBJ_SOLID
  color = 0xFF1C2026
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
}

let msgBoxHeader = @(text, ovr = {}) headerBg.__merge({
  children = {
    rendObj = ROBJ_TEXT
    text
  }.__update(fontSmall)
}, ovr)

let msgBoxHeaderWithClose = @(text, close, ovr = {}) headerBg.__merge({
  children = [
    {
      rendObj = ROBJ_TEXT
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      padding = [0,hdpx(50), 0, hdpx(50)]
      text
    }.__update(fontSmall)
    closeWndBtn(close)
  ]
}, ovr)

let mkCustomMsgBoxWnd = @(title, content, buttonsArray, ovr = {}) msgBoxBg.__merge({
  size = [ buttonsArray.len() <= 2 ? wndWidthDefault : wndWidthWide, wndHeight ]
  flow = FLOW_VERTICAL
  children = [
    type(title) == "string" ? msgBoxHeader(title) : title,
    {
      size = flex()
      flow = FLOW_VERTICAL
      padding = [ 0, buttonsHGap, buttonsHGap, buttonsHGap ]
      children = [
        type(content) == "string" ? msgBoxText(content) : content,
        {
          size = [ flex(), SIZE_TO_CONTENT ]
          halign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = { size = flex() }
          children = buttonsArray
        }
      ]
    }
  ]
},
  ovr)

let defaultBtnsCfg = freeze([ { id = "ok", styleId = "PRIMARY", isDefault = true } ])
let function closeMsgBox(uid) {
  if (removeModalWindow(uid))
    logM($"close '{uid}'")
}

let function openMsgBox(text, uid = null, title = null, buttons = defaultBtnsCfg, wndOvr = {}) {
  uid = uid ?? $"msgbox_{text}"
  closeMsgBox(uid)
  logM($"open '{uid}'")
  addModalWindow(bgShaded.__merge({
    key = uid
    size = flex()
    children = mkCustomMsgBoxWnd(title, text, mkMsgBoxBtnsSet(uid, buttons), wndOvr)
    onClick = EMPTY_ACTION
    animations = wndSwitchAnim
  }))
  return uid
}

register_command(@() openMsgBox("Some test message box\nwith two buttons", null, "msgbox title",
    [
      { id = "cancel", isCancel = true, cb = @() dlog("Cancel!") }   //warning disable: -forbidden-function
      { id = "ok", styleId = "PRIMARY", isDefault = true, cb = @() dlog("Ok!") }   //warning disable: -forbidden-function
    ]
  ),
  "debug.showMessageBox")

register_command(@(text) openMsgBox(text), "debug.showMessageBoxText")

return {
  openMsgBox = kwarg(openMsgBox)
  closeMsgBox
  mkCustomMsgBoxWnd
  mkMsgBoxBtnsSet
  msgBoxText
  defaultBtnsCfg
  msgBoxBg
  msgBoxHeader
  msgBoxHeaderWithClose

  wndWidthDefault
  wndHeight
}
