from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorDoubleSideX, mkGradientCtorDoubleSideY, gradTexSize } = require("%rGui/style/gradients.nut")


let lineColor = 0xFF75D0E7
let lineColorPremium = 0x50C89123
let aTimeOpacity = 0.3
let selLineSize = hdpx(7)
let lineColorHidden = 0x80290740

let lineGradientHor = mkBitmapPictureLazy(gradTexSize, 4, mkGradientCtorDoubleSideX(0, lineColor))
let lineGradientHorPremium = mkBitmapPictureLazy(gradTexSize, 4, mkGradientCtorDoubleSideX(0, lineColorPremium))
let lineGradientHorHidden= mkBitmapPictureLazy(gradTexSize, 4, mkGradientCtorDoubleSideX(0, lineColorHidden))

let lineGradientVert = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideY(0, lineColor, 0.25))
let lineGradientVertPremium = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideY(0, lineColorPremium, 0.25))
let lineGradientVertHidden = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideY(0, lineColorHidden, 0.25))

let opacityTransition = [{ prop = AnimProp.opacity, duration = aTimeOpacity, easing = InOutQuad }]

let selectedLine = @(isActive, size, image) @() {
  watch = isActive
  size
  rendObj = ROBJ_IMAGE
  image
  opacity = isActive.get() ? 1 : 0
  transitions = opacityTransition
}

let function getLineImageV(isHidden, isPremium){
  if(isHidden)
    return lineGradientVertHidden()
  else if(isPremium)
    return lineGradientVertPremium()
  return lineGradientVert()
}

let function getLineImageH(isHidden, isPremium){
  if(isHidden)
    return lineGradientHorHidden()
  else if(isPremium)
    return lineGradientHorPremium()
  return lineGradientHor()
}

return {
  selectedLineHor = @(isActive, isPremium = false, isHidden = false)
    selectedLine(isActive, [flex(), selLineSize], getLineImageH(isHidden, isPremium))
  selectedLineVert = @(isActive, isPremium = false, isHidden = false)
    selectedLine(isActive, [selLineSize, flex()], getLineImageV(isHidden, isPremium))
  opacityTransition
  selLineSize
}