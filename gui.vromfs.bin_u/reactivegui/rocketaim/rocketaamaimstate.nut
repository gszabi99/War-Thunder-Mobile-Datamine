from "%globalsDarg/darg_library.nut" import *

let interopGen = require("%rGui/interopGen.nut")

let aamAimState = {
  GimbalX = Watched(0.0)
  GimbalY = Watched(0.0)
  GimbalSize = Watched(0.0)
  GimbalVisible = Watched(false)

  TrackerX = Watched(0.0)
  TrackerY = Watched(0.0)
  TrackerSize = Watched(0.0)
  TrackerVisible = Watched(false)

  GuidanceLockState = Watched(-1)
  GuidanceLockSnr = Watched(0.0)

  AamSightOpacity = Watched(1.0)
}

interopGen({
  stateTable = aamAimState
  prefix = "aamAim"
  postfix = "Update"
})

return aamAimState