from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer, setInterval } = require("dagor.workcycle")
let { TouchScreenSteeringStick } = require("wt.behaviors")
let { Point3 } = require("dagor.math")
let { fabs, lerp } = require("%sqstd/math.nut")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { getScaledFont, prettyScaleForSmallNumberCharVariants } = require("%globalsDarg/fontScale.nut")
let { setAxisValue,  setShortcutOn, setShortcutOff, setVirtualAxisValue, setVirtualAxesAileronsElevatorValue,
  setVirtualAxesAim =  null, setVirtualAxesAileronsAssist = null, setVirtualAxesDirectControl = null
} = require("%globalScripts/controls/shortcutActions.nut")
let { Trt0, IsTrtWep0, Spd, DistanceToGround, IsSpdCritical, IsOnGround, isActiveTurretCamera, wheelBrake } = require("%rGui/hud/airState.nut")
let { getSvgImage, borderColor, btnBgColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { registerHapticPattern, playHapticPattern } = require("hapticVibration")
let axisListener = require("%rGui/controls/axisListener.nut")
let shortcutsMap = require("%rGui/controls/shortcutsMap.nut")
let { ailerons, mouse_aim_x, mouse_aim_y, throttle_axis, rudder, elevator, turret_x, turret_y} = shortcutsMap.gamepadAxes
let { axisMinToHotkey, axisMaxToHotkey } = require("%rGui/controls/axisToHotkey.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { mkBtnImageComp } = require("%rGui/controlsMenu/gamepadImgByKey.nut")
let { playerUnitName, unitType, isUnitDelayed } = require("%rGui/hudState.nut")
let { AIR } = require("%appGlobals/unitConst.nut")
let { currentControlByGyroModeAileronsAssist, currentControlByGyroAimMode, currentControlByGyroDirectControl,
      currentControlByGyroModeAileronsDeadZone, currentControlByGyroModeAileronsSensitivity,
      currentControlByGyroModeElevatorDeadZone, currentControlByGyroModeElevatorSensitivity,
      currentAircraftCtrlType, currentThrottleStick, currentAdditionalFlyControls } = require("%rGui/options/options/airControlsOptions.nut")
let { set_mouse_aim } = require("controlsOptions")
let { isRespawnStarted } = require("%appGlobals/clientState/respawnStateBase.nut")
let { mkMoveLeftBtn, mkMoveRightBtn, mkMoveVertBtn, mkMoveVertBtnOutline, mkMoveVertBtnCorner
} = require("%rGui/components/movementArrows.nut")
let { mkIsControlDisabled } = require("%rGui/controls/disabledControls.nut")
let { mkGamepadShortcutImage, mkContinuousButtonParams } = require("%rGui/controls/shortcutSimpleComps.nut")
let { dfAnimBottomLeft } = require("%rGui/style/unitDelayAnims.nut")
let { eventbus_subscribe, send } = require("eventbus")
let { MechState, get_gears_current_state} = require("hudAircraftStates")
let { ON } = MechState
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isPieMenuActive } = require("%rGui/hud/pieMenu.nut")

let maxThrottle = 100
let stepThrottle = 5
let wepAxisValue = 1.1 
let sliderWepValue = -3 * stepThrottle
let sliderValue = Watched(maxThrottle)
let throttleAxisUpdateTick = 0.05
let maxThrottleChangeSpeed = 50
let throttleDeadZone = 0.7
let throttlePerTick = throttleAxisUpdateTick * maxThrottleChangeSpeed

let redColor = 0xFFFF5A52
let neutralColor = 0xFFFFFFFF

let brakeBtnSize = [hdpx(90), hdpx(54)]

function getSizes(scale) {
  let height = hdpxi(270 * scale)
  let scaleWidth = evenPx(18 * scale)
  let knobSize = 3 * scaleWidth
  let sliderPadding = 2 * scaleWidth
  return {
    scale
    height
    scaleWidth
    knobSize
    knobPadding = scaleWidth
    sliderPadding
    fullWidth = knobSize + 2 * sliderPadding
    throttleScaleHeight = height - knobSize
    lineWidth = hdpx(5 * scale)
  }
}

let idleTimeForThrottleOpacity = 5
let needOpacityThrottle = Watched(false)
let makeOpacityThrottle = @() needOpacityThrottle(true)
let showModelName = Watched(false)
let SHOW_MODEL_NAME_TIMEOUT = 7.0
let isThrottleDisabled = mkIsControlDisabled("throttle")

let throttleAxisVal = Watched(0)
let isThrottleAxisActive = keepref(Computed(@() fabs(throttleAxisVal.value) > throttleDeadZone))

let knobColor = Color(230, 230, 230, 230)

let sliderToThrottleAxisValue = @(sliderV) sliderV >= stepThrottle ? (maxThrottle - sliderV).tofloat() / maxThrottle
  : sliderV > sliderWepValue ? 1.0
  : wepAxisValue
let throttleToSlider = @(trt) trt > maxThrottle ? sliderWepValue 
  : maxThrottle - trt

let throttleScale = @(scaleWidth, throttleScaleHeight, knobSize, lineWidth) {
  size = [3 * scaleWidth, throttleScaleHeight]
  pos = [-knobSize, 0]
  padding = [throttleScaleHeight * (-sliderWepValue) / (maxThrottle - sliderWepValue), 0, 0, 0]
  children = {
    size = flex()
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth
    commands = [
      [VECTOR_LINE, 0, 0, 100, 0],
      [VECTOR_LINE, 50, 10, 100,  10],
      [VECTOR_LINE, 55, 20, 100,  20],
      [VECTOR_LINE, 60, 30, 100,  30],
      [VECTOR_LINE, 65, 40, 100,  40],
      [VECTOR_LINE, 50, 50, 100,  50],
      [VECTOR_LINE, 80, 60, 100,  60],
      [VECTOR_LINE, 85, 70, 100,  70],
      [VECTOR_LINE, 90, 80, 100,  80],
      [VECTOR_LINE, 95, 90, 100,   90],
    ]
  }
}

let throttleBgrImage = Picture("!ui/gameuiskin#hud_plane_slider.avif")
let maxThrottleText = loc("HUD/CRUISE_CONTROL_MAX_SHORT")
let wepText = loc("HUD/WEP_SHORT")
let percentText = loc("measureUnits/percent")

let HAPT_THROTTLE = registerHapticPattern("ThrottleChange", { time = 0.0, intensity = 0.5, sharpness = 0.4, duration = 0.2, attack = 0.08, release = 1.0 })

let throttleHitThreshold = 90
let throttleHintMaxCount = 5
let throttleHintDelay = 20
let throttleHintCount = Watched(0)

isInBattle.subscribe(@(_) throttleHintCount(0))

function showIncreaseThrottleHint() {
  send("hint:air_increase_throttle", {})
  throttleHintCount(throttleHintCount.value + 1)
  if (throttleHintCount.value < throttleHintMaxCount)
    resetTimeout(throttleHintDelay, showIncreaseThrottleHint)
}

function changeThrottleValue(val) {
  val = clamp(val, sliderWepValue, maxThrottle)
  needOpacityThrottle(false)
  resetTimeout(idleTimeForThrottleOpacity, makeOpacityThrottle)

  let axisVal = sliderToThrottleAxisValue(val).tofloat()
  if (axisVal < wepAxisValue)
    setShortcutOff("throttle_rangeMax")
  setAxisValue("throttle", axisVal)
  setVirtualAxisValue("throttle", axisVal <= 0 ? -1 : 0)
  if (axisVal >= wepAxisValue)
    setShortcutOn("throttle_rangeMax")
  sliderValue(val)
  playHapticPattern(HAPT_THROTTLE)
  if (throttleHintCount.value < throttleHintMaxCount && maxThrottle - val < throttleHitThreshold)
    resetTimeout(throttleHintDelay, showIncreaseThrottleHint)
  else
    clearTimer(showIncreaseThrottleHint)
}

function mkGamepadHotkey(hotkey, isVisible, isActive, ovr) {
  let imageComp = mkBtnImageComp(hotkey, hdpxi(50))
  return @() {
    watch = [isVisible, isGamepad, isActive]
    key = imageComp
    children = isVisible.value && isGamepad.get() ? imageComp : null
    transform = { scale = isActive.value ? [0.8, 0.8] : [1.0, 1.0] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }.__update(ovr)
}

let btnImageThrottleInc = mkGamepadHotkey(axisMinToHotkey(throttle_axis),
  Computed(@() sliderValue.value > sliderWepValue),
  Computed(@() isThrottleAxisActive.value && throttleAxisVal.value > 0),
  { hplace = ALIGN_RIGHT, pos = [pw(90), 0] })
let btnImageThrottleDec = mkGamepadHotkey(axisMaxToHotkey(throttle_axis),
  Computed(@() sliderValue.value < maxThrottle),
  Computed(@() isThrottleAxisActive.value && throttleAxisVal.value < 0),
  { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM, pos = [pw(90), 0] })

let isStateVisible = @(state) state == ON

let isOnGroundSmoothed = Watched(IsOnGround.get())
let setIsOnGroundSmoothed = @() isOnGroundSmoothed.set(IsOnGround.get())
IsOnGround.subscribe(function(v) {
  if (!isStateVisible(get_gears_current_state())) {
    isOnGroundSmoothed.set(false)
    return
  }
  if (v)
    setIsOnGroundSmoothed()
  else
    resetTimeout(1.0, setIsOnGroundSmoothed)
})

let brakeBtnText = @(scale) {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = loc("HUD/BRAKE_SHORT")
}.__update(getScaledFont(fontTiny, scale))

function brakeButtonImpl(scale) {
  local wasBrakeOnTouchBegin = false

  function onTouchBegin() {
    setShortcutOn("ID_WHEEL_BRAKE")
    wasBrakeOnTouchBegin = wheelBrake.get()
  }

  function onTouchEnd() {
    if (wasBrakeOnTouchBegin)
      setShortcutOff("ID_WHEEL_BRAKE")
  }

  let res = mkContinuousButtonParams(onTouchBegin, onTouchEnd , "ID_WHEEL_BRAKE")
  return res.__update({
    size = scaleArr(brakeBtnSize, scale)
    children = [
      @() {
        watch = wheelBrake
        size = flex()
        rendObj = ROBJ_SOLID
        color =  wheelBrake.get() ? btnBgColor.ready : btnBgColor.empty
      }
      {
        size = flex()
        rendObj = ROBJ_VECTOR_CANVAS
        lineWidth = hdpxi(2 * scale)
        commands = [
          [VECTOR_LINE, 0, 0, 100, 0],
          [VECTOR_LINE, 100, 0, 100, 100],
          [VECTOR_LINE, 100, 100, 0, 100],
          [VECTOR_LINE, 0, 100, 0, 0],
        ]
        color = borderColor
        children = brakeBtnText(scale)
      }
    ]
  })
}

let brakeButton = @(scale) @() {
  watch = isOnGroundSmoothed
  children = isOnGroundSmoothed.get() ? brakeButtonImpl(scale) : null
}

let brakeButtonEditView = {
  size = brakeBtnSize
  rendObj = ROBJ_BOX
  borderWidth = hdpx(2)
  borderColor
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = btnBgColor.empty
    }
    brakeBtnText(1)
  ]
}

