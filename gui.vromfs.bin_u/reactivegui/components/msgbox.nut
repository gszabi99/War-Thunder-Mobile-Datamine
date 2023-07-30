from "%globalsDarg/darg_library.nut" import *
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { addModalWindow, removeModalWindow } = require("modalWindows.nut")
let { textButtonCommon, textButtonFaded, textButtonPurchase, buttonsHGap
} = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let closeWndBtn = require("%rGui/components/closeWndBtn.nut")
let { btnA, btnB, EMPTY_ACTION } = require("%rGui/controlsMenu/gpActBtn.nut")

let wndWidthDefault = hdpx(1106) // 1-2 buttons
let wndWidthWide = hdpx(1500) // 3 buttons
let wndHeight = hdpx(652)
let wndHeaderHeight = hdpx(105)

let function mkBtn(b, wndUid) {
  let { id = "", text = null, cb = null, isPurchase = false, isPrimary = false, hotkeys = null,
    isCancel = false, isDefault = false
  } = b
  let ctor = isPurchase ? textButtonPurchase
    : isPrimary ? textButtonCommon
    : textButtonFaded
  return ctor(utf8ToUpper(text ?? loc($"msgbox/btn_{id}")),
    function onClick() {
      removeModalWindow(wndUid)
      cb?()
    },
    {
      hotkeys = hotkeys
        ?? (isDefault ? [btnA]
          : isCancel ? [btnB]
          : null)
    })
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
}.__update(fontSmall, ovr)

let msgBoxBg = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = 0xDC161B23
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
      text
    }.__update(fontSmall)
    closeWndBtn(close)
  ]
}, ovr)

let mkCustomMsgBoxWnd = @(title, content, buttonsArray, ovr = {}) msgBoxBg.__merge({
  size = [ buttonsArray.len() <= 2 ? wndWidthDefault : wndWidthWide, wndHeight ]
  flow = FLOW_VERTICAL
  children = [
    title == null ? null : msgBoxHeader(title)
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

let defaultBtnsCfg = freeze([ { id = "ok", isPrimary = true, isDefault = true } ])
let closeMsgBox = removeModalWindow

let function openMsgBox(text, uid = null, title = null, buttons = defaultBtnsCfg) {
  uid = uid ?? $"msgbox_{text}"
  closeMsgBox(uid)
  addModalWindow(bgShaded.__merge({
    key = uid
    size = flex()
    children = mkCustomMsgBoxWnd(title, text, mkMsgBoxBtnsSet(uid, buttons))
    onClick = EMPTY_ACTION
    animations = wndSwitchAnim
  }))
  return uid
}

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
}
