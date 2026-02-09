from "%globalsDarg/darg_library.nut" import *

let interopGen = require("%rGui/interopGen.nut")

let agmAimState = {
  TrackerX = Watched(0.0)
  TrackerY = Watched(0.0)
  TrackerSize = Watched(0.0)
  TrackerVisible = Watched(false)
  TrackerAngle = Watched(0.0)
  GuidanceLockState = Watched(-1)
  GuidanceLockStateBlinked = Watched(-1)
  PointIsTarget = Watched(false)
}

interopGen({
  stateTable = agmAimState
  prefix = "agmAim"
  postfix = "Update"
})

return agmAimState