let throttleSlider = kwarg(@(height, scaleWidth, knobSize, knobPadding, sliderPadding, fullWidth,
  throttleScaleHeight, lineWidth, scale
) function() {
  let sliderV = sliderValue.get()
  let knobPos = sliderV <= sliderWepValue ? 0
    : ((clamp(sliderV, 0, maxThrottle) - sliderWepValue).tofloat()
        / (maxThrottle - sliderWepValue) * throttleScaleHeight).tointeger()
  let knob = {
    size  = [knobSize + 2 * knobPadding, knobSize + 2 * knobPadding]
    hplace = ALIGN_CENTER
    padding = knobPadding
    children = [
      {
        pos = [0, knobPos - knobPadding]
        size  = [knobSize, knobSize]
        fillColor = knobColor
        color = knobColor
        rendObj = ROBJ_VECTOR_CANVAS
        commands = [
          [VECTOR_ELLIPSE, 50, 50, 50, 50]
        ]
      },
      @() {
        watch = [Trt0, IsTrtWep0, wheelBrake, isOnGroundSmoothed]
        key = "air_throttle_slider_text"
        rendObj = ROBJ_TEXT
        pos = [-1.1 * knobSize, pw(-80)]
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        color = IsTrtWep0.get() && !wheelBrake.get() ? 0xFFFF0000 : knobColor
        text = wheelBrake.get() && isOnGroundSmoothed.get() ? loc("hotkeys/ID_WHEEL_BRAKE")
          : IsTrtWep0.get() ? wepText
          : Trt0.get() >= maxThrottle ? maxThrottleText
          : $"{Trt0.get()}{percentText}"
      }.__update(getScaledFont(wheelBrake.get() && isOnGroundSmoothed.get() ? fontVeryTinyShaded : fontTinyShaded, scale))
    ]
  }
  return {
    watch = [ sliderValue, needOpacityThrottle, isThrottleDisabled]
    key = "air_throttle_slider"
    size = [fullWidth, height]
    padding = [0, sliderPadding]
    behavior = Behaviors.Slider
    fValue = sliderV
    knob = knob
    min = sliderWepValue
    max = maxThrottle
    unit = stepThrottle
    orientation = O_VERTICAL
    opacity = isThrottleDisabled.get() ? 0.2
      : needOpacityThrottle.value ? 0.5
      : 1.0

    transitions = [{ prop = AnimProp.opacity, duration = 0.5, easing = Linear }]
    children = [
      {
        size = [scaleWidth, throttleScaleHeight + scaleWidth]
        pos =  [scaleWidth, 0]
        padding = [scaleWidth / 2, 0]
        vplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        image = throttleBgrImage
        children = [
          throttleScale(scaleWidth, throttleScaleHeight, knobSize, lineWidth)
          @() {
            watch = Trt0
            rendObj = ROBJ_MASK
            size = [knobSize, throttleScaleHeight]
            pos = [-knobSize, 0]
            image = getSvgImage("hud_plane_gradient_left", knobSize, throttleScaleHeight)
            children = {
              rendObj = ROBJ_SOLID
              size = flex()
              transform = {
                pivot = [1, 1],
                scale = [1,
                  (Trt0.get() <= maxThrottle ? Trt0.get().tofloat()
                      : lerp(1.0, wepAxisValue, maxThrottle, maxThrottle - sliderWepValue, Trt0.get().tofloat() / maxThrottle))
                    / (maxThrottle - sliderWepValue)
                ]
              }
              transitions = [{ prop = AnimProp.scale, duration = 0.5, easing = InOutQuad }]
            }
          }
        ]
      }
      knob
      btnImageThrottleInc
      btnImageThrottleDec
    ]
    function onAttach() {
      resetTimeout(0.1, @() sliderValue(throttleToSlider(Trt0.get())))
      needOpacityThrottle(true)
    }
    onChange = !isThrottleDisabled.get() ? changeThrottleValue : null
  }
})

