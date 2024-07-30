from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorDoubleSideX, mkGradientCtorDoubleSideY, gradTexSize } = require("%rGui/style/gradients.nut")

let lineColor = 0xFF75D0E7
let aTimeOpacity = 0.3
let selLineSize = hdpx(7)

let lineGradientHor = mkBitmapPictureLazy(gradTexSize, 4, mkGradientCtorDoubleSideX(0, lineColor))
let lineGradientVert = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideY(0, lineColor, 0.25))

let opacityTransition = [{ prop = AnimProp.opacity, duration = aTimeOpacity, easing = InOutQuad }]

let selectedLine = @(isActive, size, image) @() {
  watch = isActive
  size
  rendObj = ROBJ_IMAGE
  image
  opacity = isActive.get() ? 1 : 0
}

let selectedLineSolid = @(isActive, size) @() {
  watch = isActive
  size
  rendObj = ROBJ_SOLID
  color = lineColor
  opacity = isActive.get() ? 1 : 0
  transitions = opacityTransition
}

return {
  selectedLineHor = @(isActive)
    selectedLine(isActive, [flex(), selLineSize], lineGradientHor())
  selectedLineVert = @(isActive)
    selectedLine(isActive, [selLineSize, flex()], lineGradientVert())
  selectedLineHorSolid = @(isActive)
    selectedLineSolid(isActive, [flex(), selLineSize])
  selectedLineVertSolid = @(isActive)
    selectedLineSolid(isActive, [selLineSize, flex()])
  opacityTransition
  selLineSize
}
