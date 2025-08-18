from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorDoubleSideX, gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")

let btnH = hdpx(103)
let gap = hdpx(10)
let selLineH = hdpx(5).tointeger()

let bgColor = 0x990C1113
let activeBgColor = 0xFF52C4E4
let lineColor = 0xFF75D0E7
let textColor = 0xFFFFFFFF
let transDuration = 0.3

let opacityTransition = [{ prop = AnimProp.opacity, duration = transDuration, easing = InOutQuad }]

let lineGradient = mkBitmapPictureLazy(gradTexSize, 4, mkGradientCtorDoubleSideX(0, lineColor))
let btnGradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(activeBgColor, 0, gradTexSize / 8, gradTexSize * 4 / 8, gradTexSize / 2, gradTexSize / 4))

let btnLine = @(isActive) {
  size = [flex(), selLineH]
  rendObj = ROBJ_9RECT
  image = lineGradient()
  texOffs = [0, 0.45 * gradTexSize]
  screenOffs = [0, hdpx(50)]
  opacity = isActive ? 1 : 0
  transitions = opacityTransition
}

function btnBase(textOrCtor, sf, isSelected) {
  let isActive = isSelected || (sf & S_ACTIVE) != 0
  return {
    size = FLEX_H
    children = [
      {
        size = flex()
        rendObj = ROBJ_SOLID
        color = bgColor
      }
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = btnGradient()
        keepAspect = KEEP_ASPECT_FILL
        opacity = isActive ? 1
          : sf & S_HOVER ? 0.5
          : 0
        transitions = opacityTransition
      }
      type(textOrCtor) == "function" ? textOrCtor(sf, isSelected)
        : {
            size = [flex(), btnH]
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            color = textColor
            text = textOrCtor
          }.__update(fontSmall)
    ]
  }
}

function listButton(textOrCtor, isSelected, onClick, override = {}) {
  let stateFlags = Watched(0)
  return @() {
    watch = [isSelected, stateFlags]
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick
    xmbNode = {}

    children = [
      btnBase(textOrCtor, stateFlags.get(), isSelected.value)
      btnLine(isSelected.value || (stateFlags.get() & S_ACTIVE) != 0)
    ]
  }.__update(override)
}

return listButton