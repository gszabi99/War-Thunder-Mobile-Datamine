from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer, setInterval } = require("dagor.workcycle")
let { floor, fabs, lerp } = require("%sqstd/math.nut")
let { setAxisValue,  setShortcutOn, setShortcutOff, setVirtualAxisValue
} = require("%globalScripts/controls/shortcutActions.nut")
let { Trt0, IsTrtWep0, Spd, DistanceToGround, IsSpdCritical, IsOnGround } = require("%rGui/hud/airState.nut")
let { getSvgImage } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { registerHapticPattern, playHapticPattern } = require("hapticVibration")
let axisListener = require("%rGui/controls/axisListener.nut")
let { ailerons, mouse_aim_x, mouse_aim_y, throttle_axis
} = require("%rGui/controls/shortcutsMap.nut").gamepadAxes
let { axisMinToHotkey, axisMaxToHotkey } = require("%rGui/controls/axisToHotkey.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { mkBtnImageComp } = require("%rGui/controlsMenu/gamepadImgByKey.nut")
let { playerUnitName, unitType } = require("%rGui/hudState.nut")
let { AIR } = require("%appGlobals/unitConst.nut")
let { isRespawnStarted } = require("%appGlobals/clientState/respawnStateBase.nut")

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

let idleTimeForThrottleOpacity = 5
let needOpacityThrottle = Watched(false)
let makeOpacityThrottle = @() needOpacityThrottle(true)
let showModelName = Watched(false)
let SHOW_MODEL_NAME_TIMEOUT = 7.0

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

function throttleSlider() {
  let sliderV = sliderValue.get()
  let knobPos = sliderV <= sliderWepValue ? 0
    : ((clamp(sliderV, 0, maxThrottle) - sliderWepValue).tofloat()
        / (maxThrottle - sliderWepValue) * throttleScaleHeight).tointeger()
  let knob = {
    size  = [knobSize + 2 * knobPadding, knobSize + 2 * knobPadding]
    pos = [0, knobPos - knobPadding]
    hplace = ALIGN_CENTER
    padding = knobPadding
    children = [
      {
        size  = [knobSize, knobSize]
        fillColor = knobColor
        color = knobColor
        rendObj = ROBJ_VECTOR_CANVAS
        commands = [
          [VECTOR_ELLIPSE, 50, 50, 50, 50]
        ]
      },
      @() {
        watch = [Trt0, IsTrtWep0, IsOnGround]
        rendObj = ROBJ_TEXT
        pos = [knobSize + hdpx(5), 0]
        fontFxColor = 0xFF000000
        color = IsTrtWep0.get() ? 0xFFFF0000 : knobColor
        fontFxFactor = 50
        fontFx = FFT_GLOW
        text = IsTrtWep0.get() ? wepText
          : Trt0.get() >= maxThrottle ? maxThrottleText
          : IsOnGround.get() && Trt0.get() == 0 ? loc("hotkeys/ID_WHEEL_BRAKE")
          : $"{Trt0.get()}{percentText}"
      }.__update(IsOnGround.get() && Trt0.get() == 0 ? fontVeryTiny : fontTiny)
    ]
  }

  return {
    watch = [ sliderValue, needOpacityThrottle ]
    key = sliderValue
    size = [fullWidth, height]
    padding = [0, sliderPadding]
    behavior = Behaviors.Slider
    fValue = sliderV
    knob = knob
    min = sliderWepValue
    max = maxThrottle
    unit = stepThrottle
    orientation = O_VERTICAL
    opacity = needOpacityThrottle.value ? 0.5 : 1.0
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
    onChange = changeThrottleValue
  }
}

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

let gamepadAxisListener = axisListener({
  [ailerons] = @(v) setVirtualAxisValue("ailerons", v),
  [throttle_axis] = @(v) throttleAxisVal(v),
  [mouse_aim_x] = @(v) setVirtualAxisValue("mouse_aim_x", v),
  [mouse_aim_y] = @(v) setVirtualAxisValue("mouse_aim_y", v),
})

let aircraftMovement = {
  children = [
    throttleSlider
    @() {
      watch = isGamepad
      children = isGamepad.value ? gamepadAxisListener : null
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
        text = loc($"{playerUnitName.value}_1")
      }.__update(fontSmallAccented)
    @() {
      watch = [Spd, IsSpdCritical]
      rendObj = ROBJ_TEXT
      color = IsSpdCritical.value ? redColor : neutralColor
      text = " ".concat(loc("HUD/REAL_SPEED_SHORT"), Spd.value, loc("measureUnits/kmh"))
    }.__update(fontSmallAccented)
    @() {
      watch = DistanceToGround
      rendObj = ROBJ_TEXT
      text = " ".concat(loc("HUD/ALTITUDE_SHORT"), floor(DistanceToGround.value), loc("measureUnits/meters_alt"))
    }.__update(fontSmallAccented)
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
    }.__update(fontSmallAccented)
    {
      rendObj = ROBJ_TEXT
      color = neutralColor
      text = " ".concat(loc("HUD/REAL_SPEED_SHORT"), "xxx", loc("measureUnits/kmh"))
    }.__update(fontSmallAccented)
    {
      rendObj = ROBJ_TEXT
      text = " ".concat(loc("HUD/ALTITUDE_SHORT"), "xxxx", loc("measureUnits/meters_alt"))
    }.__update(fontSmallAccented)
  ]
}

return {
  aircraftMovement
  aircraftIndicators
  aircraftMovementEditView
  aircraftIndicatorsEditView
}
