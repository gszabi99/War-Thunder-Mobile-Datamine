from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer, setInterval } = require("dagor.workcycle")
let { TouchScreenSteeringStick } = require("wt.behaviors")
let { floor, fabs, lerp } = require("%sqstd/math.nut")
let { setAxisValue,  setShortcutOn, setShortcutOff, setVirtualAxisValue, setVirtualAxesAileronsElevatorValue
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
let { currentControlByGyroModeAilerons, currentControlByGyroModeDeadZone, currentControlByGyroModeSensitivity,
      currentAircraftCtrlType, currentAdditionalFlyControls } = require("%rGui/options/options/airControlsOptions.nut")
let { set_mouse_aim } = require("controlsOptions")
let { isRespawnStarted } = require("%appGlobals/clientState/respawnStateBase.nut")
let { mkMoveLeftBtn, mkMoveRightBtn, mkMoveVertBtn, mkMoveVertBtnOutline, mkMoveVertBtnCorner } = require("%rGui/components/movementArrows.nut")
let { mkIsControlDisabled } = require("%rGui/controls/disabledControls.nut")
let { mkGamepadShortcutImage, mkContinuousButtonParams } = require("%rGui/controls/shortcutSimpleComps.nut")
let { dfAnimBottomLeft } = require("%rGui/style/unitDelayAnims.nut")
let { eventbus_subscribe } = require("eventbus")
let { MechState, get_gears_current_state} = require("hudAircraftStates")
let { ON } = MechState


let maxThrottle = 100
let stepThrottle = 5
let wepAxisValue = 1.1 //same with native code
let sliderWepValue = -3 * stepThrottle
let sliderValue = Watched(maxThrottle)
let throttleAxisUpdateTick = 0.05
let maxThrottleChangeSpeed = 50
let throttleDeadZone = 0.7
let throttlePerTick = throttleAxisUpdateTick * maxThrottleChangeSpeed

let redColor = 0xFFFF5A52
let neutralColor = 0xFFFFFFFF

let height = hdpxi(270)
let scaleWidth = evenPx(18)
let knobSize = 3 * scaleWidth
let knobPadding = scaleWidth
let sliderPadding = 2 * scaleWidth
let fullWidth = knobSize + 2 * sliderPadding
let throttleScaleHeight = height - knobSize
let brakeBtnSize = [5 * scaleWidth, 3 * scaleWidth]

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
let throttleToSlider = @(trt) trt > maxThrottle ? sliderWepValue //wep
  : maxThrottle - trt

let throttleScale = {
  size = [3 * scaleWidth, throttleScaleHeight]
  pos = [1.2 * scaleWidth, 0]
  padding = [throttleScaleHeight * (-sliderWepValue) / (maxThrottle - sliderWepValue), 0, 0, 0]
  children = {
    size = flex()
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth = hdpx(5)
    commands = [
      [VECTOR_LINE, 0, 0,  100, 0],
      [VECTOR_LINE, 0, 10, 50,  10],
      [VECTOR_LINE, 0, 20, 45,  20],
      [VECTOR_LINE, 0, 30, 40,  30],
      [VECTOR_LINE, 0, 40, 35,  40],
      [VECTOR_LINE, 0, 50, 50,  50],
      [VECTOR_LINE, 0, 60, 20,  60],
      [VECTOR_LINE, 0, 70, 15,  70],
      [VECTOR_LINE, 0, 80, 10,  80],
      [VECTOR_LINE, 0, 90, 5,   90],
    ]
  }
}

let throttleBgrImage = Picture("!ui/gameuiskin#hud_plane_slider.avif")
let maxThrottleText = loc("HUD/CRUISE_CONTROL_MAX_SHORT")
let wepText = loc("HUD/WEP_SHORT")
let percentText = loc("measureUnits/percent")

let HAPT_THROTTLE = registerHapticPattern("ThrottleChange", { time = 0.0, intensity = 0.5, sharpness = 0.4, duration = 0.2, attack = 0.08, release = 1.0 })

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
}

