from "%globalsDarg/darg_library.nut" import *
let { startswith } = require("string")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { mkBtnImageComp } = require("%rGui/controlsMenu/gamepadImgByKey.nut")
let { btnA, clickButtons, EMPTY_ACTION } = require("%rGui/controlsMenu/gpActBtn.nut")
let { cursorPresent, cursorOverStickScroll, cursorOverClickable, hoveredClickableInfo } = gui_scene
let { isHudAttached } = require("%appGlobals/clientState/hudState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")


let font = fontTiny
let height = font.fontSize.tointeger()
let padding = hdpx(5)
let gap = hdpx(25)
let textGap = hdpx(5)

let navState = { value = [] }
let getNavState = @(_ = null) navState.value
let navStateGen = Watched(0)

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = 0xFFA0A0A0
}.__update(font)

let defaultJoyAHint = loc("ui/cursor.activate")

gui_scene.setHotkeysNavHandler(function(state) {
  navState.value = state
  navStateGen.set(navStateGen.get() + 1)
})

let btnAnimataions = [{ prop = AnimProp.opacity, from = 0, to = 1, duration = 0.15, easing = InQuad, play = true }]

function mkNavBtn(hotkey) {
  let { description = null, btnName = [] } = hotkey
  if (description == null)
    return null

  let children = btnName.map(@(name) mkBtnImageComp(name, height))
  if (description != "")
    children.append(mkText(description))

  return {
    size = [SIZE_TO_CONTENT, height]
    gap = textGap
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = children
    padding = hdpx(5)
    animations = btnAnimataions
  }
}

let isActivateKey = @(key) btnA == key.btnName
let isHotkeyVisible = @(hotkey) hotkey?.description != null && hotkey.devId == DEVID_JOYSTICK && hotkey?.action != EMPTY_ACTION

function combineHotkeys(data) {
  let hotkeys = []
  foreach (k in data) {
    if (isActivateKey(k) || !isHotkeyVisible(k))
      continue
    let t = clone k
    local isUsed = false
    foreach (r in hotkeys) {
      if (r.action == t.action) {
        r.btnName.append(t.btnName)
        isUsed = true
        break
      }
    }
    if (!isUsed) {
      t.btnName = [t.btnName]
      hotkeys.append(t)
    }
  }
  return hotkeys
}

let isPanelVisible = Computed(@() cursorPresent.get() && isGamepad.get()
  && (!isHudAttached.get() || hasModalWindows.get()))

let joyAHint = Computed(function() {
  local hotkeyAText = defaultJoyAHint
  if (!isGamepad.get())
    return hotkeyAText
  if (type(hoveredClickableInfo.get()) == "string")
    return hoveredClickableInfo.get()
  if (hoveredClickableInfo.get()?.skipDescription ?? false)
    return null

  foreach (k in getNavState(navStateGen.get()))
    if (isActivateKey(k)) {
      let { description = null } = k
      if (description == null || type(description) == "string")
        hotkeyAText = description
    }
  return hotkeyAText
})

function manualHint(images, text = "", ovr = {}) {
  let children = images.map(@(image) mkBtnImageComp(image, height))
  if (text != "")
    children.append(mkText(text))
  return {
    padding
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = textGap
    children
    animations = btnAnimataions
  }.__update(ovr)
}

let clickImageIds = clickButtons.filter(@(btn) startswith(btn, "J:"))
let minClickHintSize = calc_comp_size(manualHint(clickImageIds, defaultJoyAHint))
minClickHintSize[0] = max(minClickHintSize[0], hdpxi(250))

let cursorTips = @() {
  watch = [joyAHint, cursorOverStickScroll, cursorOverClickable]
  size = [SIZE_TO_CONTENT, height]
  flow = FLOW_HORIZONTAL
  gap
  valign = ALIGN_CENTER
  children = [
    manualHint(["J:L.Thumb.hv", "dirpad"], loc("ui/cursor.navigation"))
    cursorOverClickable.get() && joyAHint.get() ? manualHint(clickImageIds, joyAHint.get(), { minWidth = minClickHintSize[0] })
      : { size = minClickHintSize, key = {} }
    !cursorOverStickScroll.get() ? null
      : manualHint(["J:R.Thumb.hv"], loc("ui/cursor.scroll"))
  ]
}

let mainTips = @() {
  watch = [isPanelVisible, navStateGen]
  gap
  flow = FLOW_HORIZONTAL
  children = !isPanelVisible.get() ? null
    : combineHotkeys(getNavState(navStateGen.get())).map(mkNavBtn)
}

let hotkeysButtonsBar = @() !isPanelVisible.get() ? { watch = isPanelVisible }
  : {
      watch = isPanelVisible
      zOrder = Layers.Upper
      size = [flex(), saBorders[1]]
      padding = [0, saBorders[0]]
      vplace = ALIGN_BOTTOM
      flow = FLOW_HORIZONTAL
      gap = hdpx(60)
      valign = ALIGN_CENTER
      children = [
        cursorTips
        mainTips
      ]
    }

return hotkeysButtonsBar