eventbus_subscribe("throttleFromMission", function(msg) {
  sliderValue(throttleToSlider(msg.value * 100))
  if (msg.value > wepAxisValue)
    setShortcutOn("throttle_rangeMax")
  else
    setShortcutOff("throttle_rangeMax")
})

let throttleAxisUpdate = @()
  changeThrottleValue(sliderValue.get() < 0 && throttleAxisVal.get() < 0 ? 0
    : sliderValue.get() - throttlePerTick * throttleAxisVal.get())

isThrottleAxisActive.subscribe(function(isActive) {
  clearTimer(throttleAxisUpdate)
  if (isActive) {
    setInterval(throttleAxisUpdateTick, throttleAxisUpdate)
    throttleAxisUpdate()
  }
})

isRespawnStarted.subscribe(@(v) v ? setVirtualAxisValue("throttle", 0) : null)

let setThrottleAxisVal = @(v) isThrottleDisabled.get() ? null : throttleAxisVal.set(v)

let gamepadMouseAimAxisListener = axisListener({
  [ailerons] = @(v) setVirtualAxisValue("ailerons", v),
  [throttle_axis] = @(v) setThrottleAxisVal(v),
  [mouse_aim_x] = @(v) setVirtualAxisValue("mouse_aim_x", v),
  [mouse_aim_y] = @(v) setVirtualAxisValue("mouse_aim_y", v)
})

