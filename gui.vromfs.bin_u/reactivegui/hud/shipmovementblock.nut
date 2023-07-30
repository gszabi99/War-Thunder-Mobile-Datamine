from "%globalsDarg/darg_library.nut" import *
from "%rGui/controls/shortcutConsts.nut" import *
let { SUBMARINE } = require("%appGlobals/unitConst.nut")
let { lerpClamped } = require("%sqstd/math.nut")
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
  mkMoveVertBtnCorner, mkMoveVertBtn2step, fillMoveColorDef, fillMoveColorBlocked
} = require("%rGui/components/movementArrows.nut")
let { mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let axisListener = require("%rGui/controls/axisListener.nut")
let { gamepadAxes } = require("%rGui/controls/shortcutsMap.nut")
let { isGamepad } = require("%rGui/activeControls.nut")
let { send } = require("eventbus")

let HAPT_FORWARD = registerHapticPattern("Forward", { time = 0.0, intensity = 0.5, sharpness = 0.9, duration = 0.0, attack = 0.0, release = 0.0 })
let HAPT_BACKWARD = registerHapticPattern("Backward", { time = 0.0, intensity = 0.5, sharpness = 0.8, duration = 0.0, attack = 0.0, release = 0.0 })

let speedHeight = shHud(2.8)
let speedImageHeight = (0.7 * speedHeight).tointeger()
let speedImageWidth = (0.73 * speedImageHeight).tointeger()
let speedImagePadding = shHud(1.6).tointeger()

let isMoveCtrlHitShowed = Watched(false)
let function showCtrlHint() {
  if (!isMoveCtrlHitShowed.value) {
    send("hint:dont_hold_ctrl_to_move_ship:show", {})
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

let mkSteerParams = @(id) {
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
}

let function calcBackSpeedPart() {
  if (speed.value >= 0)
    return 0
  let maxSpeed = maxSpeedBySteps.value?[ - 1] ?? 0
  return maxSpeed < 0 ? clamp(speed.value / maxSpeed, 0.0, 1.0) : 0
}
let mkBackwardArrow = @(id) mkMoveVertBtn(
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
    flipY = true
    children = [
      mkMoveVertBtnAnimBg(true, calcBackSpeedPart, fillColor)
      mkMoveVertBtnOutline(true, outlineColor)
      mkMoveVertBtnCorner(true,
        Computed(@() averageSpeedDirection.value == "back" ? fillColor.value : 0xFFFFFFFF))
      mkGamepadShortcutImage(id, { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [0, ph(50)] })
    ]
  })

let function calcForwSpeedPart() {
  if (speed.value <= 0)
    return 0
  let maxSpeed = maxSpeedBySteps.value?[1] ?? 0
  return maxSpeed > 0 ? clamp(speed.value / maxSpeed, 0.0, 1.0) : 0
}

let function calcForwSpeedPart2() {
  let minSpeed = maxSpeedBySteps.value?[1] ?? 0
  if (speed.value <= minSpeed)
    return 0
  return lerpClamped(minSpeed, maxSpeedBySteps.value?[2] ?? 0, 0.0, 1.0, speed.value)
}

let fwdDirections = { forward = true, forward2 = true }
let mkForwardArrow = @(id) mkMoveVertBtn(
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
    children = [
      mkMoveVertBtnAnimBg(false, calcForwSpeedPart, fillColor)
      mkMoveVertBtnOutline(false, outlineColor)
      mkMoveVertBtnCorner(false,
        Computed(@() averageSpeedDirection.value in fwdDirections ? fillColor.value : 0xFFFFFFFF))
      mkMoveVertBtn2step(calcForwSpeedPart2,
        Computed(@() averageSpeedDirection.value == "forward2" ? fillColor.value : 0x00000000),
        fillColor)
      mkGamepadShortcutImage(id, { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [0, ph(-50)] })
    ]
  })

let mkStopImage = @(ovr = {}) @() !isStoppedSpeedStep.value ? { watch = isStoppedSpeedStep }
  : {
      watch = isStoppedSpeedStep
      rendObj = ROBJ_IMAGE
      size = [speedImageWidth, speedImageHeight]
      hplace = ALIGN_LEFT
      image = Picture($"!ui/gameuiskin#hud_movement_stop_selection_left.svg:{speedImageWidth}:{speedImageHeight}")
    }.__update(ovr)

let machineSpeed = {
  size = [flex(), speedHeight]
  padding = [0, speedImagePadding]
  valign = ALIGN_CENTER
  children = [
    mkStopImage()
    @() {
      watch = [averageSpeed]
      rendObj = ROBJ_TEXT
      hplace = ALIGN_CENTER
      text = machineSpeedLoc[averageSpeed.value]
    }.__update(fontTiny)
    mkStopImage({ flipX = true, hplace = ALIGN_RIGHT })
  ]
}

let speedComp = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  children = [
    speedValue({ margin = 0 }.__update(fontTiny))
    speedUnits(fontVeryTiny)
  ]
}

let shortcutsByType = {
  [SUBMARINE] = {
    engine_max = "submarine_main_engine_rangeMax"
    engine_min = "submarine_main_engine_rangeMin"
    aim_x = "submarine_mouse_aim_x"
    aim_y = "submarine_mouse_aim_y"
  },
}

let function movementBlock(unitType) {
  let {
    engine_max = "ship_main_engine_rangeMax",
    engine_min = "ship_main_engine_rangeMin",
    steering_max = "ship_steering_rangeMax",
    steering_min = "ship_steering_rangeMin",
    aim_x = "ship_mouse_aim_x",
    aim_y = "ship_mouse_aim_y"
  } = shortcutsByType?[unitType]

  let gamepadShipAxisListener = axisListener({
    [gamepadAxes[aim_x]] = @(v) setVirtualAxisValue(aim_x, v),
    [gamepadAxes[aim_y]] = @(v) setVirtualAxisValue(aim_y, v),
  })

  let leftArrow = mkMoveLeftBtn(mkSteerParams(steering_max))
  let rightArrow = mkMoveRightBtn(mkSteerParams(steering_min))

  return @() {
    watch = [isUnitDelayed, isGamepad]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_LEFT
    margin = [0, 0, shHud(5), 0]
    flow = FLOW_HORIZONTAL
    children = isUnitDelayed.value ? null
      : [
          leftArrow
          {
            flow = FLOW_VERTICAL
            halign = ALIGN_CENTER
            children = [
              mkForwardArrow(engine_max)
              machineSpeed
              mkBackwardArrow(engine_min)
            ]
          }
          {
            size = [SIZE_TO_CONTENT, flex()]
            children = [
              rightArrow
              speedComp
            ]
          }
          isGamepad.value ? gamepadShipAxisListener : null
        ]
    transform = {}
    animations = dfAnimBottomLeft
  }
}

return movementBlock
