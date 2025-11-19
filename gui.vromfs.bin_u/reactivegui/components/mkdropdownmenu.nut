from "%globalsDarg/darg_library.nut" import *
let modalPopupWnd = require("%rGui/components/modalPopupWnd.nut")
let { btnBEsc } = require("%rGui/controlsMenu/gpActBtn.nut")
let { hoverColor, textColor } = require("%rGui/style/stdColors.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorDoubleSideX, mkGradientCtorDoubleSideY, gradTexSize } = require("%rGui/style/gradients.nut")


let menuButtonSize = hdpx(90)
let menuButtonIconSize = hdpx(45)
let menuButtonBorderWidth = hdpx(3)
let buttonH = hdpx(85)
let separatorWidth = hdpx(2)
let optionIconSize = hdpx(40)
let optionActiveColor = 0x80405780
let borderColor = 0xFF8F8F8F
let menuBgColor = 0xD60B0B10
let menuButtonBgActiveColor = 0x990B0B10

let btnGradientVert = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideY(0, 0xFF0B0B10, 0.5))
let lineGradientVert = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideY(0, 0x80777777, 0.25))
let lineGradientHor = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideX(0, 0x80777777, 0.25))

let isDropDownMenuOpened = Watched(false)

function makeMenuBtn(onClick, icon, iconSize) {
  let stateFlags = Watched(0)
  return @() {
    watch = [stateFlags, isDropDownMenuOpened]
    size = [menuButtonSize, menuButtonSize]
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
      image = Picture($"{icon}:{iconSize}:{iconSize}")
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
      size = [flex(), buttonH]
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
              size = [optionIconSize, optionIconSize]
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
  size = [flex(), separatorWidth]
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
    size = [separatorWidth, flex()]
    image = lineGradientVert()
  })
  flow = FLOW_HORIZONTAL
  sound = { detach = "menu_close" }
  children = columnsList.map(mkColumn)
}

let function mkDropMenuBtn(getButtons, buttonsGeneration, icon = "ui/gameuiskin#hud_menu.svg", iconSize = menuButtonIconSize) {
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