let gamepadAxisListener = axisListener({
 [ailerons] = @(v) setVirtualAxisValue("ailerons", v),
 [elevator] = @(v) setVirtualAxisValue("elevator", v),
 [rudder] = @(v) setVirtualAxisValue("rudder", v),
 [throttle_axis] = @(v) setThrottleAxisVal(v),
})

let gamepadGunnerAxisListener = axisListener({
  [ailerons] = @(v) setVirtualAxisValue("ailerons", v),
  [throttle_axis] = @(v) setThrottleAxisVal(v),
  [turret_x] = @(v) setVirtualAxisValue("turret_x", v),
  [turret_y] = @(v) setVirtualAxisValue("turret_y", -v)
 })

local gravity0 = Point3(0.0, -1.0, 0.0)
local gravity = Point3(0.0, -1.0, 0.0)

local resetGravityLeft0 = false
local resetGravityForward0 = false
local resetGravityUp0 = false
function resetGravityAxesZero() {
  resetGravityLeft0 = true
  resetGravityForward0 = true
  resetGravityUp0 = true
  setVirtualAxisValue("ailerons", 0.0)
  setVirtualAxisValue("elevator", 0.0)
  setVirtualAxisValue("mouse_aim_x", 0.0)
  setVirtualAxisValue("mouse_aim_y", 0.0)
}
unitType.subscribe(@(_v) resetGravityAxesZero())
currentControlByGyroModeAileronsAssist.subscribe(@(_v) resetGravityAxesZero())
currentControlByGyroAimMode.subscribe(@(_v) resetGravityAxesZero())
currentControlByGyroDirectControl.subscribe(@(_v) resetGravityAxesZero())

