from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "%sqstd/string.nut" import utf8ToUpper
import "%rGui/components/buttonStyles.nut" as buttonStyles
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow, MWP_COMMON
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeader
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/textButton.nut" import textButtonMultiline, buttonsHGap, mergeStyles, textButton,
  textButtonPricePurchase
from "%rGui/controlsMenu/gpActBtn.nut" import btnAUp, btnBEscUp, EMPTY_ACTION
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import locColorTable
from "types" import String


let logM = log_with_prefix("[MSGBOX] ")


const wndWidthDefault = hdpx(1106) 
const wndWidthWide = hdpx(1500) 
const wndHeight = hdpx(652)
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
    title instanceof String ? modalWndHeader(title) : title,
    {
      size = FLEX
      flow = FLOW_VERTICAL
      padding = [ 0, buttonsHGap, buttonsHGap, buttonsHGap ]
      halign = ALIGN_CENTER
      children = [
        content instanceof String ? msgBoxText(content) : content,
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

const defaultBtnsCfg = [ { id = "ok", styleId = "COMMON", isDefault = true } ]
function closeMsgBox(uid) {
  if (removeModalWindow(uid))
    logM($"close '{uid}'")
}

function openMsgBox(text, uid = null, title = null, buttons = defaultBtnsCfg, wndOvr = {}, modalPriority = MWP_COMMON, onBgClick = null) {
  uid = uid ?? $"msgbox_{text}"
  closeMsgBox(uid)
  logM($"open '{uid}'")
  addModalWindow(bgShaded.__merge({
    key = uid
    priority = modalPriority
    size = FLEX
    children = mkCustomMsgBoxWnd(title, text, mkMsgBoxBtnsSet(uid, buttons), wndOvr)
    onClick = onBgClick ?? EMPTY_ACTION
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
