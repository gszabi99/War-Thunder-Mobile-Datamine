from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/gamercardStyle.nut" import *
let { gradTranspDoubleSideX, gradDoubleTexOffset, mkColoredGradientY } = require("%rGui/style/gradients.nut")

let bgShaded = {
  rendObj = ROBJ_SOLID
  color = 0x80001521
}

let bgShadedLight = {
  rendObj = ROBJ_SOLID
  color = 0x60000F18
}

let bgShadedDark = {
  rendObj = ROBJ_SOLID
  color = 0xB0001A29
}

let bgMessage = {
  rendObj = ROBJ_IMAGE
  image = mkColoredGradientY(0xFF304453, 0xFF030C13)
}

let bgHeader = {
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, hdpx(300)]
  color = 0xFF4D88A4
}


return freeze({
  bgShaded
  bgShadedLight
  bgShadedDark
  bgMessage
  bgHeader
})
