from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/stdColors.nut" import selectColor


const lineColorPremium = 0xFFFFFFFF
const aTimeOpacity = 0.3
const selLineSize = hdpx(6)

let opacityTransition = [{ prop = AnimProp.opacity, duration = aTimeOpacity, easing = InOutQuad }]

let selectedLine = @(isActive, size, color, ovr) @() {
  watch = isActive
  size
  rendObj = ROBJ_SOLID
  color
  opacity = isActive.get() ? 1 : 0
  transitions = opacityTransition
}.__update(ovr)

let getLineColor = @(isHidden, isPremium) isHidden || isPremium ? lineColorPremium : selectColor

return {
  selectedLineHorUnits = @(isActive, isPremium = false, isHidden = false, ovr = {})
    selectedLine(isActive, [FLEX, selLineSize], getLineColor(isHidden, isPremium), ovr)
  selectedLineUnitsCustomSize = @(size, isActive, isPremium = false, isHidden = false, ovr = {})
    selectedLine(isActive, size, getLineColor(isHidden, isPremium), ovr)
  opacityTransition
  selLineSize
}