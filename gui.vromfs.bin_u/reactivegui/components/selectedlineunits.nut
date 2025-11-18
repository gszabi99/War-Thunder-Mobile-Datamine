from "%globalsDarg/darg_library.nut" import *
let { selectColor } = require("%rGui/style/stdColors.nut")

let lineColorPremium = 0xFFFFFFFF
let aTimeOpacity = 0.3
let selLineSize = hdpx(6)

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
    selectedLine(isActive, [flex(), selLineSize], getLineColor(isHidden, isPremium), ovr)
  selectedLineVertUnits = @(isActive, isPremium = false, isHidden = false, ovr = {})
    selectedLine(isActive, [selLineSize, flex()], getLineColor(isHidden, isPremium), ovr)
  selectedLineUnitsCustomSize = @(size, isActive, isPremium = false, isHidden = false, ovr = {})
    selectedLine(isActive, size, getLineColor(isHidden, isPremium), ovr)
  opacityTransition
  selLineSize
}