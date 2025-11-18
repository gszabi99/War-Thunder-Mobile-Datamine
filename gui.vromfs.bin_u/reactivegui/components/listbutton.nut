from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { selectedLineHorSolid, opacityTransition } = require("%rGui/components/selectedLine.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")

let btnH = hdpx(103)

let bgColor = 0x990C1113
let textColor = 0xFFFFFFFF

let btnGradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(selectColor, 0, 35, 15, 30, -35))

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
        vplace = ALIGN_TOP
        image = btnGradient()
        keepAspect = KEEP_ASPECT_FILL
        opacity = isActive ? 0.8
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
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick
    xmbNode = {}

    children = [
      selectedLineHorSolid(isSelected)
      btnBase(textOrCtor, stateFlags.get(), isSelected.get())
    ]
  }.__update(override)
}

return listButton