from "%globalsDarg/darg_library.nut" import *
let modalPopupWnd = require("%rGui/components/modalPopupWnd.nut")
let { btnBEsc } = require("%rGui/controlsMenu/gpActBtn.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")

let menuButtonSize = hdpx(45)
let separatorWidth = hdpx(2)

function makeMenuBtn(onClick) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    onClick = onClick
    onElemState = @(sf) stateFlags.set(sf)
    valign = ALIGN_CENTER
    size = [ menuButtonSize, menuButtonSize ]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#hud_menu.svg:{menuButtonSize}:{menuButtonSize}")
    color = stateFlags.get() & S_HOVER ? hoverColor : 0xFFFFFFFF
    sound = { click  = "menu_appear" }
    hotkeys = [["^J:Start", loc("mainmenu/menu")]]
  }
}

const WND_UID = "main_menu_header_buttons"
let close = @() modalPopupWnd.remove(WND_UID)

function closeWithCb(cb) {
  cb()
  modalPopupWnd.remove("main_menu_header_buttons")
}

function textButton(text, onClick) {
  let stateFlags = Watched(0)
  return function() {
    let sf = stateFlags.get()
    return {
      watch = stateFlags
      rendObj = ROBJ_SOLID
      size = FLEX_H
      halign = ALIGN_CENTER
      minWidth = SIZE_TO_CONTENT
      padding = hdpx(15)
      behavior = Behaviors.Button
      onClick = onClick
      sound = {
        click  = "choose"
      }
      onElemState = @(s) stateFlags.set(s)
      color = sf & S_HOVER ? Color(200, 200, 200) : Color(0, 0, 0, 0)
      children = {
        rendObj = ROBJ_TEXT
        text
      }.__update(fontSmall)
    }
  }
}

let separatorH = {
  rendObj = ROBJ_SOLID
  size = [flex(), separatorWidth]
  color = Color(50, 50, 50)
}

let separatorV = separatorH.__merge({
  size = [separatorWidth, flex()]
})

let mkButton = @(btn) (btn?.len() ?? 0) > 0
  ? textButton(btn.name, @() closeWithCb(btn.cb))
  : separatorH

let mkColumn = @(buttonsList) {
  flow = FLOW_VERTICAL
  children = buttonsList.map(mkButton)
}

let mkDropMenu = @(columnsList) {
  rendObj = ROBJ_SOLID
  color = Color(32, 34, 38, 216)
  gap = separatorV
  flow = FLOW_HORIZONTAL
  sound = { detach  = "menu_close" }
  children = columnsList.map(mkColumn)
}

let function mkDropMenuBtn(getButtons, buttonsGeneration) {
  let getColumnsList = @() getButtons().filter(@(col) col.len() > 0)
  return function() {
    let res = {
      watch = buttonsGeneration
    }
    let columnsList = getColumnsList()
    if (columnsList.len() == 0)
      return res

    if (columnsList.len() == 1 && columnsList[0].len() == 1) {
      res.children <- makeMenuBtn(columnsList[0][0].cb)
      return res
    }

    function openMenu(event) {
      let { targetRect } = event
      modalPopupWnd.add([targetRect.r, targetRect.b], {
        uid = WND_UID
        children = @() { watch = buttonsGeneration, children = mkDropMenu(getColumnsList()) }
        popupOffset = hdpx(5)
        popupHalign = ALIGN_RIGHT
        hotkeys = [[$"^J:Start | {btnBEsc}", { action = close, description = loc("Cancel") }]]
      })
    }
    res.children <- makeMenuBtn(openMenu)
    return res
  }
}

return {
  mkDropMenuBtn
}