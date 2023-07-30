from "%globalsDarg/darg_library.nut" import *

let size = hdpx(40)
let lineWidth = evenPx(6)
let l = 50.0 * lineWidth / size
let r = 100.0 - l
let btnBase = {
  size = [size, size]
  margin = [hdpx(20), hdpx(20)]
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_VECTOR_CANVAS
  color = 0xFF808080
  lineWidth
  commands = [
    [VECTOR_LINE, l, l, r, r],
    [VECTOR_LINE, l, r, r, l],
  ]
  behavior = Behaviors.Button
  sound = { click  = "click" }
}

return @(onClick, override = {}) btnBase.__merge({ onClick }, override)

