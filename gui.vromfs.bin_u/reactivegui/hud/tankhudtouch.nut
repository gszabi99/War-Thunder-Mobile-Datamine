from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let hudTuningElems = require("%rGui/hudTuning/hudTuningElems.nut")
let hudTopMainLog = require("%rGui/hud/hudTopMainLog.nut")
let hudBottomCenter = require("hudBottomCenter.nut")
let { tankSight, crosshairLineWidth, crosshairLineHeight } = require("%rGui/hud/sight.nut")
let { tankCrosshairColor, tankZoomAutoAimMode, tankCrosshairDmTestResult, isFreeCamera
} = require("%rGui/hudState.nut")
let { crosshairColor, crosshairSimpleSize } = require("%rGui/hud/commonSight.nut")
let { crosshairScreenPosition, crosshairDestinationScreenPosition, crosshairSecondaryScreenPosition
} = require("%rGui/hud/commonState.nut")
let { shootReadyness, primaryRocketGun, hasSecondaryGun, allowShoot } = require("%rGui/hud/tankState.nut")
let { getSvgImage } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { startActionBarUpdate, stopActionBarUpdate } = require("actionBar/actionBarState.nut")
let menuButton = require("%rGui/hud/mkMenuButton.nut")()
let { DM_TEST_NOT_PENETRATE, DM_TEST_RICOCHET } = require("crosshair")
let { currentArmorPiercingFixed } = require("%rGui/options/options/tankControlsOptions.nut")
let hudTimersBlock = require("%rGui/hud/hudTimersBlock.nut")
let { setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")


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

let secondarySightPositionUpdate = @() {
    transform = {
      translate = [
        crosshairSecondaryScreenPosition.value.x,
        crosshairSecondaryScreenPosition.value.y
      ]
    }
  }

eventbus_subscribe("onControlledBulletStart", @(d) anim_start(triggers?[d.triggerGroup]))

function mkCrosshairLine(from, to, ovr) {
  return {
      key = hasNoPenetrationState.value
      rendObj = ROBJ_SOLID
      color = tankCrosshairColor.value
      transitions = [{ prop = AnimProp.translate, duration = 0.1, easing = Linear }]
      transform = { translate = hasNoPenetrationState.value ? from : [0, 0] }
      animations = hasNoPenetrationState.value ? mkCrosshairAnims(from, to) : mkCrosshairAnims([0, 0], to)
    }.__update(ovr)
}

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
    mkCrosshairLine([0, -halfCrosshairLineHeight], [0, hdpx(-30)], { size = sizeAim, hplace = ALIGN_CENTER, vplace = ALIGN_LEFT })
    mkCrosshairLine([-halfCrosshairLineHeight, 0], [hdpx(-30), 0], {size = sizeAimRv, hplace = ALIGN_LEFT, vplace = ALIGN_CENTER })
    mkCrosshairLine([0, halfCrosshairLineHeight], [0, hdpx(30)], {size = sizeAim, hplace = ALIGN_CENTER, vplace = ALIGN_BOTTOM })
    mkCrosshairLine([halfCrosshairLineHeight, 0], [hdpx(30), 0], {size = sizeAimRv, hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER })
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

function mkCircleGunPosition(for_secondary) {
  let color = for_secondary ? Color(150, 150, 150, 150) : Color(200, 200, 200, 200)
  return {
    behavior = Behaviors.RtPropUpdate
    pos = [-saBorders[0] - crosshairHalfSize, -saBorders[1] - crosshairHalfSize]
    size = [crosshairSimpleSize, crosshairSimpleSize]
    children = [circle(color, crosshairLineWidth)]
    update = for_secondary ? secondarySightPositionUpdate : screenPositionUpdate
  }
}

let arcadeCrosshair = @() {
  watch = [currentArmorPiercingFixed, primaryRocketGun, hasSecondaryGun, isFreeCamera, allowShoot]
  children = [
    primaryRocketGun.value || isFreeCamera.value ? null : arcadeCrosshairSight
    currentArmorPiercingFixed.value && !primaryRocketGun.value && allowShoot.value ? mkCircleGunPosition(false) : null
    hasSecondaryGun.value && allowShoot.value ? mkCircleGunPosition(true) : null
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

eventbus_subscribe("LocalPlayerDead", @(_) setShortcutOff("ID_FIRE_GM_MACHINE_GUN"))

return {
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  key = "tank-hud-touch"
  onAttach = @() startActionBarUpdate("tankHud")
  onDetach = @() stopActionBarUpdate("tankHud")
  children = [
    hudTimersBlock
    hudTopMainLog
    hudBottomCenter
    hudTuningElems
    menuButton
    gunReadyIndicator
    tankSight
    arcadeCrosshairAim
    arcadeCrosshair
  ]
}
