from "%globalsDarg/darg_library.nut" import *
let interopGet = require("%rGui/interopGen.nut")
let { Point2 } = require("dagor.math")

let commonState = {
  startCrosshairAnimationTime = Watched(0)
  crosshairScreenPosition = Watched(Point2(0, 0))
}

interopGet({
  stateTable = commonState
  prefix = "common"
  postfix = "Update"
})

return commonState
