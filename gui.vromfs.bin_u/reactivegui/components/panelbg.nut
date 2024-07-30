from "%globalsDarg/darg_library.nut" import *
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")

return freeze({
    rendObj = ROBJ_IMAGE
    image = mkColoredGradientY(0xB0000000, 0x30000000, 12)
    padding = [hdpx(30), hdpx(30) ,hdpx(30)]
    flow = FLOW_VERTICAL
})