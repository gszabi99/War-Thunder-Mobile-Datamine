let { Watched, Computed } = require("frp")
let { Point2 } = require("dagor.math")

let isStickActiveByStick = Watched(false)
let isStickActiveByArrows = Watched(false)

return {
  isStickActiveByStick
  isStickActiveByArrows
  isStickActive = Computed(@() isStickActiveByStick.value || isStickActiveByArrows.value)
  stickDelta = Watched(Point2(0, 0))
}