function setVirtualAxesAileronsEelvatorAssistValueFromGravity(_aileronsDeadZone, aileronsSensitivity, _elevatorDeadZone, _elevatorSensitivity) {
  setVirtualAxesAileronsElevatorValue(aileronsSensitivity, true, false, gravity0.z, gravity0.x, gravity0.y, gravity.z, gravity.x, gravity.y)
}

function setVirtualAxesAimValuesFromGravity(aileronsDeadZone, aileronsSensitivity, elevatorDeadZone, elevatorSensitivity) {
  if (setVirtualAxesAim != null)
    setVirtualAxesAim(gravity0, gravity, aileronsDeadZone, aileronsSensitivity, elevatorDeadZone, elevatorSensitivity)
}

function setVirtualAxesAileronsAssistValueFromGravity(aileronsDeadZone, aileronsSensitivity, _elevatorDeadZone, _elevatorSensitivity) {
  if (setVirtualAxesAileronsAssist != null)
    setVirtualAxesAileronsAssist(gravity0, gravity, aileronsDeadZone, aileronsSensitivity)
}

function setVirtualAxesDirectControlValuesFromGravity(aileronsDeadZone, aileronsSensitivity, elevatorDeadZone, elevatorSensitivity) {
  if (setVirtualAxesDirectControl != null)
    setVirtualAxesDirectControl(gravity0, gravity, aileronsDeadZone, aileronsSensitivity, elevatorDeadZone, elevatorSensitivity)
}

function applyGravityLeft(val, setAxesFunc, aileronsDeadZone, aileronsSensitivity, elevatorDeadZone, elevatorSensitivity) {
  if (resetGravityLeft0) {
    gravity0.z = val
    resetGravityLeft0 = false
  }
  gravity.z = val
  setAxesFunc(aileronsDeadZone, aileronsSensitivity, elevatorDeadZone, elevatorSensitivity)
}

function applyGravityForward(val, setAxesFunc, aileronsDeadZone, aileronsSensitivity, elevatorDeadZone, elevatorSensitivity) {
  if (resetGravityForward0) {
    gravity0.x = val
    resetGravityForward0 = false
  }
  gravity.x = val
  setAxesFunc(aileronsDeadZone, aileronsSensitivity, elevatorDeadZone, elevatorSensitivity)
}

function applyGravityUp(val, setAxesFunc, aileronsDeadZone, aileronsSensitivity, elevatorDeadZone, elevatorSensitivity) {
  if (resetGravityUp0) {
    gravity0.y = val
    resetGravityUp0 = false
  }
  gravity.y = val
  setAxesFunc(aileronsDeadZone, aileronsSensitivity, elevatorDeadZone, elevatorSensitivity)
}

function makeGravityListenerMap(setAxesFunc) {
  return {
    [shortcutsMap.imuAxes.gravityLeft]    = @(v) applyGravityLeft   ( v, setAxesFunc,
      currentControlByGyroModeAileronsDeadZone.value, currentControlByGyroModeAileronsSensitivity.value,
      currentControlByGyroModeElevatorDeadZone.value, currentControlByGyroModeElevatorSensitivity.value),
    [shortcutsMap.imuAxes.gravityForward] = @(v) applyGravityForward(-v, setAxesFunc,
      currentControlByGyroModeAileronsDeadZone.value, currentControlByGyroModeAileronsSensitivity.value,
      currentControlByGyroModeElevatorDeadZone.value, currentControlByGyroModeElevatorSensitivity.value),
    [shortcutsMap.imuAxes.gravityUp]      = @(v) applyGravityUp     (-v, setAxesFunc,
      currentControlByGyroModeAileronsDeadZone.value, currentControlByGyroModeAileronsSensitivity.value,
      currentControlByGyroModeElevatorDeadZone.value, currentControlByGyroModeElevatorSensitivity.value)
  }
}

let imuAxesListenerAleronsElevatorAssist = axisListener( makeGravityListenerMap(setVirtualAxesAileronsEelvatorAssistValueFromGravity) )
let imuAxesListenerAim = axisListener( makeGravityListenerMap(setVirtualAxesAimValuesFromGravity) )
let imuAxesListenerAleronsAssist = axisListener( makeGravityListenerMap(setVirtualAxesAileronsAssistValueFromGravity) )
let imuAxesListenerDirectControl = axisListener( makeGravityListenerMap(setVirtualAxesDirectControlValuesFromGravity) )

