from "%globalsDarg/darg_library.nut" import *

let wndHeaderHeight = hdpx(105)
let urlLineWidth = hdpx(1)
let gapAfterPoint = hdpx(10)

let linkColor = 0xFF1697E1

let urlUnderline = {
  size = [flex(), urlLineWidth]
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_SOLID
  color = linkColor
}

return {
  wndHeaderHeight
  urlLineWidth
  gapAfterPoint

  linkColor
  urlUnderline
}