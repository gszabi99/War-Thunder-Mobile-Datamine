from "%globalsDarg/darg_library.nut" import *
let { getHeroTankMaxSpeedBySteps } = require("hudState")
let { lerpClamped } = require("%sqstd/math.nut")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { setVirtualAxisValue, changeCruiseControl } = require("%globalScripts/controls/shortcutActions.nut")
let { registerHapticPattern, playHapticPattern } = require("hapticVibration")
let { speed, cruiseControl } = require("%rGui/hud/tankState.nut")
let { playSound } = require("sound_wt")
let { setTimeout, setInterval, resetTimeout, clearTimer } = require("dagor.workcycle")
let { mkMoveLeftBtn, mkMoveRightBtn, mkMoveVertBtnOutline, mkMoveVertBtnAnimBg, arrowsVerSize,
  mkMoveVertBtnCorner, mkMoveVertBtn2step, fillMoveColorDef, mkMoveVertBtn, mkStopBtn
} = require("%rGui/components/movementArrows.nut")
let { playerUnitName } = require("%rGui/hudState.nut")
let { isStickActiveByArrows, stickDelta } = require("stickState.nut")
let { currentTankMoveCtrlType } = require("%rGui/options/chooseMovementControls/tankMoveControlType.nut")
let { currentGearDownOnStopButtonTouch } = require("%rGui/options/options/tankControlsOptions.nut")
let { Point2 } = require("dagor.math")
let { eventbus_send } = require("eventbus")

let HAPT_FORWARD = registerHapticPattern("Forward",
  { time = 0.0, intensity = 0.5, sharpness = 0.9, duration = 0.0, attack = 0.0, release = 0.0 })
let HAPT_BACKWARD = registerHapticPattern("Backward",
  { time = 0.0, intensity = 0.5, sharpness = 0.8, duration = 0.0, attack = 0.0, release = 0.0 })
let deltaSteer = 0.1
let minSteer = 0.7
local curSteerValue = minSteer
let steerWatch = Watched(0)
let delayHigh = 0.25
let delayLow = 0.5
let delayReverse = 3

const CRUISE_CONTROL_UNDEF = -2
const CRUISE_CONTROL_R = -1
const CRUISE_CONTROL_N = 0
const CRUISE_CONTROL_1 = 1
const CRUISE_CONTROL_MAX = 3

local holdingForStopShowCount = 2

local prevCruiseControl = CRUISE_CONTROL_UNDEF

let isTurnTypesCtrlShowed = Watched(false)
let isStopButtonVisible = Watched(false)

let maxSpeedBySteps = Computed(@() playerUnitName.value == "" ? {} : getHeroTankMaxSpeedBySteps())

function axelerate(flipY) {
  if ((prevCruiseControl == CRUISE_CONTROL_1 && cruiseControl.value == CRUISE_CONTROL_N) ||
      (cruiseControl.value == CRUISE_CONTROL_R && flipY))
    return false

  local diff = flipY ? -1 : 1
  if (cruiseControl.value == CRUISE_CONTROL_1 && !flipY)
    diff = 2
  if (cruiseControl.value == CRUISE_CONTROL_MAX)
    diff = -2
  prevCruiseControl = cruiseControl.value
  changeCruiseControl(diff)
  if (diff > 0 && prevCruiseControl == CRUISE_CONTROL_N)
    isStopButtonVisible(true)
  return true
}

function updateStickDelta(_) {
  let deltaY = cruiseControl.value == CRUISE_CONTROL_N ? 0
             : cruiseControl.value == CRUISE_CONTROL_R ? -1
             : 1
  isStickActiveByArrows(deltaY != 0 || steerWatch.value != 0) //warning disable: -named-like-should-return
  let multX = deltaY == 0 ? 1 : 0.5
  stickDelta(Point2(steerWatch.value * multX, deltaY))
}

cruiseControl.subscribe(updateStickDelta)
steerWatch.subscribe(updateStickDelta)

let fullStopOnTouchButton = Computed(@() currentTankMoveCtrlType.value == "arrows" && currentGearDownOnStopButtonTouch.value)

function toNeutral() {
  if (holdingForStopShowCount > 0 && !fullStopOnTouchButton.value) {
    eventbus_send("hint:holding_for_stop:show", {})
    --holdingForStopShowCount
  }
  prevCruiseControl = CRUISE_CONTROL_UNDEF
  changeCruiseControl(-cruiseControl.value)
}

function toReverse() {
  prevCruiseControl = CRUISE_CONTROL_N
  changeCruiseControl(CRUISE_CONTROL_R)
  isStopButtonVisible(false)
}

function setGmBrakeAxis(v) {
  setVirtualAxisValue("gm_brake_left", v)
  setVirtualAxisValue("gm_brake_right", v)
}

function updateAxeleration(flipY) {
  if (prevCruiseControl == CRUISE_CONTROL_UNDEF || !axelerate(flipY))
    return
  let updateAxelerationImpl = callee()
  let delay = prevCruiseControl == CRUISE_CONTROL_N && !flipY ? delayHigh : delayLow
  resetTimeout(delay, @() updateAxelerationImpl (flipY))
}

function steeringAxelerate(id, flipX) {
  curSteerValue = min(curSteerValue + deltaSteer, 1)
  steerWatch(flipX ? -curSteerValue : curSteerValue)
  setVirtualAxisValue(id, steerWatch.value)
}

