from "%globalsDarg/darg_library.nut" import *
let { hoverColor, selectColor } = require("%rGui/style/stdColors.nut")

let textColor = 0xFFFFFFFF
let slotOnColor = selectColor
let slotOffColor = 0xFF000000
let primaryAccentColor = 0xE5818080
let secondaryAccentColor = 0xCC668BCC
let knobIconColor = 0xFF464646
let iconToggleBorderColor = 0xFFDADADA
let checkBorderWidth = hdpx(4)

let knobSize = evenPx(68)
let toggleW = evenPx(180)
let toggleH = knobSize

let knobMoveTime = 0.1
let activeColorTime = 0.2
let transEasing = InOutQuad

let checkIconPath = "ui/gameuiskin#voicemsg_yes.svg"

let primaryIconToggleStyle = {
  activeBgFillColor = textColor
  activeBgBorderWidth = checkBorderWidth
  activeBgBorderColor = primaryAccentColor
  knobActiveBorderColor = primaryAccentColor
  checkmarkColor = primaryAccentColor
}

let secondaryIconToggleStyle = {
  activeBgFillColor = secondaryAccentColor
  activeBgBorderWidth = null
  activeBgBorderColor = null
  knobActiveBorderColor = secondaryAccentColor
  checkmarkColor = null
}

let mkIconToggleSizes = @(sizeY) {
  tW = (sizeY * 2 + 0.5).tointeger()
  tH = sizeY
  knobSize = (sizeY - checkBorderWidth * 2).tointeger()
  knobIconSz = (sizeY * 0.6 + 0.5).tointeger()
  checkIconSz = (sizeY * 0.6 + 0.5).tointeger()
}

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

let mkToggleKnobWithIcon = @(value, sf, icon, sizes, style) {
  size = sizes.knobSize
  rendObj = ROBJ_BOX
  borderRadius = sizes.knobSize / 2
  borderColor = value ? style.knobActiveBorderColor : primaryAccentColor
  borderWidth = checkBorderWidth
  fillColor = textColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_IMAGE
    size = sizes.knobIconSz
    color = knobIconColor
    image = Picture($"{icon}:{sizes.knobIconSz}:{sizes.knobIconSz}:P")
    keepAspect = KEEP_ASPECT_FIT
  }
  transform = {
    translate = [value ? sizes.tW - sizes.tH : 0, 0]
    scale = sf & S_ACTIVE ? [0.8, 0.8] : [1.0, 1.0]
  }
  transitions = [
    { prop = AnimProp.translate, duration = knobMoveTime, easing = transEasing }
    { prop = AnimProp.scale, duration = 0.15, easing = transEasing }
  ]
}

let mkToggleCheckmark = @(value, sizes, style) {
  size = [sizes.tW - sizes.tH, sizes.tH]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_IMAGE
    size = sizes.checkIconSz
    color = style.checkmarkColor
    image = Picture($"{checkIconPath}:{sizes.checkIconSz}:{sizes.checkIconSz}:P")
    keepAspect = KEEP_ASPECT_FIT
    opacity = value ? 1.0 : 0.0
    transitions = [{ prop = AnimProp.opacity, duration = activeColorTime, easing = transEasing }]
  }
}

let mkToggleActiveBgScaled = @(value, sizes, style) {
  size = flex()
  rendObj = ROBJ_BOX
  fillColor = style.activeBgFillColor
  borderColor = style.activeBgBorderColor
  borderWidth = style.activeBgBorderWidth
  borderRadius = sizes.tH / 2
  opacity = value ? 1 : 0
  transform = { scale = value ? [1, 1] : [0, 0] }
  transitions = [
    { prop = AnimProp.scale, duration = activeColorTime, easing = transEasing }
    { prop = AnimProp.opacity, duration = activeColorTime, easing = transEasing }
  ]
}

function iconToggle(valueW, sf, icon, sizeY = knobSize, style = primaryIconToggleStyle) {
  let sizes = mkIconToggleSizes(sizeY)
  return @() {
    watch = valueW
    size = [sizes.tW, sizes.tH]
    rendObj = ROBJ_BOX
    borderColor = iconToggleBorderColor
    borderWidth = checkBorderWidth
    padding = checkBorderWidth
    fillColor = valueW.get() ? null : primaryAccentColor
    borderRadius = sizes.tH / 2
    valign = ALIGN_CENTER
    children = [
      mkToggleActiveBgScaled(valueW.get(), sizes, style)
      mkToggleCheckmark(valueW.get(), sizes, style)
      mkToggleKnobWithIcon(valueW.get(), sf, icon, sizes, style)
    ]
  }
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
  toggle
  toggleLabel
  toggleWithLabel

  horizontalToggleWithLabel
  verticalToggleWithLabel

  primaryIconToggle = @(valueW, sf, icon, sizeY = knobSize) iconToggle(valueW, sf, icon, sizeY, primaryIconToggleStyle)
  secondaryIconToggle = @(valueW, sf, icon, sizeY = knobSize) iconToggle(valueW, sf, icon, sizeY, secondaryIconToggleStyle)
  iconToggle
}