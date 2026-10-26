from "%globalsDarg/darg_library.nut" import *
from "%darg/helpers/bitmap.nut" import mkBitmapPictureLazy
from "%rGui/components/selectedLine.nut" import selectedLineHorSolid, opacityTransition
from "%rGui/style/gradients.nut" import gradTexSize, mkGradientCtorRadial
from "%rGui/style/stdColors.nut" import selectColor, tabBgColor
from "types" import Function, Table


const btnH = hdpx(103)

const textColor = 0xFFFFFFFF

let btnGradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(selectColor, 0, 35, 15, 30, -35))

function btnBase(textOrCtor, sf, isSelected) {
  let isActive = isSelected || (sf & S_ACTIVE) != 0
  return {
    size = FLEX_H
    children = [
      {
        size = FLEX
        rendObj = ROBJ_SOLID
        color = tabBgColor
      }
      {
        size = FLEX
        rendObj = ROBJ_IMAGE
        vplace = ALIGN_TOP
        image = btnGradient()
        keepAspect = KEEP_ASPECT_FILL
        opacity = isActive ? 0.8
          : sf & S_HOVER ? 0.5
          : 0
        transitions = opacityTransition
      }
      textOrCtor instanceof Table ? textOrCtor
        : !(textOrCtor instanceof Function)
          ? {
              size = const [FLEX, btnH]
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              color = textColor
              text = textOrCtor
            }.__update(fontSmall)
        : textOrCtor.getfuncinfos().parameters.len() == 1 ? textOrCtor
        : textOrCtor(sf, isSelected)
    ]
  }
}

let mkSelectedBorder = @(isSelected) @() {
  watch = isSelected
  size = FLEX
  rendObj = ROBJ_BOX
  borderWidth = isSelected.get() ? hdpx(4) : 0
  borderColor = selectColor
}

function listButton(textOrCtor, isSelected, onClick, override = {}) {
  let stateFlags = Watched(0)
  let useBorder = override?.hasBorderSelection ?? false
  let selectedLine = useBorder ? null : selectedLineHorSolid(isSelected)
  let selectedBorder = !useBorder ? null : mkSelectedBorder(isSelected)
  return @() {
    watch = [isSelected, stateFlags]
    size = FLEX_H
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    sound = const { click = "click" }
    onClick
    xmbNode = {}

    children = [
      selectedLine
      {
        size = FLEX_H
        children = [
          btnBase(textOrCtor, stateFlags.get(), isSelected.get())
          selectedBorder
        ]
      }
    ]
  }.__update(override)
}

return listButton