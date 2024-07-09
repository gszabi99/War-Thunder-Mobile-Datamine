from "%globalsDarg/darg_library.nut" import *

let lineColor = 0xFF7FAEFF
let lineColorPremium = 0xFFFFD45E
let aTimeOpacity = 0.3
let selLineSize = hdpx(7)
let lineColorHidden = 0xFFFDD7FF

let opacityTransition = [{ prop = AnimProp.opacity, duration = aTimeOpacity, easing = InOutQuad }]

let selectedLine = @(isActive, size, color) @() {
  watch = isActive
  size
  rendObj = ROBJ_SOLID
  color
  opacity = isActive.get() ? 1 : 0
  transitions = opacityTransition
}

let function getLineImageV(isHidden, isPremium){
  if(isHidden)
    return lineColorHidden
  else if(isPremium)
    return lineColorPremium
  return lineColor
}

let function getLineImageH(isHidden, isPremium){
  if(isHidden)
    return lineColorHidden
  else if(isPremium)
    return lineColorPremium
  return lineColor
}

return {
  selectedLineHorUnits = @(isActive, isPremium = false, isHidden = false)
    selectedLine(isActive, [flex(), selLineSize], getLineImageH(isHidden, isPremium))
  selectedLineVertUnits = @(isActive, isPremium = false, isHidden = false)
    selectedLine(isActive, [selLineSize, flex()], getLineImageV(isHidden, isPremium))
  selectedLineHorUnitsCustomSize = @(size, isActive, isPremium = false, isHidden = false)
    selectedLine(isActive, size, getLineImageH(isHidden, isPremium))
  opacityTransition
  selLineSize
}