function mkGamepadHotkey(hotkey, isVisible, isActive, ovr) {
  let imageComp = mkBtnImageComp(hotkey, hdpxi(50))
  return @() {
    watch = [isVisible, isGamepad, isActive]
    key = imageComp
    children = isVisible.value && isGamepad.value ? imageComp : null
    transform = { scale = isActive.value ? [0.8, 0.8] : [1.0, 1.0] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }.__update(ovr)
}

let btnImageThrottleInc = mkGamepadHotkey(axisMinToHotkey(throttle_axis),
  Computed(@() sliderValue.value > sliderWepValue),
  Computed(@() isThrottleAxisActive.value && throttleAxisVal.value > 0),
  { hplace = ALIGN_RIGHT, pos = [pw(-100), 0] })
let btnImageThrottleDec = mkGamepadHotkey(axisMaxToHotkey(throttle_axis),
  Computed(@() sliderValue.value < maxThrottle),
  Computed(@() isThrottleAxisActive.value && throttleAxisVal.value < 0),
  { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM, pos = [pw(-100), 0] })

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

let brakeBtnText = {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = loc("HUD/BRAKE_SHORT")
}.__update(fontTiny)

function brakeButton() {
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
  res.__update({
    size = brakeBtnSize
    children =[
      @() {
        watch = wheelBrake
        size = flex()
        rendObj = ROBJ_SOLID
        color =  wheelBrake.get() ? btnBgColor.ready : btnBgColor.empty
      }
      {
        size = flex()
        rendObj = ROBJ_VECTOR_CANVAS
        lineWidth = hdpxi(2)
        commands = [
          [VECTOR_LINE, 0, 0, 100, 0],
          [VECTOR_LINE, 100, 0, 100, 100],
          [VECTOR_LINE, 100, 100, 0, 100],
          [VECTOR_LINE, 0, 100, 0, 0],
        ]
        color = borderColor
        children = brakeBtnText
      }
  ]
  })
  return {
    watch = isOnGroundSmoothed
    children = isOnGroundSmoothed.get() ? res : null
  }
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
    brakeBtnText
  ]
}

function throttleSlider() {
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
        pos = [knobSize + hdpx(5), -knobPadding]
        fontFxColor = 0xFF000000
        color = IsTrtWep0.get() && !wheelBrake.get() ? 0xFFFF0000 : knobColor
        fontFxFactor = 50
        fontFx = FFT_GLOW
        text = wheelBrake.get() && isOnGroundSmoothed.get() ? loc("hotkeys/ID_WHEEL_BRAKE")
          : IsTrtWep0.get() ? wepText
          : Trt0.get() >= maxThrottle ? maxThrottleText
          : $"{Trt0.get()}{percentText}"
      }.__update(wheelBrake.get() && isOnGroundSmoothed.get() ? fontVeryTiny : fontTiny)
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
          throttleScale
          @() {
            watch = Trt0
            rendObj = ROBJ_MASK
            size = [knobSize, throttleScaleHeight]
            pos = [scaleWidth, 0]
            image = getSvgImage("hud_plane_gradient", knobSize, throttleScaleHeight)
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
}

eventbus_subscribe("throttleFromMission", function(msg) {
  sliderValue(throttleToSlider(msg.value * 100))
})

let throttleAxisUpdate = @()
  changeThrottleValue(sliderValue.get() < 0 && throttleAxisVal.get() < 0 ? 0
    : sliderValue.get() - throttlePerTick * throttleAxisVal.get())

isThrottleAxisActive.subscribe(function(isActive) {
  if (!isActive)
    clearTimer(throttleAxisUpdate)
  else {
    setInterval(throttleAxisUpdateTick, throttleAxisUpdate)
    throttleAxisUpdate()
  }
})

isRespawnStarted.subscribe(@(v) v ? setVirtualAxisValue("throttle", 0) : null)

let gamepadMouseAimAxisListener = axisListener({
  [ailerons] = @(v) setVirtualAxisValue("ailerons", v),
  [throttle_axis] = @(v) throttleAxisVal(v),
  [mouse_aim_x] = @(v) setVirtualAxisValue("mouse_aim_x", v),
  [mouse_aim_y] = @(v) setVirtualAxisValue("mouse_aim_y", v)
})

let gamepadAxisListener = axisListener({
 [ailerons] = @(v) setVirtualAxisValue("ailerons", v),
 [elevator] = @(v) setVirtualAxisValue("elevator", v),
 [rudder] = @(v) setVirtualAxisValue("rudder", v),
 [throttle_axis] = @(v) throttleAxisVal(v),
})

let gamepadGunnerAxisListener = axisListener({
  [ailerons] = @(v) setVirtualAxisValue("ailerons", v),
  [throttle_axis] = @(v) throttleAxisVal(v),
  [turret_x] = @(v) setVirtualAxisValue("turret_x", v),
  [turret_y] = @(v) setVirtualAxisValue("turret_y", -v)
 })

