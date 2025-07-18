from "%globalsDarg/darg_library.nut" import *
let { playSound } = require("sound_wt")
let { lerpClamped } = require("%sqstd/math.nut")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")

let textColor = 0xFFFFFFFF
let borderColor = 0xFF9FA7AF
let sliderBgColor = 0xFF000000
let sliderFgColor = 0xFF4089B2
let sliderValueSound = @() playSound("choose")

let knobSize = evenPx(68)
let sliderH = evenPx(80)
let sliderVisibleH = evenPx(10)
let sliderW = hdpx(750)
let sliderBlockH = hdpx(160)
let sliderBtnSize = evenPx(100)
let iconSize = evenPx(34)
let sliderGap = sliderBtnSize / 2
let firstTick = 0.3
let btnRepeatTick = 0.025
let btnRepeatTime = [firstTick, 0.25, 0.2, 0.15, 0.1, 0.075, 0.05, btnRepeatTick]
let hoverColor = 0x8052C4E4
let maxValueWidth = calc_str_box("288% ", fontSmall)[0]

let transTime = 0.05
let transEasing = InOutQuad

let mkSliderKnob = @(relValue, stateFlags, fullW, ovr = {}) @() {
  watch = [relValue, stateFlags]
  size  = [knobSize, knobSize]
  hplace = ALIGN_CENTER

  rendObj = ROBJ_VECTOR_CANVAS
  commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
  color = textColor
  fillColor = textColor

  transform = {
    scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1]
    translate = [(relValue.value - 0.5) * fullW, 0]
  }
  transitions = [
    { prop = AnimProp.translate, duration = transTime, easing = transEasing }
    { prop = AnimProp.scale, duration = 0.1, easing = InOutQuad }
  ]
}.__update(ovr)

let btnBg = freeze({
  size  = [sliderBtnSize, sliderBtnSize]
  rendObj = ROBJ_VECTOR_CANVAS
  commands = [[VECTOR_POLY, 0, 50, 50, 0, 100, 50, 50, 100]]
  color = borderColor
  fillColor = 0
  lineWidth = hdpx(3)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  transitions = [{ prop = AnimProp.scale, duration = 0.1, easing = InOutQuad }]
})

function slider(valueWatch, override = {}, knobCtor = mkSliderKnob) {
  let onChange = override?.onChange
    ?? function onChange(value) {
         sliderValueSound()
         valueWatch(value)
       }

  let stateFlags = Watched(0)
  let minV = override?.min ?? 0
  let maxV = override?.max ?? 100
  let relValue = Computed(@() lerpClamped(minV, maxV, 0.0, 1.0, valueWatch.value))
  let size = override?.size ?? [sliderW, sliderH]
  let knob = knobCtor(relValue, stateFlags, size[0])

  return {
    size
    valign = ALIGN_CENTER
    children = [
      @() {
        watch = valueWatch
        size = flex()
        behavior = Behaviors.Slider
        xmbNode = {}
        onElemState = @(sf) stateFlags(sf)
        onChange
        min = 0
        max = 100
        unit = 1
        fValue = valueWatch.value
      }.__update(override)
      {
        size = [flex(), sliderVisibleH]
        rendObj = ROBJ_SOLID
        color = sliderBgColor
      }
      @() {
        watch = relValue
        size = [flex(), sliderVisibleH]
        rendObj = ROBJ_SOLID
        color = sliderFgColor

        transform = {
          pivot = [0, 0]
          scale = [relValue.value, 1]
        }
        transitions = [{ prop = AnimProp.scale, duration = transTime, easing = transEasing }]
      }
      knob
    ]
  }
}

let sliderHeader = @(text, valueTextWatch, override = {}) {
  size = FLEX_H
  valign = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    {
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = textColor
      text
    }.__update(fontSmall)
    @() {
      watch = valueTextWatch
      hplace = ALIGN_RIGHT
      halign = ALIGN_RIGHT
      rendObj = ROBJ_TEXT
      color = textColor
      minWidth = maxValueWidth
      text = valueTextWatch.value
    }.__update(fontSmall)
  ]
}.__update(override)

let mkBtnText = @(override) {
  rendObj = ROBJ_TEXT
  color = textColor
}.__update(fontBig, override)

let getIcon = @(iconName) mkBtnText({
  size = [iconSize, iconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#icon_{iconName}.svg:{iconSize}:{iconSize}:P")
  keepAspect = KEEP_ASPECT_FIT
})

let btnTextDec = getIcon("minus")
let btnTextInc = getIcon("plus")

let mkIconBtn = @(children) {
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children
}

function sliderBtn(childrenCtor, onChangeValue, bgOvrW = Watched({})) {
  let stateFlags = Watched(0)
  local holdCount = -1
  local lastTime = 0

  function onHoldTimer() {
    let delay = btnRepeatTime?[holdCount]
    if (delay != null && delay * 1000 > get_time_msec() - lastTime)
      return
    onChangeValue()
    lastTime = get_time_msec()
    holdCount++
  }

  function resetTimer() {
    holdCount = -1
    clearTimer(onHoldTimer)
  }

  let bg = btnBg.__merge({ key = {} }) 
  return @() bg.__merge(bgOvrW.value, {
    watch = [stateFlags, bgOvrW]
    behavior = Behaviors.Button
    xmbNode = {}
    function onElemState(sf) {
      stateFlags(sf)
      let isActive = !!(sf & S_ACTIVE)
      if (isActive == (holdCount >= 0))
        return

      if (isActive) {
        lastTime = get_time_msec()
        holdCount = 0
        setInterval(btnRepeatTick, onHoldTimer)
      }
      else
        resetTimer()
    }
    onClick = @() get_time_msec() - lastTime < firstTick * 1000 ? onChangeValue() : null
    onDetach = resetTimer
    children = childrenCtor(stateFlags.value)
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
  })
}

function sliderWithButtons(valueWatch, header, sliderOverride = {}, valToString = null) {
  let valueTextWatch = valToString == null ? valueWatch : Computed(@() valToString(valueWatch.value))
  let { unit = 1,
    onChange = function(v) {
      sliderValueSound()
      valueWatch(v)
    }
  } = sliderOverride
  let minV = sliderOverride?.min ?? 0
  let maxV = sliderOverride?.max ?? 100

  let mkOnClick = @(diff) function onClick() {
    let value = clamp(valueWatch.value + diff, minV, maxV)
    if (value != valueWatch.value)
      onChange(value)
  }

  return {
    minHeight = sliderBlockH
    flow = FLOW_HORIZONTAL
    gap = sliderGap
    valign = ALIGN_BOTTOM
    children = [
      sliderBtn(@(sf) mkIconBtn(sf & S_HOVER ? btnTextDec.__merge({ color = hoverColor }) : btnTextDec),
        mkOnClick(-unit))
      {
        flow = FLOW_VERTICAL
        padding = [0, 0, (sliderBtnSize - knobSize - sliderVisibleH) / 2, 0]
        children = [
          sliderHeader(header, valueTextWatch)
          slider(valueWatch, sliderOverride)
        ]
      }
      sliderBtn(@(sf) mkIconBtn(sf & S_HOVER ? btnTextInc.__merge({ color = hoverColor }) : btnTextInc),
        mkOnClick(unit))
    ]
  }
}

return {
  sliderH
  sliderBtnSize
  sliderGap

  slider
  sliderHeader
  sliderBtn
  sliderWithButtons
  sliderValueSound
  mkSliderKnob

  btnTextDec
  btnTextInc
  mkIconBtn
  btnBg
}
