from "%globalsDarg/darg_library.nut" import *
let { tankZoomAutoAimMode, tankCrosshairColor } = require("%rGui/hudState.nut")
let { hasCrosshairForWeapon, isCurHoldWeaponInCancelZone
} = require("%rGui/hud/currentWeaponsStates.nut")
let { primaryAction, secondaryAction } = require("actionBar/actionBarState.nut")
let { isSecondaryBulletsSame } = require("bullets/hudUnitBulletsState.nut")
let { getSvgImage } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { crosshairColor, scopeSize } = require("%rGui/hud/commonSight.nut")
let { targetSelectionProgress } = require("%rGui/hud/targetSelectionProgress.nut")

let crosshairColorFire = Color(70, 70, 70)
let reloadColorPrimary = 0xCC23CACC
let reloadColorSecondary = 0xCC3C70BF
let crosshairLineWidth = hdpx(2)
let sightColor = Color(160, 160, 160, 200)
let cancelShootSize = hdpxi(70)

let crosshairLineHeight = evenPx(10)

let crosshairSize = shHud(3.5)
let pointSize = hdpxi(10)
let crosshairLineSize = hdpx(10)
let crosshairReloadSize = (1.7 * crosshairSize).tointeger()
let reloadImageInZoom = getSvgImage("reload_indication_in_zoom", crosshairReloadSize)

let fireIncreaseSizeAnimTime = 0.2
let fireDecreaseSizeAnimTime = 0.4
let fireNormalizeSizeAnimTime = 0.2

let fireColorAnimations = { prop = AnimProp.color, from = crosshairColorFire, to = crosshairColor,
  duration = fireIncreaseSizeAnimTime + fireDecreaseSizeAnimTime, easing = Linear, trigger = "fire" }

let fireAnimationIncreaseSize = { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3],
  duration = fireIncreaseSizeAnimTime, easing = Linear, trigger = "fire", onExit = "fireAnimationDecreaseSize"
}

let fireAnimationDecreaseSize = { prop = AnimProp.scale, from = [1.3, 1.3], to = [0.7, 0.7],
  duration = fireDecreaseSizeAnimTime, easing = Linear, trigger = "fireAnimationDecreaseSize",
  onExit = "fireAnimationNormalizeSize"
}

let fireAnimationNormalizeSize = { prop = AnimProp.scale, from = [0.7, 0.7], to = [1.0, 1.0],
  duration = fireNormalizeSizeAnimTime, easing = Linear, trigger = "fireAnimationNormalizeSize" }

let fireAnimationsInZomm = [ fireColorAnimations, fireAnimationIncreaseSize,
  fireAnimationDecreaseSize, fireAnimationNormalizeSize ]

let function mkReloadPartData(action, color) {
  let { cooldownEndTime = 0, cooldownTime = 0 } = action
  let cdLeft = cooldownEndTime - ::get_mission_time()
  if (cdLeft <= 0)
    return null
  return {
    cdLeft
    comp = {
      size = flex()
      rendObj = ROBJ_PROGRESS_CIRCULAR
      image = reloadImageInZoom
      fgColor = color
      bgColor = Color(0, 0, 0, 0)
      opacity = 0.0
      bValue = 1.0
      fValue = 1.0
      key = $"reload_sector_{cdLeft}_{cooldownTime}_{color}"
      animations = [
        {
          prop = AnimProp.fValue, to = 1.0, play = true,
          from = (1 - (cdLeft / max(cooldownTime, 1))),
          duration = cdLeft
        }
        {
          prop = AnimProp.opacity, from = 1.0, to = 1.0, play = true,
          duration = cdLeft
        }
      ]
    }
  }
}

let reloadSecAction = Computed(@() isSecondaryBulletsSame.value ? secondaryAction.value : null)
let reloadIndicator = @() {
  watch = [primaryAction, reloadSecAction]
  size = [crosshairReloadSize, crosshairReloadSize]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    mkReloadPartData(primaryAction.value, reloadColorPrimary)
    mkReloadPartData(reloadSecAction.value, reloadColorSecondary)
  ]
    .filter(@(v) v != null)
    .sort(@(a, b) a.cdLeft <=> b.cdLeft)
    .map(@(v) v.comp)
}

