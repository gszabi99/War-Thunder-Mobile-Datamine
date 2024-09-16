from "%globalsDarg/darg_library.nut" import *
let { Indicator } = require("wt.behaviors")
let { setDrawNativeAirCrosshair  = null } = require("hudState")
let { hasTarget, targetUnitName, aircraftCrosshairColor } = require("%rGui/hudState.nut")
let { startCrosshairAnimationTime, pointCrosshairScreenPosition, crosshairDestinationScreenPosition
} = require("%rGui/hud/commonState.nut")
let { TargetLockTime } = require("%rGui/hud/airState.nut")
let { targetName, mkTargetSelectionData } = require("%rGui/hud/targetSelectionProgress.nut")
let { currentAircraftCtrlType } = require("%rGui/options/options/airControlsOptions.nut")

let airCrosshairSize = evenPx(36)
let airGunDirectionSize = evenPx(58)


let airTarget = @() {
  watch = [hasTarget, targetUnitName, startCrosshairAnimationTime, TargetLockTime]
  transform = {}
  behavior = Indicator
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = !hasTarget.value ? null : [
    targetName(targetUnitName.value)
    mkTargetSelectionData(startCrosshairAnimationTime.value + TargetLockTime.value,
      TargetLockTime.value, calc_str_box(targetUnitName.value, fontTiny))
  ]
}

let mkUpdatePosColor = @(posP2, color) @() {
  color = color.get()
  transform = { translate = [ posP2.get().x, posP2.get().y ] }
}

let airCrosshair = {
  key = "airCrosshair"
  behavior = Behaviors.RtPropUpdate
  size = [airCrosshairSize, airCrosshairSize]
  pos = [ - airCrosshairSize * 0.5, - airCrosshairSize * 0.5]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#sight_air.svg:{airCrosshairSize}:{airCrosshairSize}:P")
  color = 0
  hplace = ALIGN_LEFT
  vplace = ALIGN_TOP
  update = mkUpdatePosColor(pointCrosshairScreenPosition, aircraftCrosshairColor)
}

let airDestination = {
  key = "airCrosshairDirection"
  behavior = Behaviors.RtPropUpdate
  size = [airGunDirectionSize, airGunDirectionSize]
  pos = [- airGunDirectionSize * 0.5, - airGunDirectionSize * 0.5]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#mouse_pointer_air.svg:{airGunDirectionSize}:{airGunDirectionSize}:P")
  color = 0
  opacity = 0.45
  hplace = ALIGN_LEFT
  vplace = ALIGN_TOP
  update = mkUpdatePosColor(crosshairDestinationScreenPosition, aircraftCrosshairColor)
}

let aircraftSight = @() {
  watch = currentAircraftCtrlType
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = setDrawNativeAirCrosshair == null ? airTarget
    : [
        airCrosshair
        currentAircraftCtrlType.value == "mouse_aim" ? airDestination : null
        airTarget
      ]
}

return aircraftSight