function mkSteerParams(isRight, scale) {
  function onTouchUpdate() {
    steeringAxelerate("gm_steering", isRight)
    if (speed.value == 0)
      toNeutral()
  }
  let shortcutId = isRight ? "gm_steering_right" : "gm_steering_left"
  return {
    scale
    ovr = { key = shortcutId }
    shortcutId
    function onTouchBegin() {
      setGmBrakeAxis(0)
      if (cruiseControl.value == 0)
        curSteerValue = 1
      steeringAxelerate("gm_steering", isRight)
      setInterval(0.3, onTouchUpdate)
      playSound("steer")
      if (!isTurnTypesCtrlShowed.value) {
        eventbus_send("hint:turn_types_ctrl:show", {})
        isTurnTypesCtrlShowed(true)
      }
    }
    function onTouchEnd() {
      clearTimer(onTouchUpdate)
      setVirtualAxisValue("gm_steering", 0)
      steerWatch(0)
      curSteerValue = minSteer
    }
  }
}

function mkStopParams(verSize) {
  let shortcutId = "ID_TRANS_GEAR_DOWN"
   return {
    ovr = { key = "gm_brake", size = verSize }
    shortcutId
    function onTouchBegin() {
      setGmBrakeAxis(1)
      toNeutral()
      if (fullStopOnTouchButton.get())
        isStopButtonVisible(false)
      else
        setTimeout(delayReverse, toReverse)
    }
    function onTouchEnd() {
      if (!fullStopOnTouchButton.value)
        setGmBrakeAxis(0)
      clearTimer(toReverse)
      isStopButtonVisible(false)
    }
  }
}

let isMoveCtrlHitShowed = Watched(false)

function mkEngineBtn(isBackward, id, verSize, children) {
  let onTouchUpdate = @() updateAxeleration(isBackward)
  return mkMoveVertBtn(
    function onTouchBegin() {
      setGmBrakeAxis(0)
      playHapticPattern(isBackward ? HAPT_BACKWARD : HAPT_FORWARD)
      if (axelerate(isBackward))
        setTimeout(delayLow, onTouchUpdate)
      if (!isMoveCtrlHitShowed.value) {
        eventbus_send("hint:dont_hold_ctrl_to_move_tank:show", {})
        isMoveCtrlHitShowed(true)
      }
    },
    function onTouchEnd() {
      prevCruiseControl = CRUISE_CONTROL_UNDEF
      clearTimer(onTouchUpdate)
    },
    id,
    {
      key = id
      size = verSize
      flipY = isBackward
      children
    })
}

function calcBackSpeedPart() {
  if (speed.value >= 0)
    return 0
  let maxSpeed = maxSpeedBySteps.value?[ - 1] ?? 0
  return maxSpeed < 0 ? clamp(speed.value / maxSpeed.tofloat(), 0.0, 1.0) : 0
}

let backwardArrow = @(verSize) mkEngineBtn(true, "ID_TRANS_GEAR_DOWN", verSize,
  [
    mkMoveVertBtnAnimBg(true, calcBackSpeedPart, verSize)
    mkMoveVertBtnOutline(true, verSize)
    mkMoveVertBtnCorner(true,
      Computed(@() cruiseControl.value == CRUISE_CONTROL_R ? fillMoveColorDef : 0xFFFFFFFF),
      verSize)
  ])

function calcForwSpeedPart() {
  if (speed.value <= 0)
    return 0
  let maxSpeed = maxSpeedBySteps.value?[1] ?? 0
  return maxSpeed > 0 ? clamp(speed.value / maxSpeed.tofloat(), 0.0, 1.0) : 0
}

function calcForwSpeedPart2() {
  let minSpeed = maxSpeedBySteps.value?[1] ?? 0
  if (speed.value <= minSpeed)
    return 0.0
  let res = lerpClamped(minSpeed.tofloat(), (maxSpeedBySteps.value?[2] ?? 0).tofloat(), 0.0, 1.0, speed.value)
  return res
}

let fwdControl = { [CRUISE_CONTROL_1] = true, [CRUISE_CONTROL_MAX] = true }
let forwardArrow = @(verSize) mkEngineBtn(false, "ID_TRANS_GEAR_UP", verSize,
  [
    mkMoveVertBtnAnimBg(false, calcForwSpeedPart, verSize)
    mkMoveVertBtnOutline(false, verSize)
    mkMoveVertBtnCorner(false,
      Computed(@() cruiseControl.value in fwdControl ? fillMoveColorDef : 0xFFFFFFFF),
      verSize)
    mkMoveVertBtn2step(calcForwSpeedPart2,
      Computed(@() cruiseControl.value == CRUISE_CONTROL_MAX ? fillMoveColorDef : 0x00000000),
      verSize)
  ])

return function(scale) {
  let verSize = scaleArr(arrowsVerSize, scale)
  return {
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_LEFT
    margin = [0, 0, shHud(1), 0]
    flow = FLOW_HORIZONTAL
    children = [
      mkMoveLeftBtn(mkSteerParams(false, scale))
      {
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        gap = shHud(2)
        children = [
          forwardArrow(verSize)
          @() {
            watch = isStopButtonVisible
            children = isStopButtonVisible.value ? mkStopBtn(mkStopParams(verSize)) : backwardArrow(verSize)
          }
        ]
      }
      mkMoveRightBtn(mkSteerParams(true, scale))
    ]
  }
}
