from "%globalsDarg/darg_library.nut" import *
let { hoverColor, selectColor } = require("%rGui/style/stdColors.nut")

let textColor = 0xFFFFFFFF
let slotOnColor = selectColor
let slotOffColor = 0xFF000000

let knobSize = evenPx(68)
let toggleW = evenPx(180)
let toggleH = knobSize

let knobMoveTime = 0.1
let activeColorTime = 0.2
let transEasing = InOutQuad

let toggleLabel = @(text, sf, ovr = {}) {
  rendObj = ROBJ_TEXT
  color = sf & S_HOVER ? hoverColor : textColor
  text
}.__update(fontSmall, ovr)

let toggleActiveBg = @(value) {
  size = [toggleW, toggleH]
  rendObj = ROBJ_BOX
  fillColor = slotOnColor
  borderRadius = toggleH / 2
  opacity = value ? 1 : 0
  transform = { scale = value ? [1, 1] : [0, 0] }
  transitions = [
    { prop = AnimProp.scale, duration = activeColorTime, easing = transEasing }
    { prop = AnimProp.opacity, duration = activeColorTime, easing = transEasing }
  ]
}

let toggleKnob = @(value, sf) {
  size  = [knobSize, knobSize]
  rendObj = ROBJ_BOX
  borderRadius = knobSize / 2
  fillColor = textColor

  transform = {
    translate = [value ? toggleW - knobSize : 0, 0]
    scale = sf & S_ACTIVE ? [0.8, 0.8] : [1.0, 1.0]
  }
  transitions = [
    { prop = AnimProp.translate, duration = knobMoveTime, easing = transEasing }
    { prop = AnimProp.scale, duration = 0.15, easing = transEasing }
  ]
}

let toggle = @(valueW, sf) @() {
  watch = valueW
  size = [toggleW, toggleH]
  rendObj = ROBJ_BOX
  fillColor = slotOffColor
  borderRadius = toggleH / 2
  valign = ALIGN_CENTER
  children = [
    toggleActiveBg(valueW.get())
    toggleKnob(valueW.get(), sf)
  ]
}

let toggleWithLabel = @(stateFlags, valueW, children, ovr = {}) @() {
  watch = stateFlags
  behavior = Behaviors.Button
  onElemState = @(v) stateFlags.set(v)
  sound = { click  = "click" }
  onClick = @() valueW.set(!valueW.get())
  valign = ALIGN_CENTER
  gap = hdpx(30)
  children
}.__update(ovr)

function horizontalToggleWithLabel(valueW, label, textOvr = {}) {
  let stateFlags = Watched(0)
  let children = [
    toggle(valueW, stateFlags.get())
    toggleLabel(label, stateFlags.get(), textOvr)
  ]
  return toggleWithLabel(stateFlags, valueW, children, { flow = FLOW_HORIZONTAL })
}

function verticalToggleWithLabel(valueW, label, textOvr = {}) {
  let stateFlags = Watched(0)
  let children = [
    toggleLabel(label, stateFlags.get(), textOvr)
    toggle(valueW, stateFlags.get())
  ]
  return toggleWithLabel(stateFlags, valueW, children, { flow = FLOW_VERTICAL })
}

return {
  horizontalToggleWithLabel
  verticalToggleWithLabel
}