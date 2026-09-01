from "dagor.math" import Point2
from "frp" import Watched, Computed


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
