from "%globalsDarg/darg_library.nut" import *
let { Indicator } = require("wt.behaviors")
let { hasTarget, targetUnitName, aircraftCrosshairColor, areSightHidden
} = require("%rGui/hudState.nut")
let { startCrosshairAnimationTime, pointCrosshairScreenPosition, crosshairDestinationScreenPosition
} = require("%rGui/hud/commonState.nut")
let { TargetLockTime } = require("%rGui/hud/airState.nut")
let { targetName, mkTargetSelectionData } = require("%rGui/hud/targetSelectionProgress.nut")
let { currentAircraftCtrlType } = require("%rGui/options/options/airControlsOptions.nut")
let { currentCrosshairIconCfg } = require("%rGui/options/options/crosshairOptions.nut")
let { elementBlinks } = require("%rGui/tutorial/hudElementBlink.nut")


let airGunDirectionSize = oddPx(58)
let isSightAttached = Watched(false)
let needSightBlink = keepref(Computed(@() isSightAttached.get() && (elementBlinks.get()?.crosshair ?? false)))
let needDestinationBlink = keepref(Computed(@() isSightAttached.get() && (elementBlinks.get()?.mouseAim ?? false)))

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

let mkUpdatePosColor = @(posP2, color) @() {
  color = color.get()
  transform = { translate = [ posP2.get().x, posP2.get().y ] }
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

let airDestination = {
  key = "airCrosshairDirection"
  behavior = Behaviors.RtPropUpdate
  size = [airGunDirectionSize, airGunDirectionSize]
  pos = [- airGunDirectionSize / 2, - airGunDirectionSize / 2]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#mouse_pointer_air.svg:{airGunDirectionSize}:{airGunDirectionSize}:P")
  color = 0
  opacity = 0.45
  hplace = ALIGN_LEFT
  vplace = ALIGN_TOP
  update = mkUpdatePosColor(crosshairDestinationScreenPosition, aircraftCrosshairColor)
  transform = {}
  animations = destAnimatons
}

let aircraftSight = @() {
  watch = [areSightHidden, currentAircraftCtrlType]
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = areSightHidden.get() ? null
    : [
        airCrosshair
        currentAircraftCtrlType.value == "mouse_aim" ? airDestination : null
        airTarget
      ]
}

return aircraftSight
