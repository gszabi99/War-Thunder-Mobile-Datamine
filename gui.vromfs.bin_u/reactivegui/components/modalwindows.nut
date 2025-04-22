from "%globalsDarg/darg_library.nut" import *
let logM = log_with_prefix("[ModalWnd] ")
let { register_command } = require("console")
let { EMPTY_ACTION, btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")

let MWP_COMMON = 0
let MWP_ALWAYS_TOP = 1000

let WND_PARAMS = {
  key = null 
  children = null
  onClick = null 
  priority = MWP_COMMON

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
let hideModalsIds = Watched({})
let modalWindowsGeneration = Watched(0)
let hasModalWindows = Computed(@() modalWindowsGeneration.get() >= 0 && modalWindows.len() > 0)
let isModalsHidden = Computed(@() hideModalsIds.get().len() > 0)

function appendModal(wnd) {
  if ((modalWindows?[modalWindows.len() - 1].priority ?? MWP_COMMON) <= wnd.priority) {
    modalWindows.append(wnd)
    return
  }
  for (local i = modalWindows.len() - 2; i >= 0; i--)
    if (modalWindows[i].priority <= wnd.priority) {
      modalWindows.insert(i + 1, wnd)
      return
    }
  modalWindows.insert(0, wnd)
}

function moveModalToTop(key) {
  let idx = modalWindows.findindex(@(m) m.key == key)
  if (idx == null)
    return false
  appendModal(modalWindows.remove(idx))
  modalWindowsGeneration.set(modalWindowsGeneration.get() + 1)
  return true
}

function removeModalWindow(key) {
  let idx = modalWindows.findindex(@(w) w.key == key)
  if (idx == null)
    return false
  modalWindows.remove(idx)
  modalWindowsGeneration.set(modalWindowsGeneration.get() + 1)
  logM("Remove window ", key)
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
  logM("Open window ", wnd.key)
  wnd.onClick = wnd.onClick ?? @() removeModalWindow(wnd.key)
  if (wnd.onClick == EMPTY_ACTION)
    wnd.behavior = null
  appendModal(wnd)
  modalWindowsGeneration.set(modalWindowsGeneration.get() + 1)
}

let addModalWindowWithHeader = @(key, title, content) addModalWindow(bgShaded.__merge({
  key = key
  size = flex()
  children = modalWndBg.__merge({
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      modalWndHeaderWithClose(
        title,
        @() removeModalWindow(key),
        {
          minWidth = SIZE_TO_CONTENT,
          padding = [0, hdpx(10)]
        })
      content
    ]
  })
  animations = wndSwitchAnim
}))

function closeAllModalWindows() {
  if (modalWindows.len() == 0)
    return
  logM("CloseAllModals ", modalWindows.len())
  modalWindows.clear()
  modalWindowsGeneration.set(modalWindowsGeneration.get() + 1)
}

function hideModals(id) {
  if (id in hideModalsIds.get())
    return
  logM("Hide modals ", id)
  hideModalsIds.mutate(@(v) v.$rawset(id, true))
}

function unhideModals(id) {
  if (id not in hideModalsIds.get())
    return
  logM("Unhide modals ", id)
  hideModalsIds.mutate(@(v) v.$rawdelete(id))
}

let modalWindowsComponent = @() {
  watch = [modalWindowsGeneration, isModalsHidden]
  size = flex()
  children = isModalsHidden.get() ? null : modalWindows
}

function printOpenedModalWindows(mws = null) {
  if (mws == null || mws.len() == 0)
    return console_print("Empty") 
  foreach (mw in mws.map(@(v) v.key))
    console_print(mw) 
}

register_command(@() printOpenedModalWindows(modalWindows), "debug.print_opened_modal_windows")
register_command(@() closeAllModalWindows(), "debug.close_all_modal_windows")
register_command(@(key) removeModalWindow(key), "debug.close_modal_window")

return {
  addModalWindow
  addModalWindowWithHeader
  removeModalWindow
  closeAllModalWindows
  modalWindowsComponent
  hasModalWindows
  moveModalToTop
  hideModals
  unhideModals

  MWP_ALWAYS_TOP
  MWP_COMMON
}