let stickZoneSize = hdpx(280)
let bgRadius = hdpx(140)
let imgBgSize = 2 * bgRadius
let stickSize = hdpx(100)

let imgBg = @(size) {
  size = [size, size]
  image = Picture($"ui/gameuiskin#hud_tank_stick_bg.svg:{size}:{size}:P")
  rendObj = ROBJ_IMAGE
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  color = borderColor
}

let mkImgBgComp = @(scale) {
  size = flex()
  opacity = 0.5
  children = imgBg(scaleEven(imgBgSize, scale))
  transform = {}
}

function mkImgStick(scale) {
  let size = scaleEven(stickSize, scale)
  return {
    size = [size, size]
    image = Picture($"ui/gameuiskin#joy_head.svg:{size}:{size}:P")
    rendObj = ROBJ_IMAGE
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    transform = {}
  }
}

function aircraftMoveStickBase(scale) {
  let imgStick = mkImgStick(scale)
  let imgBgComp = mkImgBgComp(scale)
  let maxValueRadius = scaleEven(bgRadius, scale)
  return @() {
    watch = currentAircraftCtrlType
    key = currentAircraftCtrlType
    behavior = TouchScreenSteeringStick
    size = flex()
    touchStickAction = {
      horizontal = "ailerons"
      vertical = "elevator"
    }
    isForAircraft = true
    invertedX=true
    maxValueRadius
    useCenteringOnTouchBegin = currentAircraftCtrlType.value == "stick"

    function onAttach() {
      set_mouse_aim(false)
    }
    function onDetach() {
      setVirtualAxisValue("elevator", 0)
      setVirtualAxisValue("ailerons", 0)
      if (!isInBattle.get())
        set_mouse_aim(true)
    }
    children = [
      imgBgComp
      imgStick
    ]
  }
}

let aircraftMoveStick = @(scale) @() {
  watch = currentAircraftCtrlType
  size = array(2, scaleEven(stickZoneSize, scale))
  children = currentAircraftCtrlType.value == "stick" || currentAircraftCtrlType.value == "stick_static"
    ? aircraftMoveStickBase(scale)
    : null
}

function aircraftMoveSecondaryStickBase(scale) {
  let imgStick = mkImgStick(scale)
  let imgBgComp = mkImgBgComp(scale)
  let maxValueRadius = scaleEven(bgRadius, scale)
  return @() {
    watch = currentAircraftCtrlType
    key = currentAircraftCtrlType
    size = flex()
    behavior = TouchScreenSteeringStick
    touchStickAction = {
      horizontal = "rudder"
      vertical = "throttle"
    }
    isForAircraft = true
    invertedX=true
    maxValueRadius
    useCenteringOnTouchBegin = currentAircraftCtrlType.value == "stick"

    function onAttach() {
      set_mouse_aim(false)
    }
    function onDetach() {
      setVirtualAxisValue("rudder", 0)
      setVirtualAxisValue("throttle", 0)
      if (!isInBattle.get())
        set_mouse_aim(true)
    }
    children = [
      imgBgComp
      imgStick
    ]
  }
}

function aircraftMoveRudderStickBase(scale) {
  let imgStick = mkImgStick(scale)
  let imgBgComp = mkImgBgComp(scale)
  let maxValueRadius = scaleEven(bgRadius, scale)
  return @() {
    watch = currentAircraftCtrlType
    key = currentAircraftCtrlType
    size = flex()
    behavior = TouchScreenSteeringStick
    touchStickAction = {
      horizontal = "rudder"
      vertical = "climb"
    }
    isForAircraft = true
    invertedX=true
    maxValueRadius
    useCenteringOnTouchBegin = currentAircraftCtrlType.value == "stick"

    function onAttach() {
      set_mouse_aim(false)
    }
    function onDetach() {
      setVirtualAxisValue("rudder", 0)
      setVirtualAxisValue("climb", 0)
      if (!isInBattle.get())
        set_mouse_aim(true)
    }
    children = [
      imgBgComp
      imgStick
    ]
  }
}

let aircraftMoveSecondaryStick = @(scale) @() {
  watch = [currentAircraftCtrlType, currentThrottleStick]
  size = array(2, scaleEven(stickZoneSize, scale))
  children = currentAircraftCtrlType.get() != "stick" && currentAircraftCtrlType.get() != "stick_static" ? null
    : currentThrottleStick.get() ? aircraftMoveSecondaryStickBase(scale)
    : aircraftMoveRudderStickBase(scale)
}

