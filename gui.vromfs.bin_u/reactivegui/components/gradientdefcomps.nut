from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, gradDoubleTexOffset, simpleHorGrad


let headerRowHeight = evenPx(60)
const headerGradientPaddingY = hdpxi(20)
let headerHeightInSafeArea = headerRowHeight + headerGradientPaddingY
const headerMargin = hdpx(20)

const doubleSideGradientPaddingX = hdpx(100)
const doubleSideGradientPaddingY = hdpx(20)
let doubleSideGradient = {
  padding = const [doubleSideGradientPaddingY, doubleSideGradientPaddingX]
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, hdpx(300)]
  color = 0x90000000
}

let headerGradientBg = @(children, ovr = {}) {
  size = [SIZE_TO_CONTENT, headerHeightInSafeArea]
  margin = const [0, 0, headerMargin, 0]
  padding = const [0, 0, headerGradientPaddingY, 0]
  valign = ALIGN_CENTER
  children = {
    size = [SIZE_TO_CONTENT, headerRowHeight + 2 * headerGradientPaddingY]
    pos = [-saBordersRv[1], 0]
    rendObj = ROBJ_IMAGE
    image = simpleHorGrad
    flipX = true
    color = 0x80000000
    padding = [headerGradientPaddingY, hdpx(50), headerGradientPaddingY, saBordersRv[1]]
    flow = FLOW_HORIZONTAL
    gap = hdpx(35)
    valign = ALIGN_CENTER
    children
  }
}.__update(ovr)

let headerGradientWithRightBlock = @(leftChildren, rightChildren, ovr = {}) {
  size = [FLEX, headerHeightInSafeArea]
  margin = const [0, 0, headerMargin, 0]
  padding = const [0, 0, headerGradientPaddingY, 0]
  valign = ALIGN_CENTER
  children = [
    headerGradientBg(leftChildren, { margin = 0, vplace = ALIGN_TOP })
    {
      size = FLEX
      halign = ALIGN_RIGHT
      valign = ALIGN_CENTER
      children = rightChildren
    }
  ]
}.__update(ovr)

return {
  doubleSideGradient
  doubleSideGradientPaddingX
  doubleSideGradientPaddingY

  headerGradientBg
  headerGradientWithRightBlock
  headerRowHeight
  headerHeightInSafeArea
  headerMargin
  headerGradientPaddingY
}