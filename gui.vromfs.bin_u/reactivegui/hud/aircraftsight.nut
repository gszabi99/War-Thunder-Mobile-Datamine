from "%globalsDarg/darg_library.nut" import *
let { Indicator } = require("wt.behaviors")
let { hasTarget, targetUnitName, aircraftCrosshairColor, areSightHidden
} = require("%rGui/hudState.nut")
let { startCrosshairAnimationTime, pointCrosshairScreenPosition, crosshairDestinationScreenPosition
} = require("%rGui/hud/commonState.nut")
let { TargetLockTime } = require("%rGui/hud/airState.nut")
let { targetName, mkTargetSelectionData } = require("%rGui/hud/targetSelectionProgress.nut")
let { currentAircraftCtrlType, currentFixedAimCursor } = require("%rGui/options/options/airControlsOptions.nut")
let { currentCrosshairIconCfg } = require("%rGui/options/options/crosshairOptions.nut")
let { elementBlinks } = require("%rGui/tutorial/hudElementBlink.nut")


let airGunDirectionSize = oddPx(58)
let fixedAirGunDirectionSize = oddPx(11)
let isSightAttached = Watched(false)
let needSightBlink = keepref(Computed(@() isSightAttached.get() && (elementBlinks.get()?.crosshair ?? false)))
let needDestinationBlink = keepref(Computed(@() isSightAttached.get() && (elementBlinks.get()?.mouseAim ?? false)))
let airDestinationOpacity = 0.45

let sightTrigger = {}
let sightAnimatons = [{
  prop = AnimProp.scale, to = [1.2, 1.2], duration = 0.6,
  easing = CosineFull, loop = true, trigger = sightTrigger
}]
let destTrigger = {}
let destAnimatons = [{
  prop = AnimProp.scale, to = [1.2, 1.2], duration = 0.6,
  easing = CosineFull, loop = true, trigger = destTrigger
}]

needSightBlink.subscribe(@(v) v ? anim_start(sightTrigger) : anim_request_stop(sightTrigger))
needDestinationBlink.subscribe(@(v) v ? anim_start(destTrigger) : anim_request_stop(destTrigger))

let airTarget = @() {
  watch = [hasTarget, targetUnitName, startCrosshairAnimationTime, TargetLockTime]
  transform = {}
  behavior = Indicator
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = !hasTarget.value ? null
    : [
        targetName(targetUnitName.get() ?? "")
        mkTargetSelectionData(startCrosshairAnimationTime.value + TargetLockTime.value,
          TargetLockTime.value, calc_str_box(targetUnitName.get() ?? "", fontTiny))
      ]
}

let mkUpdatePosColor = @(posP2, color, opacity = 1.0) function() {
  let isValid =  posP2.get().x >= 0 && posP2.get().y >= 0
  return {
    color = isValid ? color.get() : 0
    opacity = isValid ? opacity : 0
    transform = { translate = [ posP2.get().x, posP2.get().y ] }
  }
}

function airCrosshair() {
  let { size, icon } = currentCrosshairIconCfg.get()
  return {
    watch = currentCrosshairIconCfg
    key = "airCrosshair"
    size
    onAttach = @() isSightAttached.set(true)
    onDetach = @() isSightAttached.set(false)
    pos = [ - size[0] / 2, - size[1] / 2]
    rendObj = ROBJ_IMAGE
    image = Picture($"{icon}:{size[0]}:{size[1]}:P")
    color = 0
    hplace = ALIGN_LEFT
    vplace = ALIGN_TOP
    behavior = Behaviors.RtPropUpdate
    update = mkUpdatePosColor(pointCrosshairScreenPosition, aircraftCrosshairColor)
    transform = {}
    animations = sightAnimatons
  }
}

function mkCrosshairIcon(icon, size) {
  return {
    key = "airCrosshairDirection"
    behavior = Behaviors.RtPropUpdate
    size = [size, size]
    pos = [- size / 2, - size / 2]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#{icon}:{size}:{size}:P")
    color = 0
    opacity = airDestinationOpacity
    hplace = ALIGN_LEFT
    vplace = ALIGN_TOP
    update = mkUpdatePosColor(crosshairDestinationScreenPosition, aircraftCrosshairColor, airDestinationOpacity)
    transform = {}
    animations = destAnimatons
  }
}

let airDestination = mkCrosshairIcon("mouse_pointer_air.svg", airGunDirectionSize)
let fixedAirDestination = mkCrosshairIcon("point_center_air.svg", fixedAirGunDirectionSize)

let aircraftSight = @() {
  watch = [areSightHidden, currentAircraftCtrlType, currentFixedAimCursor]
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = areSightHidden.get() ? null
    : [
        airCrosshair
        currentAircraftCtrlType.value != "mouse_aim" ? null
          : currentFixedAimCursor.value ? fixedAirDestination
          : airDestination
        airTarget
      ]
}

return aircraftSight
