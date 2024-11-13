from "%globalsDarg/darg_library.nut" import *
from "%rGui/controls/shortcutConsts.nut" import *
let { SUBMARINE } = require("%appGlobals/unitConst.nut")
let { lerpClamped, round } = require("%sqstd/math.nut")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { getScaledFont } = require("%globalsDarg/fontScale.nut")
let { dfAnimBottomLeft } = require("%rGui/style/unitDelayAnims.nut")
let { setShortcutOn, setShortcutOff, setVirtualAxisValue } = require("%globalScripts/controls/shortcutActions.nut")
let { speedValue, speedUnits, averageSpeed, machineSpeedLoc, isStoppedSpeedStep, machineSpeedDirection
} = require("%rGui/hud/shipStateView.nut")
let { getHeroShipMaxSpeedBySteps } = require("hudState")
let { registerHapticPattern, playHapticPattern } = require("hapticVibration")
let { playerUnitName, isUnitDelayed } = require("%rGui/hudState.nut")
let { speed, hasDebuffEngines, hasDebuffMoveControl, currentMaxThrottle } = require("%rGui/hud/shipState.nut")
let { playSound } = require("sound_wt")
let { btnBgColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkMoveLeftBtn, mkMoveRightBtn, mkMoveVertBtn, mkMoveVertBtnAnimBg, mkMoveVertBtnOutline,
  mkMoveVertBtnCorner, mkMoveVertBtn2step, fillMoveColorDef, fillMoveColorBlocked, arrowsVerSize
} = require("%rGui/components/movementArrows.nut")
let { mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let axisListener = require("%rGui/controls/axisListener.nut")
let { gamepadAxes } = require("%rGui/controls/shortcutsMap.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { eventbus_send } = require("eventbus")
let { mkIsControlDisabled } = require("%rGui/controls/disabledControls.nut")

let HAPT_FORWARD = registerHapticPattern("Forward", { time = 0.0, intensity = 0.5, sharpness = 0.9, duration = 0.0, attack = 0.0, release = 0.0 })
let HAPT_BACKWARD = registerHapticPattern("Backward", { time = 0.0, intensity = 0.5, sharpness = 0.8, duration = 0.0, attack = 0.0, release = 0.0 })

let speedHeight = shHud(2.8)
let speedImageHeight = (0.7 * speedHeight).tointeger()
let speedImageWidth = (0.73 * speedImageHeight).tointeger()
let speedImagePadding = hdpxi(10)

let isMoveCtrlHitShowed = Watched(false)
function showCtrlHint() {
  if (!isMoveCtrlHitShowed.value) {
    eventbus_send("hint:dont_hold_ctrl_to_move_ship:show", {})
    isMoveCtrlHitShowed(true)
  }
}

let averageSpeedDirection = Computed(@() machineSpeedDirection[averageSpeed.value])

let maxSpeedBySteps = Computed(function() {
  if (playerUnitName.value == "")
    return {}

  return getHeroShipMaxSpeedBySteps()
})

let isControlsBlocked = Computed(@() hasDebuffMoveControl.value || currentMaxThrottle.value == 0.0)

let outlineColor = Computed(@()
  isControlsBlocked.value ? fillMoveColorBlocked
  : hasDebuffEngines.value || currentMaxThrottle.value < 1.0 ? btnBgColor.broken
  : 0x4D4D4D4D)
let fillColor = Computed(@()
  isControlsBlocked.value ? fillMoveColorBlocked
  : hasDebuffEngines.value || currentMaxThrottle.value < 1.0 ? btnBgColor.broken
  : fillMoveColorDef)

let mkSteerParams = @(id, disableId, scale) {
  scale
  ovr = { key = id }
  shortcutId = id
  outlineColor
  function onTouchBegin() {
    if (!isControlsBlocked.value) {
      setShortcutOn(id)
      playSound("steer")
    }
  }
  onTouchEnd = @() setShortcutOff(id)
  isDisabled = mkIsControlDisabled(disableId)
}

function calcBackSpeedPart() {
  if (speed.value >= 0)
    return 0
  let maxSpeed = maxSpeedBySteps.value?[ - 1] ?? 0
  return maxSpeed < 0 ? clamp(speed.value / maxSpeed, 0.0, 1.0) : 0
}
let mkBackwardArrow = @(id, isEngineDisabled, verSize, scale) mkMoveVertBtn(
  function onTouchBegin() {
    if (!isControlsBlocked.value) {
      setShortcutOn(id)
      playHapticPattern(HAPT_BACKWARD)
      showCtrlHint()
    }
  },
  @() setShortcutOff(id),
  id,
  {
    key = id
    size = verSize
    flipY = true
    children = @() {
      watch = isEngineDisabled
      size = flex()
      children = isEngineDisabled.value ? null
        : [
            mkMoveVertBtnAnimBg(true, calcBackSpeedPart, verSize, fillColor)
            mkMoveVertBtnOutline(true, verSize, outlineColor)
            mkMoveVertBtnCorner(true,
              Computed(@() averageSpeedDirection.value == "back" ? fillColor.value : 0xFFFFFFFF),
              verSize)
            mkGamepadShortcutImage(id, { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [0, ph(50)] }, scale)
          ]
    }
  })

function calcForwSpeedPart() {
  if (speed.value <= 0)
    return 0
  let maxSpeed = maxSpeedBySteps.value?[1] ?? 0
  return maxSpeed > 0 ? clamp(speed.value / maxSpeed, 0.0, 1.0) : 0
}

function calcForwSpeedPart2() {
  let minSpeed = maxSpeedBySteps.value?[1] ?? 0
  if (speed.value <= minSpeed)
    return 0
  return lerpClamped(minSpeed, maxSpeedBySteps.value?[2] ?? 0, 0.0, 1.0, speed.value)
}

let fwdDirections = { forward = true, forward2 = true }
let mkForwardArrow = @(id, isEngineDisabled, verSize, scale) mkMoveVertBtn(
  function onTouchBegin() {
    if (!isControlsBlocked.value) {
      setShortcutOn(id)
      playHapticPattern(HAPT_FORWARD)
      showCtrlHint()
    }
  },
  @() setShortcutOff(id),
  id,
  {
    key = id
    size = verSize
    children = @() {
      watch = isEngineDisabled
      size = flex()
      children = isEngineDisabled.value ? null
        : [
            mkMoveVertBtnAnimBg(false, calcForwSpeedPart, verSize, fillColor)
            mkMoveVertBtnOutline(false, verSize, outlineColor)
            mkMoveVertBtnCorner(false,
              Computed(@() averageSpeedDirection.value in fwdDirections ? fillColor.value : 0xFFFFFFFF),
              verSize)
            mkMoveVertBtn2step(calcForwSpeedPart2,
              Computed(@() averageSpeedDirection.value == "forward2" ? fillColor.value : 0x00000000),
              verSize,
              fillColor)
            mkGamepadShortcutImage(id, { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [0, ph(-50)] }, scale)
          ]
    }
  })

function mkStopImage(scale, ovr = {}) {
  let size = scaleArr([speedImageWidth, speedImageHeight], scale)
  return @() !isStoppedSpeedStep.value ? { watch = isStoppedSpeedStep }
    : {
        watch = isStoppedSpeedStep
        size
        rendObj = ROBJ_IMAGE
        hplace = ALIGN_LEFT
        image = Picture($"!ui/gameuiskin#hud_movement_stop_selection_left.svg:{size[0]}:{size[1]}")
      }.__update(ovr)
}

let machineSpeed = @(scale) {
  size = [flex(), speedHeight]
  padding = [0, round(speedImagePadding * scale)]
  valign = ALIGN_CENTER
  children = [
    mkStopImage(scale)
    @() {
      watch = [averageSpeed]
      rendObj = ROBJ_TEXT
      hplace = ALIGN_CENTER
      text = machineSpeedLoc[averageSpeed.value]
    }.__update(getScaledFont(fontTinyShaded, scale))
    mkStopImage(scale, { flipX = true, hplace = ALIGN_RIGHT })
  ]
}

let speedComp = @(scale) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  gap = hdpx(2)
  children = [
    speedValue(scale)
    speedUnits(scale)
  ]
}

let shortcutsByType = {
  [SUBMARINE] = {
    engineAxis = "submarine_main_engine"
    aim_x = "submarine_mouse_aim_x"
    aim_y = "submarine_mouse_aim_y"
  },
}

function movementBlock(unitType, scale) {
  let {
    engineAxis = "ship_main_engine",
    steeringAxis = "ship_steering",
    aim_x = "ship_mouse_aim_x",
    aim_y = "ship_mouse_aim_y"
  } = shortcutsByType?[unitType]

  let engine_max = $"{engineAxis}_rangeMax"
  let engine_min = $"{engineAxis}_rangeMin"

  let gamepadShipAxisListener = axisListener({
    [gamepadAxes[aim_x]] = @(v) setVirtualAxisValue(aim_x, v),
    [gamepadAxes[aim_y]] = @(v) setVirtualAxisValue(aim_y, v),
  })

  let leftArrow = mkMoveLeftBtn(mkSteerParams($"{steeringAxis}_rangeMax", steeringAxis, scale))
  let rightArrow = mkMoveRightBtn(mkSteerParams($"{steeringAxis}_rangeMin", steeringAxis, scale))

  let verSize = scaleArr(arrowsVerSize, scale)
  let isEngineDisabled = mkIsControlDisabled(engineAxis)
  let middle = [
    mkForwardArrow(engine_max, isEngineDisabled, verSize, scale)
    machineSpeed(scale)
    mkBackwardArrow(engine_min, isEngineDisabled, verSize, scale)
  ]

  return @() {
    watch = [isUnitDelayed, isGamepad]
    flow = FLOW_HORIZONTAL
    children = isUnitDelayed.value ? null
      : [
          leftArrow
          {
            flow = FLOW_VERTICAL
            halign = ALIGN_CENTER
            children = middle
          }
          {
            size = [SIZE_TO_CONTENT, flex()]
            children = [
              rightArrow
              speedComp(scale)
            ]
          }
          isGamepad.value ? gamepadShipAxisListener : null
        ]
    transform = {}
    animations = dfAnimBottomLeft
  }
}

return movementBlock
