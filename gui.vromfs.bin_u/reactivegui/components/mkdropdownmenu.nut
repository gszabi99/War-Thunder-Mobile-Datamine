from "%globalsDarg/darg_library.nut" import *
let modalPopupWnd = require("%rGui/components/modalPopupWnd.nut")
let { btnB } = require("%rGui/controlsMenu/gpActBtn.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")

let menuButtonSize = hdpx(60)

let function makeMenuBtn(onClick) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    onClick = onClick
    onElemState = @(sf) stateFlags(sf)
    valign = ALIGN_CENTER
    size = [ menuButtonSize, menuButtonSize ]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#hud_menu.svg:{menuButtonSize}:{menuButtonSize}")
    color = stateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
    sound = { click  = "menu_appear" }
    hotkeys = [["^J:Start", loc("mainmenu/menu")]]
  }
}

const WND_UID = "main_menu_header_buttons"
let close = @() modalPopupWnd.remove(WND_UID)

let function closeWithCb(cb) {
  cb()
  modalPopupWnd.remove("main_menu_header_buttons")
}

let function textButton(text, onClick) {
  let stateFlags = Watched(0)
  return function() {
    let sf = stateFlags.value
    return {
      watch = stateFlags
      rendObj = ROBJ_SOLID
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      minWidth = SIZE_TO_CONTENT
      padding = hdpx(15)
      behavior = Behaviors.Button
      onClick = onClick
      sound = {
        click  = "choose"
      }
      onElemState = @(s) stateFlags(s)
      color = sf & S_HOVER ? Color(200, 200, 200) : Color(0, 0, 0, 0)
      children = {
        rendObj = ROBJ_TEXT
        text
      }.__update(fontSmall)
    }
  }
}

let mkButton = @(btn) (btn?.len() ?? 0) > 0
  ? textButton(btn.name, @() closeWithCb(btn.cb))
  : {
      rendObj = ROBJ_SOLID
      size = [flex(), hdpx(1)]
      color = Color(50, 50, 50)
    }

let mkDropMenu = @(buttonsList) {
  rendObj = ROBJ_SOLID
  color = Color(32, 34, 38, 216)
  flow = FLOW_VERTICAL
  children = buttonsList.map(mkButton)
}

let mkDropMenuBtn = @(getButtons, buttonsGeneration) function() {
  let res = {
    watch = buttonsGeneration
  }
  let buttonsList = getButtons()
  if (buttonsList.len() == 0)
    return res

  if (buttonsList.len() == 1) {
    res.children <- makeMenuBtn(buttonsList[0].cb)
    return res
  }

  let menuUi = mkDropMenu(buttonsList)
  let function openMenu(event) {
    let { targetRect } = event
    modalPopupWnd.add([targetRect.r, targetRect.b], {
      uid = WND_UID
      children = menuUi
      popupOffset = hdpx(5)
      popupHalign = ALIGN_RIGHT
      hotkeys = [[$"^J:Start | {btnB} | Esc", { action = close, description = loc("Cancel") }]]
    })
  }
  res.children <- makeMenuBtn(openMenu)
  return res
}

return {
  mkDropMenuBtn
}