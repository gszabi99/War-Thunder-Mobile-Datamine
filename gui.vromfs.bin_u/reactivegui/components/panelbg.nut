from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/gradients.nut" import mkColoredGradientY


return freeze({
  rendObj = ROBJ_IMAGE
  image = mkColoredGradientY(0xB0000000, 0x30000000, 12)
  padding = hdpx(30)
  flow = FLOW_VERTICAL
})