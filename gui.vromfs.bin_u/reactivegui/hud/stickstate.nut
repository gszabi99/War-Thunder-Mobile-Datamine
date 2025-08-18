let { Watched, Computed } = require("frp")
let { Point2 } = require("dagor.math")

let isStickActiveByStick = Watched(false)
let isStickActiveByArrows = Watched(false)

enum STICK {
  LEFT
  RIGHT
}

return {
  STICK
  isStickActiveByStick
  isStickActiveByArrows
  isStickActive = Computed(@() isStickActiveByStick.get() || isStickActiveByArrows.get())
  stickDelta = Watched(Point2(0, 0))
}
