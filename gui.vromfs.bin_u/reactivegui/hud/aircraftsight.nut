from "%globalsDarg/darg_library.nut" import *
let { hasTarget } = require("%rGui/hudState.nut")
let { startCrosshairAnimationTime } = require("%rGui/hud/commonState.nut")
let { TargetLockTime } = require("%rGui/hud/airState.nut")
let { crosshairSimpleSize, pointingAnimSteps, pointingSectors, mkSector } = require("%rGui/hud/commonSight.nut")

let function crosshairSimple() {
  if (!hasTarget.value)
    return { watch = [ hasTarget ] }

  let leftTimeAnimKey = $"{TargetLockTime.value}_{startCrosshairAnimationTime.value}"
  let leftAnimTime = (startCrosshairAnimationTime.value + TargetLockTime.value) - ::get_mission_time()
  let stepAnimTime = leftAnimTime > 0 ? leftAnimTime / pointingAnimSteps : 0
  return {
    watch = [ hasTarget, TargetLockTime, startCrosshairAnimationTime ]
    size = [crosshairSimpleSize, crosshairSimpleSize]
    behavior = Behaviors.Indicator
    key = $"crosshairSimple_{leftTimeAnimKey}"
    children = pointingSectors.map(@(sector, idx) mkSector(sector, idx, leftTimeAnimKey, stepAnimTime))
    transform = { pivot = [0.5, 0.5] }
  }
}

let aircraftSight = {
  size = [sw(100), sh(100)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = crosshairSimple
}

return aircraftSight
