from "%globalsDarg/darg_library.nut" import *
let logM = log_with_prefix("[MSGBOX] ")
let { register_command } = require("console")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { addModalWindow, removeModalWindow, MWP_COMMON } = require("%rGui/components/modalWindows.nut")
let { textButtonMultiline, buttonsHGap, mergeStyles, textButton, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { btnAUp, btnBEscUp, EMPTY_ACTION } = require("%rGui/controlsMenu/gpActBtn.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { locColorTable } = require("%rGui/style/stdColors.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { spinner } = require("%rGui/components/spinner.nut")


let wndWidthDefault = hdpx(1106) 
let wndWidthWide = hdpx(1500) 
let wndHeight = hdpx(652)
let { defButtonHeight } = buttonStyles

function mkBtn(b, wndUid) {
  let { id = "", text = null, cb = null, hotkeys = null, isCancel = false, isDefault = false,
    styleId = "COMMON", key = null, multiLine = false, priceComp = null, addChild = null, isInProgress = null } = b
  let style = buttonStyles?[styleId]
  if (!style)
    logerr($"StyleId {styleId} doesn't exist in buttonStyles")

  let ovr = !multiLine ? { key } : { key, size = [wndWidthDefault/2-buttonsHGap*1.5, defButtonHeight] }
  let locText = utf8ToUpper(text ?? loc($"msgbox/btn_{id}"))
  let styleOvr = mergeStyles(style ?? buttonStyles.COMMON, {
    hotkeys = hotkeys
      ?? (isDefault ? [btnAUp]
        : isCancel ? [btnBEscUp]
        : null)
    ovr = addChild == null ? ovr : ovr.__merge({ children = addChild })
    childOvr = !multiLine ? {}
      : {
        size = [wndWidthDefault / 2 - buttonsHGap * 2, defButtonHeight * 0.9]
        valign = ALIGN_CENTER
      }
  })

  if (isInProgress == null) {
    function onClick() {
      removeModalWindow(wndUid)
      cb?()
    }
    return priceComp != null ? textButtonPricePurchase(locText, priceComp, onClick, styleOvr)
      : (multiLine ? textButtonMultiline : textButton)(locText, onClick, styleOvr)
  }

  let hasClicked = Watched(isInProgress.get())
  let needRemoveWnd = Computed(@() hasClicked.get() && !isInProgress.get())
  let onRemoveWnd = @(v) v ? removeModalWindow(wndUid) : null
  function onClickWithProgress() {
    if (hasClicked.get() || isInProgress.get())
      return
    cb?()
    hasClicked.set(true)
  }

  return function() {
    let inProgressStyleOvr = hasClicked.get() || isInProgress.get() ? mergeStyles(styleOvr, buttonStyles.INACTIVE) : styleOvr
    return {
      watch = [isInProgress, hasClicked]
      key = onRemoveWnd
      onAttach = @() needRemoveWnd.subscribe(onRemoveWnd)
      onDetach = @() needRemoveWnd.unsubscribe(onRemoveWnd)
      children = priceComp != null || isInProgress.get()
          ? textButtonPricePurchase(locText, hasClicked.get() || isInProgress.get() ? spinner : priceComp, onClickWithProgress, inProgressStyleOvr)
        : (multiLine ? textButtonMultiline : textButton)(locText, onClickWithProgress, inProgressStyleOvr)
    }
  }
}

let mkMsgBoxBtnsSet = @(wndUid, btnsCfg) btnsCfg.map(@(b) mkBtn(b, wndUid))

let msgBoxText = @(text, ovr = {}) {
  size = FLEX
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = 0xFFC0C0C0
  text
  colorTable = locColorTable
}.__update(fontSmall, ovr)

let mkCustomMsgBoxWnd = @(title, content, buttonsArray, ovr = {}) modalWndBg.__merge({
  size = [ buttonsArray.len() <= 2 ? wndWidthDefault : wndWidthWide, wndHeight ]
  flow = FLOW_VERTICAL
  children = [
    type(title) == "string" ? modalWndHeader(title) : title,
    {
      size = FLEX
      flow = FLOW_VERTICAL
      padding = [ 0, buttonsHGap, buttonsHGap, buttonsHGap ]
      halign = ALIGN_CENTER
      children = [
        type(content) == "string" ? msgBoxText(content) : content,
        {
          size = FLEX_H
          halign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = { size = FLEX }
          children = buttonsArray
        }
      ]
    }
  ]
},
  ovr)

let defaultBtnsCfg = freeze([ { id = "ok", styleId = "COMMON", isDefault = true } ])
function closeMsgBox(uid) {
  if (removeModalWindow(uid))
    logM($"close '{uid}'")
}

function openMsgBox(text, uid = null, title = null, buttons = defaultBtnsCfg, wndOvr = {}, modalPriority = MWP_COMMON) {
  uid = uid ?? $"msgbox_{text}"
  closeMsgBox(uid)
  logM($"open '{uid}'")
  addModalWindow(bgShaded.__merge({
    key = uid
    priority = modalPriority
    size = FLEX
    children = mkCustomMsgBoxWnd(title, text, mkMsgBoxBtnsSet(uid, buttons), wndOvr)
    onClick = EMPTY_ACTION
    animations = wndSwitchAnim
  }))
  return uid
}

register_command(@() openMsgBox("Some test message box\nwith two buttons", null, "msgbox title",
    [
      { id = "cancel", isCancel = true, cb = @() dlog("Cancel!") }   
      { id = "ok", styleId = "PRIMARY", isDefault = true, cb = @() dlog("Ok!") }   
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
  mkBtn

  wndWidthDefault
  wndHeight
}
