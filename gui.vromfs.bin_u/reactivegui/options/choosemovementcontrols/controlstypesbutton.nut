from "%globalsDarg/darg_library.nut" import *

let bgColor = 0xC0262B33
let selBorderColor = 0xFFFFFFFF
let hovBorderColor = 0xFF666666
let selBorderWidth = hdpx(4)

function btnBase(content, sf, isSelected) {
  let isActive = isSelected || (sf & S_ACTIVE) != 0
  let isHovered = (sf & S_HOVER) != 0
  return {
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      {
        size = flex()
        rendObj = ROBJ_SOLID
        color = bgColor
      }
      content
      !(isActive || isHovered) ? null : {
        size = flex()
        rendObj = ROBJ_FRAME
        borderWidth = selBorderWidth
        color = isActive ? selBorderColor : hovBorderColor
      }
    ]
  }
}

function controlsTypesButton(content, isSelectedW, onClick) {
  let stateFlags = Watched(0)
  return @() {
    watch = [isSelectedW, stateFlags]
    size = [flex(), SIZE_TO_CONTENT]
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick
    children = btnBase(content, stateFlags.value, isSelectedW.value)
  }
}

return controlsTypesButton