let pointCrosshair = {
  size = [pointSize, pointSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#sight_point.svg:{pointSize}:{pointSize}")
  color = crosshairColor
  transform = { pivot = [0.5, 0.5] }
  key = "crosshairInZoom"
  animations = fireAnimationsInZomm
  children = reloadIndicator
}

let circleCrosshair = {
  key = {}
  size = [crosshairSize, crosshairSize]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = crosshairLineWidth
  fillColor = 0
  color = crosshairColor
  commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
  children = [
    reloadIndicator
    {
      size = flex()
      rendObj = ROBJ_VECTOR_CANVAS
      lineWidth = crosshairLineWidth
      color = crosshairColor
      commands = [
        [VECTOR_LINE, -crosshairLineSize, 50, crosshairLineSize, 50],
        [VECTOR_LINE, 100 - crosshairLineSize, 50, 100 + crosshairLineSize, 50],
        [VECTOR_LINE, 50, -crosshairLineSize, 50, crosshairLineSize],
        [VECTOR_LINE, 50, 100 - crosshairLineSize, 50, 100 + crosshairLineSize],
      ]
      transform = { pivot = [0.5, 0.5] }
      animations = [
        fireAnimationIncreaseSize,
        { prop = AnimProp.scale, from = [1.3, 1.3], to = [1.0, 1.0],
          duration = fireDecreaseSizeAnimTime, easing = Linear, trigger = "fireAnimationDecreaseSize" }
      ]
    }
  ]
  transform = { pivot = [0.5, 0.5] }
  animations = fireAnimationsInZomm
}

let mkCrosshairAutoAim = @(color) {
  size = [crosshairSize, crosshairSize]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = crosshairLineWidth
  fillColor = 0
  color
  commands = [
    [VECTOR_WIDTH, hdpx(3)],
    [VECTOR_LINE, 50, 10, 50, 90],
    [VECTOR_LINE, 10, 50, 90, 50],
  ]
  transform = { pivot = [0.5, 0.5] }
  key = "crosshairInZoom"
  animations = fireAnimationsInZomm
  children = reloadIndicator
}

let sightCommands = [
  [VECTOR_LINE, 3, 0, 0, 5, 0, 95, 3, 100],
  [VECTOR_LINE, 97, 0, 100, 5, 100, 95, 97, 100],
  [VECTOR_WIDTH, 1],
  [VECTOR_RECTANGLE, -1, 35, 1, 30],
  [VECTOR_RECTANGLE, 100, 35, 1, 30],
]

let sightFrame = {
  rendObj = ROBJ_VECTOR_CANVAS
  size = scopeSize
  color = sightColor
  fillColor = sightColor
  commands = sightCommands
}

let cancelShootMark = {
  size = [cancelShootSize, cancelShootSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#sight_blocked.svg:{cancelShootSize}:{cancelShootSize}")
  color = 0x80FFFFFF
  keepAspect = true
}

let shipSight = @() {
  watch = [isCurHoldWeaponInCancelZone, hasCrosshairForWeapon]
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    targetSelectionProgress
    isCurHoldWeaponInCancelZone.value ? cancelShootMark
      : !hasCrosshairForWeapon.value ? sightFrame
      : circleCrosshair
    ]
}

let tankSight = @() {
  watch = [isCurHoldWeaponInCancelZone, tankZoomAutoAimMode, tankCrosshairColor]
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    targetSelectionProgress
    isCurHoldWeaponInCancelZone.value ? cancelShootMark
      : !tankZoomAutoAimMode.value ? pointCrosshair
      : tankCrosshairColor.value != 0 ? mkCrosshairAutoAim(tankCrosshairColor.value)
      : null
  ]
}

return {
  shipSight
  tankSight
  pointCrosshair
  crosshairLineWidth
  crosshairLineHeight
}