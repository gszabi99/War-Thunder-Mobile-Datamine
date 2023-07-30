from "%globalsDarg/darg_library.nut" import *
let { mkLinearGradientImg, mkRadialGradientImg } = require("%darg/helpers/mkGradientImg.nut")

let btnH = hdpx(103)
let gap = hdpx(10)
let selLineH = hdpx(5).tointeger()

let bgColor = 0x80000000
let activeBgColor = 0x8052C4E4
let textColor = 0xFFFFFFFF
let transDuration = 0.3

let opacityTransition = [{ prop = AnimProp.opacity, duration = transDuration, easing = InOutQuad }]


let lineTexW = hdpx(150)
let lineTexOfs = (0.5 * lineTexW).tointeger() - 2
let lineGradient = mkLinearGradientImg({
  points = [
    { offset = 0, color = colorArr(0) },
    { offset = 45, color = colorArr(activeBgColor) },
    { offset = 55, color = colorArr(activeBgColor) },
    { offset = 100, color = colorArr(0) }
  ]
  width = lineTexW
  height = 4
  x1 = 0
  y1 = 0
  x2 = lineTexW
  y2 = 0
})

let btnGradient = mkRadialGradientImg({
  points = [{ offset = 0, color = colorArr(activeBgColor) }, { offset = 100, color = colorArr(bgColor) }]
  width = 2 * btnH
  height = btnH
  cx = btnH
  cy = btnH
  r = 1.5 * btnH
})

let btnLine = @(isActive) {
  size = [flex(), selLineH]
  rendObj = ROBJ_9RECT
  image = lineGradient
  texOffs = [0, lineTexOfs]
  screenOffs = [0, lineTexOfs]
  opacity = isActive ? 1 : 0
  transitions = opacityTransition
}

let function btnBase(textOrCtor, sf, isSelected) {
  let isActive = isSelected || (sf & S_ACTIVE) != 0
  return {
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      {
        size = flex()
        rendObj = ROBJ_SOLID
        color = bgColor
        opacity = isActive ? 0 : 1
        transitions = opacityTransition
      }
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = btnGradient
        opacity = isActive ? 1
          : sf & S_HOVER ? 0.75
          : 0
        transitions = opacityTransition
      }
      type(textOrCtor) == "function" ? textOrCtor(sf, isSelected)
        : {
            size = [flex(), btnH]
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            rendObj = ROBJ_TEXT
            color = textColor
            text = textOrCtor
          }.__update(fontSmall)
    ]
  }
}

let function listButton(textOrCtor, isSelected, onClick, override = {}) {
  let stateFlags = Watched(0)
  return @() {
    watch = [isSelected, stateFlags]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick

    children = [
      btnBase(textOrCtor, stateFlags.value, isSelected.value)
      btnLine(isSelected.value || (stateFlags.value & S_ACTIVE) != 0)
    ]
  }.__update(override)
}

return listButton