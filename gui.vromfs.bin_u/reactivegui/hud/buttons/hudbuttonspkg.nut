from "%globalsDarg/darg_library.nut" import *
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { userHoldWeapKeys, userHoldWeapInside } = require("%rGui/hud/currentWeaponsStates.nut")
let { hasTarget, hasTargetCandidate } = require("%rGui/hudState.nut")
let { imageColor, textDisabledColor } = require("%rGui/hud/hudTouchButtonStyle.nut")

let defShortcutOvr = { hplace = ALIGN_CENTER, vplace = ALIGN_CENTER, pos = [0, ph(-50)] }

function mkBtnZone(key, zoneRadiusX, zoneRadiusY) {
  let isVisible = Computed(@() !isGamepad.value && (userHoldWeapKeys.value?[key] ?? false))
  let isInside = Computed(@() userHoldWeapInside.value?[key] ?? true)
  return @() !isVisible.value ? { watch = isVisible }
    : {
        watch = isVisible
        size = [2 * zoneRadiusX, 2 * zoneRadiusY]
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        children = @() {
          watch = isInside
          size = flex()
          rendObj = ROBJ_VECTOR_CANVAS
          color = isInside.value ? 0x20404040 : 0x20602020
          fillColor = 0
          lineWidth = hdpx(3)
          commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
          animations = [{ prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.5,
            easing = OutQuad, play = true }]
        }
      }
}

let canLock = Computed(@() ((hasTargetCandidate.value && !hasTarget.value) || hasTarget.value ))

let lockButtonIcon = @(targetTrackingImgSize, targetTrackingOffImgSize) @(){
  watch = [hasTarget, canLock]
  rendObj = ROBJ_IMAGE
  size = hasTarget.get() ? [targetTrackingImgSize, targetTrackingImgSize] : [targetTrackingOffImgSize, targetTrackingOffImgSize]
  image = hasTarget.get()
    ? Picture($"ui/gameuiskin#hud_target_tracking.svg:{targetTrackingImgSize}:{targetTrackingImgSize}")
    : Picture($"ui/gameuiskin#hud_target_tracking_off.svg:{targetTrackingOffImgSize}:{targetTrackingOffImgSize}")
  keepAspect = true
  color = canLock.value ? imageColor : textDisabledColor
}


return {
  canLock
  mkBtnZone
  lockButtonIcon
  defShortcutOvr
}