local resetGravityLeft0 = false
local resetGravityForward0 = false
local resetGravityUp0 = false
function resetAxesZero() {
  resetGravityLeft0 = true
  resetGravityForward0 = true
  resetGravityUp0 = true
  setVirtualAxisValue("ailerons", 0.0)
  setVirtualAxisValue("elevator", 0.0)
}
unitType.subscribe(@(_v) resetAxesZero())
currentControlByGyroModeAilerons.subscribe(@(_v) resetAxesZero())

local gravityLeft0 = 0.0
local gravityForward0 = 0.0
local gravityUp0 = -1.0

local gravityLeft = 0.0
local gravityForward = 0.0
local gravityUp = -1.0

function setVirtualAxesAileronsElevatorValueFromGravity(set_ailerons, sensitivity) {
  setVirtualAxesAileronsElevatorValue(sensitivity, set_ailerons, false, gravityLeft0, gravityForward0, gravityUp0, gravityLeft, gravityForward, gravityUp)
}

function applyGravityLeft(val, set_ailerons, sensitivity) {
  if (resetGravityLeft0) {
    gravityLeft0 = val
    resetGravityLeft0 = false
  }
  gravityLeft = val
  return setVirtualAxesAileronsElevatorValueFromGravity(set_ailerons, sensitivity)
}

function applyGravityForward(val, set_ailerons, sensitivity) {
  if (resetGravityForward0) {
    gravityForward0 = val
    resetGravityForward0 = false
  }
  gravityForward = val
  return setVirtualAxesAileronsElevatorValueFromGravity(set_ailerons, sensitivity)
}

function applyGravityUp(val, set_ailerons, sensitivity) {
  if (resetGravityUp0) {
    gravityUp0 = val
    resetGravityUp0 = false
  }
  gravityUp = val
  return setVirtualAxesAileronsElevatorValueFromGravity(set_ailerons, sensitivity)
}

let imuAxisListener = axisListener({
  [shortcutsMap.imuAxes.gravityLeft]    = @(v) applyGravityLeft   ( v, currentControlByGyroModeAilerons.value, currentControlByGyroModeSensitivity.value),
  [shortcutsMap.imuAxes.gravityForward] = @(v) applyGravityForward(-v, currentControlByGyroModeAilerons.value, currentControlByGyroModeSensitivity.value),
  [shortcutsMap.imuAxes.gravityUp]      = @(v) applyGravityUp     (-v, currentControlByGyroModeAilerons.value, currentControlByGyroModeSensitivity.value)
})

let stickZoneSize = [shHud(40), shHud(40)]
let bgRadius = shHud(15)
let imgBgSize = 2 * bgRadius
let stickSize = shHud(11)

let imgBg = {
  size = [imgBgSize, imgBgSize]
  image = Picture($"ui/gameuiskin#hud_tank_stick_bg.svg:{imgBgSize}:{imgBgSize}:P")
  rendObj = ROBJ_IMAGE
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  color = borderColor
}

let imgBgComp = @() {
  size = flex()
  opacity = 0.5
  children = imgBg
  transform = {}
}

let imgStick = {
  size = [stickSize, stickSize]
  image = Picture($"ui/gameuiskin#joy_head.svg:{stickSize}:{stickSize}:P")
  rendObj = ROBJ_IMAGE
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  transform = {}
}

let aircraftMoveStickBase  = @() {
  watch = currentAircraftCtrlType
  key = currentAircraftCtrlType
  behavior = TouchScreenSteeringStick
  size = stickZoneSize
  touchStickAction = {
    horizontal = "ailerons"
    vertical = "elevator"
  }
  isForAircraft = true
  invertedX=true
  maxValueRadius = bgRadius
  useCenteringOnTouchBegin = currentAircraftCtrlType.value == "stick"

  function onAttach() {
    set_mouse_aim(false)
  }
  function onDetach() {
    setVirtualAxisValue("elevator", 0)
    setVirtualAxisValue("ailerons", 0)
    set_mouse_aim(true)
  }
  children = [
    imgBgComp
    imgStick
  ]
}

let aircraftMoveStick = @() {
  watch = currentAircraftCtrlType
  size = stickZoneSize
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_LEFT
  children = currentAircraftCtrlType.value == "stick" || currentAircraftCtrlType.value == "stick_static" ? aircraftMoveStickBase : null
}

let aircraftMoveStickView = {
  size = stickZoneSize
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    imgBgComp
    imgStick
  ]
}

function mkGamepadAxisListener() {
  if (isActiveTurretCamera.get())
    return gamepadGunnerAxisListener
  if (currentAircraftCtrlType.value == "mouse_aim")
    return gamepadMouseAimAxisListener
  return gamepadAxisListener
}

