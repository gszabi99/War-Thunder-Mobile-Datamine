from "%globalsDarg/darg_library.nut" import *
from "%darg/helpers/bitmap.nut" import mkBitmapPictureLazy
import "%rGui/components/modalPopupWnd.nut" as modalPopupWnd
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEsc
from "%rGui/style/gradients.nut" import mkGradientCtorDoubleSideX, mkGradientCtorDoubleSideY, gradTexSize
from "%rGui/style/stdColors.nut" import hoverColor, textColor


const menuButtonSize = hdpx(90)
const menuButtonIconSize = hdpx(45)
const menuButtonBorderWidth = hdpx(3)
const buttonH = hdpx(85)
const separatorWidth = hdpx(2)
const optionIconSize = hdpx(40)
const optionActiveColor = 0x80405780
const borderColor = 0xFF8F8F8F
const menuBgColor = 0xD60B0B10
const menuButtonBgActiveColor = 0x990B0B10

let btnGradientVert = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideY(0, 0xFF0B0B10, 0.5))
let lineGradientVert = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideY(0, 0x80777777, 0.25))
let lineGradientHor = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideX(0, 0x80777777, 0.25))

let isDropDownMenuOpened = Watched(false)

function makeMenuBtn(onClick, icon, iconSize) {
  let stateFlags = Watched(0)
  return @() {
    watch = [stateFlags, isDropDownMenuOpened]
    size = const [menuButtonSize, menuButtonSize]
    behavior = Behaviors.Button
    onClick = onClick
    onElemState = @(sf) stateFlags.set(sf)
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    rendObj = ROBJ_BOX
    fillColor = isDropDownMenuOpened.get() ? menuButtonBgActiveColor : null
    borderWidth = isDropDownMenuOpened.get() ? menuButtonBorderWidth : 0
    borderColor = borderColor
    children = {
      size = [iconSize, iconSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"{icon}:{iconSize}:{iconSize}:P")
      color = stateFlags.get() & S_HOVER ? hoverColor : textColor
    }
    sound = { click  = "menu_appear" }
    hotkeys = [["^J:Start", loc("mainmenu/menu")]]
  }
}

const WND_UID = "main_menu_header_buttons"
isDropDownMenuOpened.subscribe(@(v) !v ? modalPopupWnd.remove(WND_UID) : null)

let close = @() isDropDownMenuOpened.set(false)

function closeWithCb(cb) {
  cb()
  close()
}

function textButton(btn, onClick) {
  let { name, icon = null } = btn
  let stateFlags = Watched(0)
  return function() {
    let sf = stateFlags.get()
    return {
      watch = stateFlags
      size = const [FLEX, buttonH]
      minWidth = SIZE_TO_CONTENT
      padding = hdpx(15)
      rendObj = sf & S_HOVER ? ROBJ_BOX : ROBJ_IMAGE
      image = sf & S_HOVER ? null : btnGradientVert()
      fillColor = sf & S_HOVER ? optionActiveColor : null
      halign = ALIGN_LEFT
      valign = ALIGN_CENTER
      behavior = Behaviors.Button
      onClick = onClick
      sound = { click  = "choose" }
      onElemState = @(s) stateFlags.set(s)
      flow = FLOW_HORIZONTAL
      gap = hdpx(30)
      children = [
        icon != null
          ? {
              size = const [optionIconSize, optionIconSize]
              rendObj = ROBJ_IMAGE
              image = Picture($"{icon}:{optionIconSize}:{optionIconSize}:P")
              keepAspect = true
            }
          : null
        {
          rendObj = ROBJ_TEXT
          text = name
        }.__update(fontSmall)
      ]
    }
  }
}

let separator = @(ovr = {}) {
  size = const [FLEX, separatorWidth]
  rendObj = ROBJ_IMAGE
  image = lineGradientHor()
}.__update(ovr)

let mkButton = @(btn) (btn?.len() ?? 0) > 0
  ? textButton(btn, @() closeWithCb(btn.cb))
  : separator()

let mkColumn = @(buttonsList) {
  flow = FLOW_VERTICAL
  gap = separator()
  children = buttonsList.map(mkButton)
}

let mkDropMenu = @(columnsList) {
  rendObj = ROBJ_BOX
  fillColor = menuBgColor
  borderWidth = menuButtonBorderWidth
  borderColor = borderColor
  padding = menuButtonBorderWidth
  gap = separator({
    size = const [separatorWidth, FLEX]
    image = lineGradientVert()
  })
  flow = FLOW_HORIZONTAL
  sound = { detach = "menu_close" }
  children = columnsList.map(mkColumn)
}

function mkDropMenuBtn(getButtons, buttonsGeneration, icon = "ui/gameuiskin#hud_menu.svg", iconSize = menuButtonIconSize) {
  let getColumnsList = @() getButtons().filter(@(col) col.len() > 0)
  return function() {
    let res = {
      watch = buttonsGeneration
    }
    let columnsList = getColumnsList()
    if (columnsList.len() == 0)
      return res

    if (columnsList.len() == 1 && columnsList[0].len() == 1) {
      res.children <- makeMenuBtn(columnsList[0][0].cb, icon, iconSize)
      return res
    }

    function openMenu(event) {
      let { targetRect } = event
      isDropDownMenuOpened.set(true)
      modalPopupWnd.add([targetRect.r, targetRect.b], {
        uid = WND_UID
        children = @() { watch = buttonsGeneration, children = mkDropMenu(getColumnsList()) }
        popupOffset = hdpx(5)
        popupHalign = ALIGN_RIGHT
        hotkeys = [[$"^J:Start | {btnBEsc}", { action = close, description = loc("Cancel") }]]
        onDetach = close
        rendObj = null
        color = null
      })
    }
    res.children <- makeMenuBtn(openMenu, icon, iconSize)
    return res
  }
}

return {
  mkDropMenuBtn
}