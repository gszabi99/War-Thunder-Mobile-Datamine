from "%globalsDarg/darg_library.nut" import *
from "guidanceConstants" import GuidanceLockResult
from "%rGui/hud/airState.nut" import AamState
from "%rGui/rocketAim/rocketAamAimState.nut" import GuidanceLockState


let aamSeekerState = Computed(@(prev) GuidanceLockState.get() != GuidanceLockResult.RESULT_INVALID
  ? GuidanceLockState.get()
  : prev == FRP_INITIAL ? GuidanceLockResult.RESULT_STANDBY
  : prev)

let isAamLocked = Computed(@() AamState.get().count != 0 && aamSeekerState.get() >= GuidanceLockResult.RESULT_TRACKING)

let getAamShortcutId = @() (AamState.get().count != 0 && !isAamLocked.get()) ? "ID_WEAPON_LOCK" : "ID_AAM"

return {
  isAamLocked
  getAamShortcutId
}