let aircraftMovement = {
  children = [
    throttleSlider
    @() {
      watch = [ isGamepad, currentAircraftCtrlType, currentControlByGyroModeAilerons,
                currentControlByGyroModeDeadZone, currentControlByGyroModeSensitivity]
      children = [
        currentAircraftCtrlType.value == "mouse_aim" && currentControlByGyroModeAilerons.value ? imuAxisListener : null
        isGamepad.value ? mkGamepadAxisListener() : null
      ]
    }
  ]
}

let aircraftMovementEditView = {
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
        throttleScale
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

let aircraftIndicators = {
  size = [hdpx(250), hdpx(150)]
  valign = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = hdpx(5)
  children = [
    @() !showModelName.value ? { watch = showModelName }
    : {
        watch = [showModelName, playerUnitName]
        rendObj = ROBJ_TEXT
        color = neutralColor
        text = loc($"{playerUnitName.value}_1", loc(playerUnitName.value))
      }.__update(fontTinyAccented)
    @() {
      watch = [Spd, IsSpdCritical]
      key = "plane_speed_indicator"
      rendObj = ROBJ_TEXT
      color = IsSpdCritical.value ? redColor : neutralColor
      text = " ".concat(loc("HUD/REAL_SPEED_SHORT"), Spd.value, loc("measureUnits/kmh"))
    }.__update(fontTinyAccented)
    @() {
      watch = DistanceToGround
      key = "plane_altitude_indicator"
      rendObj = ROBJ_TEXT
      text = " ".concat(loc("HUD/ALTITUDE_SHORT"), floor(DistanceToGround.value), loc("measureUnits/meters_alt"))
    }.__update(fontTinyAccented)
  ]
}

let aircraftIndicatorsEditView = {
  size = [hdpx(250), hdpx(150)]
  valign = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = hdpx(5)
  children = [
    {
      rendObj = ROBJ_TEXT
      color = neutralColor
      text = loc("hud/aircraft_name")
    }.__update(fontTinyAccented)
    {
      rendObj = ROBJ_TEXT
      color = neutralColor
      text = " ".concat(loc("HUD/REAL_SPEED_SHORT"), "xxx", loc("measureUnits/kmh"))
    }.__update(fontTinyAccented)
    {
      rendObj = ROBJ_TEXT
      text = " ".concat(loc("HUD/ALTITUDE_SHORT"), "xxxx", loc("measureUnits/meters_alt"))
    }.__update(fontTinyAccented)
  ]
}

let outlineColor = Watched(0x4D4D4D4D)
let isAircraftMoveArrowsAvailable = Computed(@() currentAdditionalFlyControls.value)
let toInt = @(list) list.map(@(v) v.tointeger())
let horSize = toInt([shHud(9), shHud(12)])
let verSize = toInt([shHud(12), shHud(10)])

let mkVerticalArrow = @(id, isControlDisabled, upDirection) mkMoveVertBtn(
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
            mkMoveVertBtnOutline(upDirection, outlineColor, verSize)
            mkGamepadShortcutImage(id, { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [0, ph(50)] })
          ]
    }
  })

let mkHorizontalMovementParams = @(id, disableId) {
  ovr = { key = id, size = horSize }
  shortcutId = id
  outlineColor
  function onTouchBegin() {
    setShortcutOn(id)
  }
  onTouchEnd = @() setShortcutOff(id)
  isDisabled = mkIsControlDisabled(disableId)
}

function aircraftMoveArrows() {
  let vertical = "elevator"
  let horizontal = "ailerons"
  let vertical_max = $"{vertical}_rangeMax"
  let vertical_min = $"{vertical}_rangeMin"

  let leftArrow = mkMoveLeftBtn(mkHorizontalMovementParams($"{horizontal}_rangeMin", horizontal))
  let rightArrow = mkMoveRightBtn(mkHorizontalMovementParams($"{horizontal}_rangeMax", horizontal))

  let isControlDisabled = mkIsControlDisabled(vertical)

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
            children = [
              mkVerticalArrow(vertical_min, isControlDisabled, false)
              mkVerticalArrow(vertical_max, isControlDisabled, true)
            ]
          }
          rightArrow
          isGamepad.value ? gamepadMouseAimAxisListener : null
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
  aircraftMoveStickView
  aircraftMoveArrows
  brakeButton
  brakeButtonEditView
  isAircraftMoveArrowsAvailable
}
