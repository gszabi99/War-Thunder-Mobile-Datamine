from "%globalsDarg/darg_library.nut" import *
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")

let fadedTextColor = 0xFFACACAC

let bgGradWidth = hdpx(1200)
let bgGradLineHeight = hdpx(4)
let doubleSideGradBG = {
  size = [bgGradWidth, flex()]
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, 0.45 * bgGradWidth]
  color = 0xA0000000
}

let doubleSideGradLine = doubleSideGradBG.__merge({
  size = [bgGradWidth, bgGradLineHeight]
  color = fadedTextColor
})

let bgGradient = {
  size = flex()
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    doubleSideGradLine
    doubleSideGradBG
    doubleSideGradLine
  ]
  transform = { pivot = [0.5, 0] }
}

return {
  bgGradient
  fadedTextColor
}