let aircraftMoveStickView = {
  size = [stickZoneSize, stickZoneSize]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    mkImgBgComp(1)
    mkImgStick(1)
  ]
}

function mkGamepadAxisListener() {
  if (isActiveTurretCamera.get())
    return gamepadGunnerAxisListener
  if (currentAircraftCtrlType.value == "mouse_aim")
    return gamepadMouseAimAxisListener
  return gamepadAxisListener
}

function getImuAxesListener(controlType, gyroAimMode, aileronsAssistMode, directControlMode) {
  if (controlType == "mouse_aim") {
    if (setVirtualAxesAim != null) {
      if (gyroAimMode == "aim")
        return imuAxesListenerAim
      else if (gyroAimMode == "aileron_assist")
        return imuAxesListenerAleronsAssist
      else
        return null
    }
    else
      return aileronsAssistMode ? imuAxesListenerAleronsElevatorAssist : null
  }
  else
    return directControlMode ? imuAxesListenerDirectControl : null
}

let aircraftMovement = @(scale) {
  children = [
    throttleSlider(getSizes(scale))
    @() {
      watch = [ currentAircraftCtrlType, currentControlByGyroModeAileronsAssist, currentControlByGyroAimMode, currentControlByGyroDirectControl,
        currentControlByGyroModeAileronsDeadZone, currentControlByGyroModeAileronsSensitivity, isGamepad, isPieMenuActive]
      children = [
        getImuAxesListener(currentAircraftCtrlType.value, currentControlByGyroAimMode.value, currentControlByGyroModeAileronsAssist.value, currentControlByGyroDirectControl.value),
        isGamepad.get() && !isPieMenuActive.get() ? mkGamepadAxisListener() : null
      ]
    }
  ]
}

function mkEditView() {
  let { fullWidth, height, sliderPadding, scaleWidth, throttleScaleHeight, knobSize, lineWidth
  } = getSizes(1)
  return {
    size = [fullWidth, height]
    padding = [0, sliderPadding]
    children = [
      {
        size = [scaleWidth, throttleScaleHeight]
        pos =  [scaleWidth, 0]
        vplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        image = throttleBgrImage
        children = [
          throttleScale(scaleWidth, throttleScaleHeight, knobSize, lineWidth)
          {
            rendObj = ROBJ_MASK
            size = [knobSize, throttleScaleHeight]
            pos = [scaleWidth, 0]
            image = getSvgImage("hud_plane_gradient", knobSize, throttleScaleHeight)
            children = {
              rendObj = ROBJ_SOLID
              size = flex()
            }
          }
        ]
      }
    ]
  }
}

let aircraftMovementEditView = mkEditView()

let showModelNameOff = @() showModelName(false)

playerUnitName.subscribe(function(_) {
  if (unitType.value != AIR) {
    showModelName(false)
    return
  }
  showModelName(true)
  resetTimeout(SHOW_MODEL_NAME_TIMEOUT, showModelNameOff)
})
resetTimeout(SHOW_MODEL_NAME_TIMEOUT, showModelNameOff)

let txtSpeedLabel = loc("HUD/REAL_SPEED_SHORT")
let txtSpeedUnits = loc("measureUnits/kmh")
let txtAltitudeLabel = loc("HUD/ALTITUDE_SHORT")
let txtAltitudeUnits = loc("measureUnits/meters_alt")

let altitudeMeters = Computed(@() DistanceToGround.get().tointeger())

function aircraftIndicators(scale) {
  let font = prettyScaleForSmallNumberCharVariants(fontTinyAccentedShaded, scale)
  let fontMono = prettyScaleForSmallNumberCharVariants(fontMonoTinyAccentedShaded, scale)
  return {
    size = [hdpx(250 * scale), hdpx(150 * scale)]
    valign = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    gap = hdpx(5 * scale)
    children = [
      @() !showModelName.value ? { watch = showModelName }
      : {
          watch = [showModelName, playerUnitName]
          rendObj = ROBJ_TEXT
          color = neutralColor
          text = loc($"{playerUnitName.value}_1", loc(playerUnitName.value))
        }.__update(font)
      @() {
        watch = IsSpdCritical
        key = "plane_speed_indicator"
        flow = FLOW_HORIZONTAL
        gap = hdpx(8 * scale)
        children = [
          {
            rendObj = ROBJ_TEXT
            color = IsSpdCritical.get() ? redColor : neutralColor
            text = txtSpeedLabel
          }.__update(font)
          @() {
            watch = Spd
            rendObj = ROBJ_TEXT
            color = IsSpdCritical.get() ? redColor : neutralColor
            text = Spd.get()
          }.__update(fontMono)
          {
            rendObj = ROBJ_TEXT
            color = IsSpdCritical.get() ? redColor : neutralColor
            text = txtSpeedUnits
          }.__update(font)
        ]
      }
      {
        key = "plane_altitude_indicator"
        flow = FLOW_HORIZONTAL
        gap = hdpx(8 * scale)
        children = [
          {
            rendObj = ROBJ_TEXT
            text = txtAltitudeLabel
          }.__update(font)
          @() {
            watch = altitudeMeters
            rendObj = ROBJ_TEXT
            text = altitudeMeters.get()
          }.__update(fontMono)
          {
            rendObj = ROBJ_TEXT
            text = txtAltitudeUnits
          }.__update(font)
        ]
      }
    ]
  }
}

