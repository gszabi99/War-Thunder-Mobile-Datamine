from "%globalsDarg/darg_library.nut" import *
let { hasTarget, targetUnitName } = require("%rGui/hudState.nut")
let { startCrosshairAnimationTime } = require("%rGui/hud/commonState.nut")
let { TargetLockTime } = require("%rGui/hud/airState.nut")
let { targetName, mkTargetSelectionData } = require("%rGui/hud/targetSelectionProgress.nut")

let aircraftSight = @() {
  watch = [hasTarget, targetUnitName, startCrosshairAnimationTime, TargetLockTime]
  transform = {}
  behavior = Behaviors.Indicator
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = !hasTarget.value ? null : [
    targetName(targetUnitName.value)
    mkTargetSelectionData(startCrosshairAnimationTime.value + TargetLockTime.value,
      TargetLockTime.value, calc_str_box(targetUnitName.value, fontTiny))
  ]
}

return aircraftSight
