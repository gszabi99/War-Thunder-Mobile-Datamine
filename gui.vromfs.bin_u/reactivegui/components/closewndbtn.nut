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
  lineWidth
  commands = [
    [VECTOR_LINE, l, l, r, r],
    [VECTOR_LINE, l, r, r, l],
  ]
  behavior = Behaviors.Button
  sound = { click  = "click" }
}

return function(onClick, override = {}) {
  let stateFlags = Watched(0)
  return @() btnBase.__merge({
    watch = stateFlags
    color = stateFlags.value & S_HOVER ? 0xFFFFFFFF : 0xFF808080
    onElemState = @(sf) stateFlags(sf)
    onClick

    transform = { scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }, override)
}

