from "%globalsDarg/darg_library.nut" import *
let { gradTranspDoubleSideX, gradDoubleTexOffset, simpleHorGrad } = require("%rGui/style/gradients.nut")

let doubleSideGradientPaddingX = hdpx(100)
let doubleSideGradientPaddingY = hdpx(20)
let doubleSideGradient = {
  padding = [doubleSideGradientPaddingY, doubleSideGradientPaddingX]
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, hdpx(300)]
  color = 0x90000000
}

let headerGradientBg = @(children, ovr = {}) {
  size = [SIZE_TO_CONTENT, hdpx(60)]
  vplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    pos = [-saBordersRv[1], 0]
    rendObj = ROBJ_IMAGE
    image = simpleHorGrad
    flipX = true
    color = 0x80000000
    padding = [hdpx(20), hdpx(50), hdpx(20), saBordersRv[1]]
    flow = FLOW_HORIZONTAL
    gap = hdpx(35)
    valign = ALIGN_CENTER
    children
  }
}.__update(ovr)

return {
  doubleSideGradient
  doubleSideGradientPaddingX
  doubleSideGradientPaddingY

  headerGradientBg
}