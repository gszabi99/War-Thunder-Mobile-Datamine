from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer, setInterval } = require("dagor.workcycle")
let { floor, fabs } = require("%sqstd/math.nut")
let { setAxisValue,  setShortcutOn, setShortcutOff, setVirtualAxisValue
} = require("%globalScripts/controls/shortcutActions.nut")
let { Trt, TrtMode, Spd, DistanceToGround, IsSpdCritical } = require("%rGui/hud/airState.nut")
let { getSvgImage } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { registerHapticPattern, playHapticPattern } = require("hapticVibration")
let axisListener = require("%rGui/controls/axisListener.nut")
let { ailerons, mouse_aim_x, mouse_aim_y, throttle_axis
} = require("%rGui/controls/shortcutsMap.nut").gamepadAxes
let { axisMinToHotkey, axisMaxToHotkey } = require("%rGui/controls/axisToHotkey.nut")
let { isGamepad } = require("%rGui/activeControls.nut")
let { mkBtnImageComp } = require("%rGui/controlsMenu/gamepadImgByKey.nut")

let maxThrottle = 100.0
let stepThrottle = 5.0
let userTrottle = Watched(maxThrottle)
let throttleAxisUpdateTick = 0.05
let maxThrottleChangeSpeed = 50
let throttleDeadZone = 0.7
let throttlePerTick = throttleAxisUpdateTick * maxThrottleChangeSpeed

let redColor = 0xFFFF5A52
let neutralColor = 0xFFFFFFFF

let height = shHud(25)
let scaleWidth = (12.0 / 177.0 * height).tointeger()
let knobSize = 3 * scaleWidth
let knobPadding = scaleWidth
let sliderPadding = 2 * scaleWidth
let fullWidth = knobSize + 2 * sliderPadding
let throttleScaleHeight = height - knobSize

let idleTimeForThrottleOpacity = 5
let needOpacityThrottle = Watched(false)
let makeOpacityThrottle = @() needOpacityThrottle(true)

let throttleAxisVal = Watched(0)
let isThrottleAxisActive = keepref(Computed(@() fabs(throttleAxisVal.value) > throttleDeadZone))

let knobColor = Color(230, 230, 230, 230)

let throttleScale = {
  size = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(5)
  commands = [
    [VECTOR_LINE, 110, 10, 300, 10],
    [VECTOR_LINE, 110, 20, 210, 20],
    [VECTOR_LINE, 110, 30, 190, 30],
    [VECTOR_LINE, 110, 40, 180, 40],
    [VECTOR_LINE, 110, 50, 210, 50],
    [VECTOR_LINE, 110, 60, 150, 60],
    [VECTOR_LINE, 110, 70, 140, 70],
    [VECTOR_LINE, 110, 80, 130, 80],
    [VECTOR_LINE, 110, 90, 150, 90],
  ]
}

let throttleBgrImage = Picture("!ui/gameuiskin#hud_plane_slider.avif")
let maxThrottleText = loc("HUD/CRUISE_CONTROL_MAX_SHORT")
let wepText = loc("HUD/WEP_SHORT")
let percentText = loc("measureUnits/percent")

let HAPT_THROTTLE = registerHapticPattern("ThrottleChange", { time = 0.0, intensity = 0.5, sharpness = 0.4, duration = 0.2, attack = 0.08, release = 1.0 })

let function changeThrottleValue(val) {
  val = clamp(val, 0, maxThrottle)
  needOpacityThrottle(false)
  resetTimeout(idleTimeForThrottleOpacity, makeOpacityThrottle)
  setAxisValue("throttle", (maxThrottle - val) / maxThrottle)
  let th = (maxThrottle - val) / maxThrottle

  if (th >= 1.0)
    setShortcutOn("throttle_rangeMax")
  else
    setShortcutOff("throttle_rangeMax")
  userTrottle(val)
  playHapticPattern(HAPT_THROTTLE)
}

let function mkGamepadHotkey(hotkey, isVisible, isActive, ovr) {
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
  Computed(@() userTrottle.value > 0),
  Computed(@() isThrottleAxisActive.value && throttleAxisVal.value > 0),
  { hplace = ALIGN_RIGHT, pos = [pw(-100), 0] })
let btnImageThrottleDec = mkGamepadHotkey(axisMaxToHotkey(throttle_axis),
  Computed(@() userTrottle.value < maxThrottle),
  Computed(@() isThrottleAxisActive.value && throttleAxisVal.value < 0),
  { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM, pos = [pw(-100), 0] })

let function throttleSlider() {
  let knob = {
    size  = [knobSize + 2 * knobPadding, knobSize + 2 * knobPadding]
    pos = [0, (userTrottle.value.tofloat() / maxThrottle * throttleScaleHeight).tointeger() - knobPadding]
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
        watch = [Trt[0], TrtMode[0]]
        rendObj = ROBJ_TEXT
        pos = [knobSize + hdpx(5), 0]
        fontFxColor = Color(0, 0, 0, 255)
        color = TrtMode[0].value == AirThrottleMode.AIRCRAFT_WEP ? Color(255, 0, 0, 255) : knobColor
        fontFxFactor = 50
        fontFx = FFT_GLOW
        text = TrtMode[0].value == AirThrottleMode.AIRCRAFT_WEP ? wepText : Trt[0].value >= maxThrottle ? maxThrottleText : $"{Trt[0].value}{percentText}"
      }.__update(fontTiny)
    ]
  }

  return {
    watch = [ userTrottle, needOpacityThrottle ]
    key = userTrottle
    size = [fullWidth, height]
    padding = [0, sliderPadding]
    behavior = Behaviors.Slider
    fValue = userTrottle.value
    knob = knob
    max = maxThrottle
    unit = stepThrottle
    orientation = O_VERTICAL
    opacity = needOpacityThrottle.value ? 0.5 : 1.0
    transitions = [{ prop = AnimProp.opacity, duration = 0.5, easing = Linear }]
    children = [
      {
        size = [scaleWidth, throttleScaleHeight]
        pos =  [scaleWidth, 0]
        vplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        image = throttleBgrImage
        children = [
          throttleScale
          @() {
            watch = Trt[0]
            rendObj = ROBJ_MASK
            size = [knobSize, throttleScaleHeight]
            pos = [scaleWidth, 0]
            image = getSvgImage("hud_plane_gradient", knobSize, throttleScaleHeight)
            children = {
              rendObj = ROBJ_SOLID
              size = flex()
              transform = { pivot = [1, 1], scale = [1, Trt[0].value.tofloat() / maxThrottle] }
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
      resetTimeout(0.1, @() userTrottle(maxThrottle - Trt[0].value))
      setShortcutOn("throttle_rangeMax")
      needOpacityThrottle(true)
    }
    onChange = changeThrottleValue
  }
}

let throttleAxisUpdate = @()
  changeThrottleValue(userTrottle.value - throttlePerTick * throttleAxisVal.value)

isThrottleAxisActive.subscribe(function(isActive) {
  if (!isActive)
    clearTimer(throttleAxisUpdate)
  else {
    setInterval(throttleAxisUpdateTick, throttleAxisUpdate)
    throttleAxisUpdate()
  }
})

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

let aircraftIndicators = {
  flow = FLOW_VERTICAL
  gap = hdpx(5)
  children = [
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
  flow = FLOW_VERTICAL
  gap = hdpx(5)
  children = [
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
