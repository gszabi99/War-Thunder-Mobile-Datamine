from "%globalsDarg/darg_library.nut" import *
let { selectColor } = require("%rGui/style/stdColors.nut")

let selLineSize = hdpx(8)
let opacityTransition = [{ prop = AnimProp.opacity, duration = 0.3, easing = InOutQuad }]

let selectedLineSolid = @(isActive, size) @() {
  watch = isActive
  size
  rendObj = ROBJ_SOLID
  color = selectColor
  opacity = isActive.get() ? 1 : 0
  transitions = opacityTransition
}

return {
  selectedLineHorSolid = @(isActive)
    selectedLineSolid(isActive, [flex(), selLineSize])
  selectedLineVertSolid = @(isActive)
    selectedLineSolid(isActive, [selLineSize, flex()])
  opacityTransition
  selLineSize
}
