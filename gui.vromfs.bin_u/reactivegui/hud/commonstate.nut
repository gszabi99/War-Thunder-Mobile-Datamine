from "%globalsDarg/darg_library.nut" import *
from "dagor.math" import Point2
import "%rGui/interopGen.nut" as interopGet


let middle = Point2(sw(50), sh(50))
let commonState = {
  startCrosshairAnimationTime = Watched(0)
  crosshairScreenPosition = Watched([[middle.x, middle.y]])
  pointCrosshairScreenPosition = Watched(middle)
  crosshairDestinationScreenPosition = Watched(middle)
}

interopGet({
  stateTable = commonState
  prefix = "common"
  postfix = "Update"
})

return commonState
