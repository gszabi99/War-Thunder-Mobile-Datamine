from "%globalsDarg/darg_library.nut" import *

let textColor = 0xFFD0D0D0
let headerHeight = hdpx(60)
let gap = hdpx(10)

let bg = {
  rendObj = ROBJ_SOLID
  color = 0x99000000
}

let headerText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = textColor
}.__update(fontTinyAccented)

let header = @(children, ovr = {}) bg.__merge({
  size = [flex(), headerHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children
}, ovr)

let headerMarquee = @(width) {
  size = [width, SIZE_TO_CONTENT]
  behavior = Behaviors.Marquee
  delay = 1
  speed = hdpx(50)
}

return {
  bg
  gap
  headerText
  header
  headerHeight
  headerMarquee
}