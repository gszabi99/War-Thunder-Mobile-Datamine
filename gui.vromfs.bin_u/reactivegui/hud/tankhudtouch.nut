from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { dfAnimLeft, dfAnimBottomCenter } = require("%rGui/style/unitDelayAnims.nut")
let tankMovementBlock = require("%rGui/hud/tankMovementBlock.nut")
let tankStateModule = require("%rGui/hud/tankStateModule.nut")
let tankWeaponryBlock = require("tankWeaponryBlock.nut")
let hudTopCenter = require("%rGui/hud/hudTopCenter.nut")
let hudBottomCenter = require("hudBottomCenter.nut")
let { tankSight, crosshairLineWidth, crosshairLineHeight } = require("%rGui/hud/sight.nut")
let { tankCrosshairColor, tankZoomAutoAimMode, isUnitDelayed, tankCrosshairDmTestResult
} = require("%rGui/hudState.nut")
let { crosshairColor, crosshairSimpleSize } = require("%rGui/hud/commonSight.nut")
let { crosshairScreenPosition, crosshairDestinationScreenPosition } = require("%rGui/hud/commonState.nut")
let { shootReadyness, primaryRocketGun } = require("%rGui/hud/tankState.nut")
let { getSvgImage, touchMenuButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")
let actionBar = require("actionBar/actionBar.nut")
let hudTimers = require("%rGui/hudHints/hudTimers.ui.nut")
let menuButton = require("%rGui/hud/mkMenuButton.nut")()
let tacticalMapTransparent = require("components/tacticalMapTransparent.nut")
let { logerrAndKillLogPlace } = require("%rGui/hudHints/hintBlocks.nut")
let winchButton = require("buttons/winchButton.nut")(touchMenuButtonSize)
let { mkCircleTankPrimaryGun, mkCountTextRight } = require("buttons/circleTouchHudButtons.nut")
let { primaryAction } = require("actionBar/actionBarState.nut")
let hitCamera = require("hitCamera/hitCamera.nut")
let zoomSlider = require("%rGui/hud/zoomSlider.nut")
let { DM_TEST_NOT_PENETRATE, DM_TEST_RICOCHET } = require("crosshair")
let { currentArmorPiercingFixed } = require("%rGui/options/options/controlsOptions.nut")

let crosshairReadyColor = Color(232, 75, 60)
let crosshairSize = evenPx(38)
let crosshairReadySize = (1.7 * crosshairSize).tointeger()
let readyImage = getSvgImage("reload_indication_in_zoom", crosshairReadySize)

let crosshairHalfSize = (0.5 * crosshairSimpleSize).tointeger()
let halfCrosshairLineHeight = (0.5 * crosshairLineHeight).tointeger()
let sizeAim = [crosshairLineWidth, crosshairLineHeight]
let sizeAimRv = [sizeAim[1], sizeAim[0]]

let hasNoPenetrationState = Computed(@() tankCrosshairDmTestResult.value == DM_TEST_NOT_PENETRATE ||
                                         tankCrosshairDmTestResult.value == DM_TEST_RICOCHET)

let triggers = [TRIGGER_GROUP_PRIMARY, TRIGGER_GROUP_SECONDARY, TRIGGER_GROUP_COAXIAL_GUN, TRIGGER_GROUP_MACHINE_GUN]
  .reduce(function(res, t) {
    res[t] <- $"bullet_shot_{t}"
    return res
  }, {})

let mkCrosshairAnims = @(from, to) [
  {
    prop = AnimProp.translate, from, to = to.map(@(v, i) v * 0.25 + from[i]), duration = 0.15,
    easing = Blink, trigger = triggers[TRIGGER_GROUP_COAXIAL_GUN]
  }
  {
    prop = AnimProp.translate, from, to = to.map(@(v, i) v * 0.25 + from[i]), duration = 0.15,
    easing = Blink, trigger = triggers[TRIGGER_GROUP_MACHINE_GUN]
  }
  {
    prop = AnimProp.translate, from, to, duration = 0.3,
    easing = Blink, trigger = triggers[TRIGGER_GROUP_SECONDARY]
  }
  {
    prop = AnimProp.translate, from, to, duration = 0.3,
    easing = Blink, trigger = triggers[TRIGGER_GROUP_PRIMARY]
  }
]

let sightDestinationUpdate = @() {
  transform = {
    translate = [
      crosshairDestinationScreenPosition.value.x
      crosshairDestinationScreenPosition.value.y
    ]
  }
}

let screenPositionUpdate = @() {
    transform = {
      translate = [
        crosshairScreenPosition.value.x,
        crosshairScreenPosition.value.y
      ]
    }
  }

subscribe("onControlledBulletStart", @(d) anim_start(triggers?[d.triggerGroup]))

let arcadeCrosshairSight = @() tankZoomAutoAimMode.value  ?
{ watch = [tankCrosshairColor, tankZoomAutoAimMode ] }
:
{
  watch = [tankCrosshairColor, tankZoomAutoAimMode, hasNoPenetrationState, currentArmorPiercingFixed ]
  behavior = Behaviors.RtPropUpdate
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  size = [crosshairSimpleSize, crosshairSimpleSize]
  pos = [-saBorders[0] - crosshairHalfSize, -saBorders[1] - crosshairHalfSize]
  children = [
    {
      key = hasNoPenetrationState.value
      rendObj = ROBJ_SOLID
      color = tankCrosshairColor.value
      size = sizeAim
      hplace = ALIGN_CENTER
      vplace = ALIGN_LEFT
      transitions = [{ prop = AnimProp.translate, duration = 0.1, easing = Linear }]
      transform = { translate = hasNoPenetrationState.value ? [0, -halfCrosshairLineHeight] : [0, 0] }
      animations = hasNoPenetrationState.value ? mkCrosshairAnims([0, -halfCrosshairLineHeight], [0, hdpx(-30)])
        : mkCrosshairAnims([0, 0], [0, hdpx(-30)])
    }
    {
      key = hasNoPenetrationState.value
      rendObj = ROBJ_SOLID
      color = tankCrosshairColor.value
      size = sizeAimRv
      hplace = ALIGN_LEFT
      vplace = ALIGN_CENTER
      transitions = [{ prop = AnimProp.translate, duration = 0.1, easing = Linear }]
      transform = { translate = hasNoPenetrationState.value ? [-halfCrosshairLineHeight, 0] : [0, 0] }
      animations = hasNoPenetrationState.value ? mkCrosshairAnims([-halfCrosshairLineHeight, 0], [hdpx(-30), 0])
        : mkCrosshairAnims([0, 0], [hdpx(-30), 0])
    }
    {
      key = hasNoPenetrationState.value
      rendObj = ROBJ_SOLID
      color = tankCrosshairColor.value
      size = sizeAim
      hplace = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      transitions = [{ prop = AnimProp.translate, duration = 0.1, easing = Linear }]
      transform = { translate = hasNoPenetrationState.value ? [0, halfCrosshairLineHeight] : [0, 0] }
      animations = hasNoPenetrationState.value ? mkCrosshairAnims([0, halfCrosshairLineHeight], [0, hdpx(30)])
        : mkCrosshairAnims([0, 0], [0, hdpx(30)])
    }
    {
      key = hasNoPenetrationState.value
      rendObj = ROBJ_SOLID
      color = tankCrosshairColor.value
      size = sizeAimRv
      vplace = ALIGN_CENTER
      hplace = ALIGN_RIGHT
      transitions = [{ prop = AnimProp.translate, duration = 0.1, easing = Linear }]
      transform = { translate = hasNoPenetrationState.value ? [halfCrosshairLineHeight, 0] : [0, 0] }
      animations = hasNoPenetrationState.value ? mkCrosshairAnims([halfCrosshairLineHeight, 0], [hdpx(30), 0])
        : mkCrosshairAnims([0, 0], [hdpx(30), 0])
    }
  ]
  update = currentArmorPiercingFixed.value ? sightDestinationUpdate : screenPositionUpdate
}


let arcadeCrosshairAim = @() tankZoomAutoAimMode.value ?
{
  watch = [tankCrosshairColor, tankZoomAutoAimMode, currentArmorPiercingFixed]
  behavior = Behaviors.RtPropUpdate
  color = crosshairColor
  size = [crosshairSimpleSize, crosshairSimpleSize]
  lineWidth = crosshairLineWidth
  rendObj = ROBJ_VECTOR_CANVAS
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  commands = [
      [VECTOR_FILL_COLOR, 0],
      [VECTOR_ELLIPSE, 50, 50, 40, 40],
    ]
  update = currentArmorPiercingFixed.value ? sightDestinationUpdate : screenPositionUpdate
}
:
{ watch = [tankCrosshairColor, tankZoomAutoAimMode] }

let circle = @(color, width) {
    color
    fillColor = 0
    rendObj = ROBJ_VECTOR_CANVAS
    size = flex()
    lineWidth = width
    commands = [
      [VECTOR_ELLIPSE, 50, 50, 50, 50],
    ]
}

let mkCircleGunPosition = {
  behavior = Behaviors.RtPropUpdate
  pos = [-saBorders[0] - crosshairHalfSize, -saBorders[1] - crosshairHalfSize]
  size = [crosshairSimpleSize, crosshairSimpleSize]
  children = [circle(Color(200, 200, 200, 200), crosshairLineWidth)]
  update = screenPositionUpdate
}

let arcadeCrosshair = @() {
  watch = [currentArmorPiercingFixed, primaryRocketGun]
  children = [
    primaryRocketGun.value ? null : arcadeCrosshairSight
    currentArmorPiercingFixed.value && !primaryRocketGun.value ? mkCircleGunPosition : null
  ]
}

let mkReadyPart = @(progress) {
  size = flex()
  rendObj = ROBJ_PROGRESS_CIRCULAR
  image = readyImage
  fgColor = crosshairReadyColor
  bgColor = 0
  opacity = 0.0
  bValue = 1.0
  fValue = 1.0
  key = $"ready_sector_{progress}"
  animations = [
    {
      prop = AnimProp.fValue,
      from = 1 - progress
      to =  1.0,
      play = true,
    }
    {
      prop = AnimProp.opacity, from = 1.0, to = 1.0, play = progress > 0.0,
    }
  ]
}

let gunReadyIndicator = @() {
  watch = shootReadyness
  size = [crosshairReadySize, crosshairReadySize]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = mkReadyPart(shootReadyness.value)
}

let controlsWrapper = {
  padding = [0, 0, 0, hdpx(540)]
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_BOTTOM
  children = [
    tankStateModule
    actionBar
  ]
}

let hudBottom = @() {
  watch = isUnitDelayed
  size = [flex(), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = isUnitDelayed.value ? null
    : [
        hudTimers
        controlsWrapper
      ]
  transform = {}
  animations = dfAnimBottomCenter
}

let mapGap = hdpx(40)
let hudTopLeft = {
  flow = FLOW_VERTICAL
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = mapGap
      children = [
        menuButton
        tacticalMapTransparent
      ]
    }
    @() {
      watch = isUnitDelayed
      flow = FLOW_HORIZONTAL
      gap = mapGap
      children = [
        isUnitDelayed.value ? null : winchButton
        logerrAndKillLogPlace
      ]
      transform = {}
      animations = dfAnimLeft
    }
  ]
}

let leftShootButton = @() {
  watch = [primaryAction, isUnitDelayed]
  vplace = ALIGN_CENTER
  pos = [hdpx(10), hdpx(10)]
  children = isUnitDelayed.value || primaryAction.value == null ? null
    : mkCircleTankPrimaryGun(primaryAction.value, "btn_weapon_primary_alt", mkCountTextRight)
  transform = {}
  animations = dfAnimLeft
}

return {
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  key = "tank-hud-touch"
  children = [
    hudTopLeft
    zoomSlider
    hudTopCenter
    hitCamera
    tankMovementBlock
    hudBottom
    hudBottomCenter
    leftShootButton
    tankWeaponryBlock
    gunReadyIndicator
    tankSight
    arcadeCrosshairAim
    arcadeCrosshair
  ]
}
