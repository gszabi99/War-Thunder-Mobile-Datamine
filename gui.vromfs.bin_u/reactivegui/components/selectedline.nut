from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/listConst.nut" import selLineSize
from "%rGui/style/stdColors.nut" import selectColor


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
    selectedLineSolid(isActive, [FLEX, selLineSize])
  selectedLineVertSolid = @(isActive)
    selectedLineSolid(isActive, [selLineSize, FLEX])
  opacityTransition
  selLineSize
}
