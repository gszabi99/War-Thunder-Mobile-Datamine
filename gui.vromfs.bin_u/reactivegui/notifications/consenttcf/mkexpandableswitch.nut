from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/stdColors.nut" import selectColor

let textColor = 0xFFFFFFFF
let slotOnColor = selectColor
let slotOffColor = 0xFF000000

let toEvenInt = @(v) (v / 2.0 + 0.5).tointeger() * 2

let fontDefault = fontTiny
let textH = fontDefault.fontSize
let switchH = toEvenInt(textH * 2.0)
let switchW = toEvenInt(switchH * 2.4)
let knobSize = switchH
let headerHorGap = textH
let arrowSize = [switchH, toEvenInt(switchH / 40.0 * 24)]
let arrowCollapsedShiftX = (arrowSize[0] - arrowSize[1]) / 2
let expandBtnGap = headerHorGap - arrowCollapsedShiftX
let expandableHeaderMinH = switchH
let expandableContentLPad = arrowSize[0] + expandBtnGap

let knobMoveTime = 0.1
let activeColorTime = 0.2
let expandTime = 0.15
let transEasing = InOutQuad

let mkLabel = @(text) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(fontDefault)

let switchActiveBg = @(val) {
  size = [switchW, switchH]
  rendObj = ROBJ_BOX
  fillColor = slotOnColor
  borderRadius = switchH / 2
  opacity = val ? 1 : 0
  transform = { scale = val ? [1, 1] : [0, 0] }
  transitions = [
    { prop = AnimProp.scale, duration = activeColorTime, easing = transEasing }
    { prop = AnimProp.opacity, duration = activeColorTime, easing = transEasing }
  ]
}

let switchKnob = @(val, sf) {
  size  = [knobSize, knobSize]
  rendObj = ROBJ_BOX
  borderRadius = knobSize / 2
  fillColor = textColor
  transform = {
    translate = [val ? switchW - knobSize : 0, 0]
    scale = sf & S_ACTIVE ? [0.8, 0.8] : [1.0, 1.0]
  }
  transitions = [
    { prop = AnimProp.translate, duration = knobMoveTime, easing = transEasing }
    { prop = AnimProp.scale, duration = 0.15, easing = transEasing }
  ]
}

function mkSwitchComp(isAvailableW, valueW, onManualSwitch = null) {
  let stateFlags = Watched(0)
  return @() {
    watch = [stateFlags, isAvailableW, valueW]
    size = [switchW, switchH]

    behavior = !isAvailableW.get() ? null : Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    sound = { click  = "click" }
    onClick = !isAvailableW.get() ? null : function() {
      let val = !valueW.get()
      valueW.set(val)
      onManualSwitch?(val)
    }

    rendObj = ROBJ_BOX
    fillColor = slotOffColor
    opacity = isAvailableW.get() ? 1 : 0.2
    borderRadius = switchH / 2
    valign = ALIGN_CENTER
    children = [
      switchActiveBg(valueW.get())
      switchKnob(valueW.get(), stateFlags.get())
    ]
  }
}

let mkExpandArrowImg = @(isExpanded) @() {
  watch = isExpanded,
  size = arrowSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#scroll_arrow.svg:{arrowSize[0]}:{arrowSize[1]}:P")
  keepAspect = true
  color = 0xFFFFFFFF
  transform = {
    rotate = isExpanded.get() ? 0 : -90
    translate = isExpanded.get() ? [0, 0] : [-arrowCollapsedShiftX, 0]
  }
  transitions = [
    { prop = AnimProp.rotate, from = 0, to = -90, duration = expandTime }
    { prop = AnimProp.translate, from = [0, 0], to = [-arrowCollapsedShiftX, 0], duration = expandTime }
  ]
}

function mkExpandableLabel(text, isExpanded) {
  let stateFlags = Watched(0)
  return @() {
    watch = [stateFlags, isExpanded]
    size = FLEX_H
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = expandBtnGap

    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    sound = { click  = "click" }
    onClick = @() isExpanded.set(!isExpanded.get())

    children = [
      mkExpandArrowImg(isExpanded)
      mkLabel(text)
    ]
  }
}

function mkExpandableSwitch(text, isAvailableW = null, valueW = null, onManualSwitch = null, isExpandedW = null, mkExpandedContent = null) {
  let isSwitchable = valueW != null
  let isExpandable = mkExpandedContent != null
  let isExpanded = isExpandedW ?? Watched(false)

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = [
      {
        size = FLEX_H
        minHeight = expandableHeaderMinH
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = headerHorGap
        children = [
          !isExpandable ? mkLabel(text) : mkExpandableLabel(text, isExpanded)
          !isSwitchable ? null : mkSwitchComp(isAvailableW ?? Watched(true), valueW, onManualSwitch)
        ]
      }
      !isExpandable ? null : @() {
        watch = isExpanded
        size = FLEX_H
        padding = [0, 0, 0, expandableContentLPad]
        opacity = isExpanded.get() ? 1 : 0
        transform = { translate = [0, isExpanded.get() ? 0 : -textH] }
        transitions = [
          { prop = AnimProp.translate, duration = expandTime }
          { prop = AnimProp.opacity, duration = expandTime }
        ]
        clipChildren = true
        flow = FLOW_VERTICAL
        children = isExpanded.get() ? mkExpandedContent() : null
      }
    ]
  }
}

return {
  mkExpandableSwitch
  mkExpandable = @(text, isExpandedW, mkExpandedContent) mkExpandableSwitch(text, null, null, null, isExpandedW, mkExpandedContent)
  mkSwitch = @(text, isAvailableW, valueW, onManualSwitch = null) mkExpandableSwitch(text, isAvailableW, valueW, onManualSwitch, null, null)
}
