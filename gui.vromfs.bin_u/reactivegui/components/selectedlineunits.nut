from "%globalsDarg/darg_library.nut" import *

let lineColor = 0xFF7FAEFF
let lineColorPremium = 0xFFFFFFFF
let aTimeOpacity = 0.3
let selLineSize = hdpx(7)

let opacityTransition = [{ prop = AnimProp.opacity, duration = aTimeOpacity, easing = InOutQuad }]

let selectedLine = @(isActive, size, color) @() {
  watch = isActive
  size
  rendObj = ROBJ_SOLID
  color
  opacity = isActive.get() ? 1 : 0
  transitions = opacityTransition
}

let getLineColor = @(isHidden, isPremium) isHidden || isPremium ? lineColorPremium : lineColor

return {
  selectedLineHorUnits = @(isActive, isPremium = false, isHidden = false)
    selectedLine(isActive, [flex(), selLineSize], getLineColor(isHidden, isPremium))
  selectedLineVertUnits = @(isActive, isPremium = false, isHidden = false)
    selectedLine(isActive, [selLineSize, flex()], getLineColor(isHidden, isPremium))
  selectedLineHorUnitsCustomSize = @(size, isActive, isPremium = false, isHidden = false)
    selectedLine(isActive, size, getLineColor(isHidden, isPremium))
  opacityTransition
  selLineSize
}