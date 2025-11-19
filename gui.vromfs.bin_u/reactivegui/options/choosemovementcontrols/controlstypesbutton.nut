from "%globalsDarg/darg_library.nut" import *

let bgColor = 0xC0313843
let selBorderColor = 0xFFFFFFFF
let hovBorderColor = 0xFF666666
let selBorderWidth = hdpx(4)

function btnBase(content, sf, isSelected) {
  let isActive = isSelected || (sf & S_ACTIVE) != 0
  let isHovered = (sf & S_HOVER) != 0
  return {
    size = FLEX_H
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
    size = FLEX_H
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick
    children = btnBase(content, stateFlags.get(), isSelectedW.get())
  }
}

return controlsTypesButton
