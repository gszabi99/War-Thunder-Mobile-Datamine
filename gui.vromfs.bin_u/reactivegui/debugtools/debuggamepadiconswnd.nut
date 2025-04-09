from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let presets = require("%rGui/controlsMenu/gamepadImagePresets.nut")

let wndUid = "debugGamepadIconsWnd"
let wndPadding = hdpxi(30)
let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened(false)

let viewOrder = [
  "BTN_A", "BTN_A_PRESSED", "BTN_B", "BTN_B_PRESSED", "BTN_X", "BTN_X_PRESSED", "BTN_Y", "BTN_Y_PRESSED",
  "BTN_DIRPAD", "BTN_DIRPAD_DOWN", "BTN_DIRPAD_LEFT", "BTN_DIRPAD_RIGHT", "BTN_DIRPAD_UP",
  "BTN_BACK", "BTN_BACK_PRESSED", "BTN_START", "BTN_START_PRESSED",
  "BTN_LB", "BTN_LB_PRESSED", "BTN_RB", "BTN_RB_PRESSED",
  "BTN_LT", "BTN_LT_PRESSED", "BTN_RT", "BTN_RT_PRESSED",
  "BTN_LS", "BTN_LS_PRESSED", "BTN_LS_ANY",
  "BTN_LS_UP", "BTN_LS_DOWN", "BTN_LS_LEFT", "BTN_LS_RIGHT", "BTN_LS_HOR", "BTN_LS_VER",
  "BTN_RS", "BTN_RS_PRESSED", "BTN_RS_ANY",
  "BTN_RS_UP", "BTN_RS_DOWN", "BTN_RS_LEFT", "BTN_RS_RIGHT", "BTN_RS_HOR", "BTN_RS_VER",
]
let presetsOrder = ["xone", "sony", "nintendo"]
let sizes = [
  fontTiny.fontSize.tointeger() //hotkey panel
  evenPx(50)  //main buttons
  evenPx(70)
]

function mkRow(size, presetId, preset) {
  let { heightMuls, defHeightMul } = preset
  let gap = 0.3 * size
  let cols = max(1, ((saSize[0] + gap).tofloat() / (size + gap)).tointeger())
  let icons = viewOrder.map(function(id) {
    let imgSize = ((heightMuls?[id] ?? defHeightMul) * size + 0.5).tointeger()
    return {
      size = [size, size]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = {
        size = [imgSize, imgSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#{preset?[id] ?? ""}.svg:{imgSize}:{imgSize}:P")
        keepAspect = true
      }
    }
  })
  let rows = arrayByRows(icons, cols)
  let header = {
    rendObj = ROBJ_TEXT,
    text = $"{presetId} (size = {size})"
  }.__update(fontTiny)
  return {
    flow = FLOW_VERTICAL
    gap
    children = [header]
      .extend(rows.map(@(list) {
        flow = FLOW_HORIZONTAL
        gap
        children = list
      }))
  }
}

function mkContent() { //no point to create it n scripts load
  let children = []
  foreach(size in sizes)
    foreach(presetId in presetsOrder)
      if (presetId in presets)
        children.append(mkRow(size, presetId, presets[presetId]))

  return {
    size = saSize.map(@(v) v + 2 * wndPadding)
    stopMouse = true
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = 0xFF707070
    clipChildren = true
    children = {
      size = flex()
      padding = wndPadding
      flow = FLOW_VERTICAL
      gap = hdpx(30)
      behavior = Behaviors.Pannable
      touchMarginPriority = TOUCH_BACKGROUND
      scrollHandler = ScrollHandler()
      children
    }
  }
}

let openImpl = @() addModalWindow({
  key = wndUid
  size = flex()
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
  children = mkContent()
  onClick = close
})

if (isOpened.value)
  openImpl()
isOpened.subscribe(@(v) v ? openImpl() : removeModalWindow(wndUid))

register_command(@() isOpened(true), "ui.debugGamepadIcons")