let aircraftIndicatorsEditView = {
  size = const [hdpx(250), hdpx(150)]
  valign = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = hdpx(5)
  children = [
    {
      rendObj = ROBJ_TEXT
      color = neutralColor
      text = loc("hud/aircraft_name")
    }.__update(fontTinyAccentedShaded)
    {
      rendObj = ROBJ_TEXT
      color = neutralColor
      text = " ".concat(loc("HUD/REAL_SPEED_SHORT"), "xxx", loc("measureUnits/kmh"))
    }.__update(fontTinyAccentedShaded)
    {
      rendObj = ROBJ_TEXT
      text = " ".concat(loc("HUD/ALTITUDE_SHORT"), "xxxx", loc("measureUnits/meters_alt"))
    }.__update(fontTinyAccentedShaded)
  ]
}

let outlineColor = Watched(0x4D4D4D4D)
let isAircraftMoveArrowsAvailable = Computed(@() currentAdditionalFlyControls.value)
let toInt = @(list) list.map(@(v) v.tointeger())
let horSize = toInt([shHud(9), shHud(12)])
let verSizeBase = toInt([shHud(12), shHud(10)])

let mkVerticalArrow = @(id, isControlDisabled, verSize, upDirection) mkMoveVertBtn(
  function onTouchBegin() {
    setShortcutOn(id)
  },
  @() setShortcutOff(id),
  id,
  {
    size = verSize
    key = id
    flipY = upDirection
    children = @() {
      watch = isControlDisabled
      children = isControlDisabled.value ? null
        : [
            mkMoveVertBtnCorner(upDirection, Watched(0xFFFFFFFF), verSize)
            mkMoveVertBtnOutline(upDirection, verSize, outlineColor)
            mkGamepadShortcutImage(id, { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [0, ph(50)] }, verSize)
          ]
    }
  })

let mkHorizontalMovementParams = @(id, disableId, scale) {
  scale
  ovr = { key = id, size = horSize }
  shortcutId = id
  outlineColor
  function onTouchBegin() {
    setShortcutOn(id)
  }
  onTouchEnd = @() setShortcutOff(id)
  isDisabled = mkIsControlDisabled(disableId)
}

function aircraftMoveArrows(scale) {
  let vertical = "elevator"
  let horizontal = "ailerons"
  let vertical_max = $"{vertical}_rangeMax"
  let vertical_min = $"{vertical}_rangeMin"

  let leftArrow = mkMoveLeftBtn(mkHorizontalMovementParams($"{horizontal}_rangeMin", horizontal, scale))
  let rightArrow = mkMoveRightBtn(mkHorizontalMovementParams($"{horizontal}_rangeMax", horizontal, scale))

  let isControlDisabled = mkIsControlDisabled(vertical)
  let verSize = scaleArr(verSizeBase, scale)
  let vertArrows = [
    mkVerticalArrow(vertical_min, isControlDisabled, verSize, false)
    mkVerticalArrow(vertical_max, isControlDisabled, verSize, true)
  ]

  return @() {
    watch = [isUnitDelayed, isGamepad]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    children = [
          leftArrow
          {
            flow = FLOW_VERTICAL
            halign = ALIGN_CENTER
            children = vertArrows
          }
          rightArrow
          isGamepad.get() ? gamepadMouseAimAxisListener : null
        ]
    animations = dfAnimBottomLeft
  }
}

return {
  aircraftMovement
  aircraftIndicators
  aircraftMovementEditView
  aircraftIndicatorsEditView
  aircraftMoveStick
  aircraftMoveSecondaryStick
  aircraftMoveStickView
  aircraftMoveArrows
  brakeButton
  brakeButtonEditView
  isAircraftMoveArrowsAvailable
  resetGravityAxesZero
}
