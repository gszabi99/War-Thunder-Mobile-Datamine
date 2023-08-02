from "%globalsDarg/darg_library.nut" import *
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")

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

return {
  doubleSideGradient
  doubleSideGradientPaddingX
  doubleSideGradientPaddingY
}