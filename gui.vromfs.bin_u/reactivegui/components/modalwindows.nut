from "%globalsDarg/darg_library.nut" import *
let { EMPTY_ACTION, btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")

let WND_PARAMS = {
  key = null //generate automatically when not set
  children = null
  onClick = null //remove current modal window when not set

  size = flex()
  behavior = Behaviors.Button
  stopMouse = true
  stopHotkeys = true
  clickableInfo = loc("mainmenu/btnClose")
  hotkeys = [[btnBEscUp, loc("mainmenu/btnClose")]]
  animations = [
    { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.15, play = true, easing = OutCubic }
    { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.125, playFadeOut = true, easing = OutCubic }
  ]
}

let modalWindows = []
let modalWindowsGeneration = Watched(0)
let hasModalWindows = Computed(@() modalWindowsGeneration.get() >= 0 && modalWindows.len() > 0)

function moveModalToTop(key) {
  let idx = modalWindows.findindex(@(m) m.key == key)
  if (idx == null)
    return false
  modalWindows.append(modalWindows.remove(idx))
  modalWindowsGeneration.set(modalWindowsGeneration.get() + 1)
  return true
}

function removeModalWindow(key) {
  let idx = modalWindows.findindex(@(w) w.key == key)
  if (idx == null)
    return false
  modalWindows.remove(idx)
  modalWindowsGeneration.set(modalWindowsGeneration.get() + 1)
  return true
}

local lastWndIdx = 0
function addModalWindow(wnd = {}) {
  wnd = WND_PARAMS.__merge(wnd)
  if (wnd.key != null)
    removeModalWindow(wnd.key)
  else {
    lastWndIdx++
    wnd.key = $"modal_wnd_{lastWndIdx}"
  }
  wnd.onClick = wnd.onClick ?? @() removeModalWindow(wnd.key)
  if (wnd.onClick == EMPTY_ACTION)
    wnd.behavior = null
  modalWindows.append(wnd)
  modalWindowsGeneration.set(modalWindowsGeneration.get() + 1)
}

function hideAllModalWindows() {
  if (modalWindows.len() == 0)
    return
  modalWindows.clear()
  modalWindowsGeneration.set(modalWindowsGeneration.get() + 1)
}

let modalWindowsComponent = @() {
  watch = modalWindowsGeneration
  size = flex()
  children = modalWindows
}

return {
  addModalWindow
  removeModalWindow
  hideAllModalWindows
  modalWindowsComponent
  hasModalWindows
  moveModalToTop
}
