from "%globalsDarg/darg_library.nut" import *
from "%rGui/controls/shortcutConsts.nut" import *
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { lerpClamped } = require("%sqstd/math.nut")
let { setVirtualAxisValue } = require("controls")
let { dfAnimBottomLeft } = require("%rGui/style/unitDelayAnims.nut")
let { setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { getHeroWalkerMaxSpeedBySteps } = require("hudState")
let { registerHapticPattern, playHapticPattern } = require("hapticVibration")
let { playerUnitName, isUnitDelayed } = require("%rGui/hudState.nut")
let { speed } = require("%rGui/hud/tankState.nut")
let { playSound } = require("sound_wt")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { mkMoveLeftBtn, mkMoveRightBtn, mkMoveVertBtn2step, mkMoveVertBtn, mkMoveVertBtnAnimBg, mkMoveVertBtnOutline,
  mkMoveVertBtnCorner, mkStopBtn, arrowsVerSize, outlineColorDef, fillMoveColorDef } = require("%rGui/components/movementArrows.nut")
let { mkIsControlDisabled } = require("%rGui/controls/disabledControls.nut")
let { currentWalkerMoveCtrlType } = require("%rGui/options/chooseMovementControls/groundMoveControlType.nut")
let { hudWhiteColor, hudTransparentColor } = require("%rGui/style/hudColors.nut")

let HAPT_FORWARD = registerHapticPattern("Forward",
  { time = 0.0, intensity = 0.5, sharpness = 0.9, duration = 0.0, attack = 0.0, release = 0.0 })
let HAPT_BACKWARD = registerHapticPattern("Backward",
  { time = 0.0, intensity = 0.5, sharpness = 0.8, duration = 0.0, attack = 0.0, release = 0.0 })
let delayHigh = 0.25
let delayLow = 0.5
let delayReverse = 3

const CRUISE_CONTROL_UNDEF = -2
const CRUISE_CONTROL_R = -1
const CRUISE_CONTROL_N = 0
const CRUISE_CONTROL_1 = 1
const CRUISE_CONTROL_MAX = 3

let cruiseControl = Watched(CRUISE_CONTROL_N)
local prevCruiseControl = CRUISE_CONTROL_UNDEF
let isStopButtonVisible = Watched(false)

let maxSpeedBySteps = Computed(@() playerUnitName.get() == "" ? {} : getHeroWalkerMaxSpeedBySteps())

function axelerate(isBackward) {
  if ((prevCruiseControl == CRUISE_CONTROL_1 && cruiseControl.get() == CRUISE_CONTROL_N) ||
      (cruiseControl.get() == CRUISE_CONTROL_R && isBackward))
    return false

  prevCruiseControl = cruiseControl.get()

  if (isBackward) {
    setVirtualAxisValue("walker_throttle", -1.0)
    cruiseControl.set(CRUISE_CONTROL_R)
  } else if (cruiseControl.get() == CRUISE_CONTROL_1) {
    setVirtualAxisValue("walker_throttle", 1.0)
    cruiseControl.set(CRUISE_CONTROL_MAX)
  }
  else if (cruiseControl.get() == CRUISE_CONTROL_N || cruiseControl.get() == CRUISE_CONTROL_MAX) {
    setVirtualAxisValue("walker_throttle", 0.5)
    cruiseControl.set(CRUISE_CONTROL_1)
  } else if (cruiseControl.get() == CRUISE_CONTROL_R) {
    setVirtualAxisValue("walker_throttle", 0.0)
    cruiseControl.set(CRUISE_CONTROL_N)
  }

  if (cruiseControl.get() > CRUISE_CONTROL_N)
    isStopButtonVisible.set(true)

  return true
}

let fullStopOnTouchButton = Computed(@() currentWalkerMoveCtrlType.get() == "arrows")

function toNeutral() {
  prevCruiseControl = CRUISE_CONTROL_UNDEF
  setVirtualAxisValue("walker_throttle", 0)
  cruiseControl.set(CRUISE_CONTROL_N)
}

function toReverse() {
  prevCruiseControl = CRUISE_CONTROL_N
  setVirtualAxisValue("walker_throttle", -1)
  cruiseControl.set(CRUISE_CONTROL_R)
  isStopButtonVisible.set(false)
}

function setGmBrakeAxis(v) {
  if (v == 1.0)
    setVirtualAxisValue("walker_throttle", 0)
}

function updateAxeleration(isBackward) {
  if (prevCruiseControl == CRUISE_CONTROL_UNDEF || !axelerate(isBackward))
    return
  let updateAxelerationImpl = callee()
  let delay = prevCruiseControl == CRUISE_CONTROL_N && !isBackward ? delayHigh : delayLow
  resetTimeout(delay, @() updateAxelerationImpl (isBackward))
}

let mkSteerParams = @(id, disableId, scale) {
  scale
  ovr = { key = id }
  shortcutId = id
  function onTouchBegin() {
    setShortcutOn(id)
    playSound("steer")
  }
  onTouchEnd = @() setShortcutOff(id)
  isDisabled = mkIsControlDisabled(disableId)
}

function mkStopParams(verSize) {
  let shortcutId = "walker_throttle_rangeMin"
  return {
    ovr = { key = "gm_brake", size = verSize }
    shortcutId
    function onTouchBegin() {
      toNeutral()
      if (fullStopOnTouchButton.get())
        isStopButtonVisible.set(false)
      else
        resetTimeout(delayReverse, toReverse)
    }
    function onTouchEnd() {
      clearTimer(toReverse)
      isStopButtonVisible.set(false)
    }
  }
}

function mkEngineBtn(isBackward, id, verSize, children) {
  let onTouchUpdate = @() updateAxeleration(isBackward)
  return mkMoveVertBtn(
    function onTouchBegin() {
      setGmBrakeAxis(0)
      playHapticPattern(isBackward ? HAPT_BACKWARD : HAPT_FORWARD)
      if (axelerate(isBackward))
        resetTimeout(delayLow, onTouchUpdate)
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
  if (speed.get() >= 0)
    return 0
  let maxSpeed = maxSpeedBySteps.get()?[ - 1] ?? 0
  return maxSpeed < 0 ? clamp(speed.get() / maxSpeed.tofloat(), 0.0, 1.0) : 0
}

let backwardArrow = @(verSize) mkEngineBtn(true, "walker_throttle_rangeMin", verSize,
  [
    mkMoveVertBtnAnimBg(true, calcBackSpeedPart, verSize)
    mkMoveVertBtnOutline(true, verSize)
    mkMoveVertBtnCorner(true,
      Computed(@() cruiseControl.get() == CRUISE_CONTROL_R ? hudWhiteColor : outlineColorDef.get()),
      verSize)
  ])

function calcForwSpeedPart() {
  if (speed.get() <= 0)
    return 0
  let maxSpeed = maxSpeedBySteps.get()?[1] ?? 0
  return maxSpeed > 0 ? clamp(speed.get() / maxSpeed.tofloat(), 0.0, 1.0) : 0
}

function calcForwSpeedPart2() {
  let minSpeed = maxSpeedBySteps.get()?[1] ?? 0
  if (speed.get() <= minSpeed)
    return 0.0
  let res = lerpClamped(minSpeed.tofloat(), (maxSpeedBySteps.get()?[2] ?? 0).tofloat(), 0.0, 1.0, speed.get())
  return res
}

let fwdControl = { [CRUISE_CONTROL_1] = true, [CRUISE_CONTROL_MAX] = true }
let forwardArrow = @(verSize) mkEngineBtn(false, "walker_throttle_rangeMax", verSize,
  [
    mkMoveVertBtnAnimBg(false, calcForwSpeedPart, verSize)
    mkMoveVertBtnOutline(false, verSize)
    mkMoveVertBtnCorner(false,
      Computed(@() cruiseControl.get() in fwdControl ? hudWhiteColor : outlineColorDef.get()),
      verSize)
    mkMoveVertBtn2step(calcForwSpeedPart2,
      Computed(@() cruiseControl.get() == CRUISE_CONTROL_MAX ? fillMoveColorDef : hudTransparentColor),
      verSize)
  ])

function movementBlock(scale) {
  let steeringAxis = "walker_steering"

  let leftArrow = mkMoveLeftBtn(mkSteerParams($"{steeringAxis}_rangeMax", steeringAxis, scale))
  let rightArrow = mkMoveRightBtn(mkSteerParams($"{steeringAxis}_rangeMin", steeringAxis, scale))
  let verSize = scaleArr(arrowsVerSize, scale)

  return @() {
    watch = [isUnitDelayed]
    flow = FLOW_HORIZONTAL
    children = isUnitDelayed.get() ? null
      : [
          leftArrow
          {
            flow = FLOW_VERTICAL
            halign = ALIGN_CENTER
            gap = shHud(2)
            children = [
              forwardArrow(verSize)
              @() {
                watch = isStopButtonVisible
                children = isStopButtonVisible.get() ? mkStopBtn(mkStopParams(verSize)) : backwardArrow(verSize)
              }
            ]
          }
          {
            size = FLEX_V
            children = rightArrow
          }
        ]
    transform = {}
    animations = dfAnimBottomLeft
  }
}

return movementBlock
