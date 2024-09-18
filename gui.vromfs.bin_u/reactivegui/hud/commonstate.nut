from "%globalsDarg/darg_library.nut" import *
let interopGet = require("%rGui/interopGen.nut")
let { Point2 } = require("dagor.math")

let middle = Point2(sw(50), sh(50))
let commonState = {
  startCrosshairAnimationTime = Watched(0)
  crosshairScreenPosition = Watched(middle)
  pointCrosshairScreenPosition = Watched(middle)
  crosshairDestinationScreenPosition = Watched(middle)
  crosshairSecondaryScreenPosition = Watched(middle)
}

interopGet({
  stateTable = commonState
  prefix = "common"
  postfix = "Update"
})

return commonState
