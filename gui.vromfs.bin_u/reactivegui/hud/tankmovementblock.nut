from "%globalsDarg/darg_library.nut" import *
from "%rGui/controls/shortcutConsts.nut" import *
let { Point2 } = require("dagor.math")
let { TouchScreenSteeringStick } = require("wt.behaviors")
let { currentTankMoveCtrlType } = require("%rGui/options/chooseMovementControls/tankMoveControlType.nut")
let { setVirtualAxisValue } = require("%globalScripts/controls/shortcutActions.nut")
let { isStickActiveByStick, stickDelta } = require("stickState.nut")
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { IsTracked } = require("%rGui/hud/tankState.nut")
let axisListener = require("%rGui/controls/axisListener.nut")
let { gm_mouse_aim_x, gm_mouse_aim_y, gm_throttle, gm_steering } = require("%rGui/controls/shortcutsMap.nut").gamepadAxes
let { setMoveControlByArrows } = require("hudState")
let { enabledControls, isAllControlsEnabled, isControlEnabled } = require("%rGui/controls/disabledControls.nut")

let stickZoneSize = evenPx(380)
let bgRadius = evenPx(160)
let zoneToBgRadius = bgRadius.tofloat() / stickZoneSize
let imgBgSize = 2 * bgRadius
let imgRotationSize = (0.1 * imgBgSize).tointeger()
let imgArrowW = (0.1 * imgBgSize).tointeger()
let imgArrowH = (23.0 / 35 * imgArrowW).tointeger()
let imgArrowGapPw = 3
let imgArrowSmallW = (0.08 * imgBgSize).tointeger()
let imgArrowSmallH = (23.0 / 35 * imgArrowW).tointeger()
let diagArrowOffsetPw = 40
let stickSize = shHud(11)

let isTankMoveEnabled = Computed(@()
  isControlEnabled("gm_throttle", enabledControls.get(), isAllControlsEnabled.get())
    || isControlEnabled("gm_steering", enabledControls.get(), isAllControlsEnabled.get()))

let mkImgRotaion = @(size) {
  size = [size, size]
  pos = [-0.5 * size, 0]
  vplace = ALIGN_CENTER
  image = Picture($"ui/gameuiskin#hud_tank_stick_rotation.svg:{size}:{size}:P")
  rendObj = ROBJ_IMAGE
}

let mkImgArrow = @(w, h) {
  size = [w, h]
  hplace = ALIGN_CENTER
  image = Picture($"ui/gameuiskin#hud_tank_stick_arrow.svg:{w}:{h}:P")
  rendObj = ROBJ_IMAGE
}

function imgBg(scale) {
  let size = scaleEven(imgBgSize, scale)
  return {
    size = [size, size]
    image = Picture($"ui/gameuiskin#hud_tank_stick_bg.svg:{size}:{size}:P")
    rendObj = ROBJ_IMAGE
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    color = borderColor
  }
}

function fullImgBg(scale) {
  let rotSize = scaleEven(imgRotationSize, scale)
  let imgRotaion = mkImgRotaion(rotSize)
  let imgArrow = mkImgArrow(scaleEven(imgArrowW, scale), scaleEven(imgArrowH, scale))
  let imgArrowSmall = mkImgArrow(scaleEven(imgArrowSmallW, scale), scaleEven(imgArrowSmallH, scale))
    .__merge({ vplace = ALIGN_CENTER })
  return imgBg(scale).__merge({
    children = [
      imgRotaion.__merge({
        flipX = true
      })
      imgRotaion.__merge({
        pos = [0.5 * rotSize, 0]
        hplace = ALIGN_RIGHT
      })
      imgArrow.__merge({
        pos = [0, pw(-100 - imgArrowGapPw)]
        vplace = ALIGN_BOTTOM
      })
      imgArrow.__merge({
        pos = [0, pw(100 + imgArrowGapPw)]
        transform = { rotate = 180 }
      })
      imgArrowSmall.__merge({
        pos = [ pw(-diagArrowOffsetPw), pw(-diagArrowOffsetPw) ]
        transform = { rotate = -45 }
      })
      imgArrowSmall.__merge({
        pos = [ pw(diagArrowOffsetPw), pw(-diagArrowOffsetPw) ]
        transform = { rotate = 45 }
      })
      imgArrowSmall.__merge({
        pos = [ pw(diagArrowOffsetPw), pw(diagArrowOffsetPw) ]
        transform = { rotate = 135 }
      })
      imgArrowSmall.__merge({
        pos = [ pw(-diagArrowOffsetPw), pw(diagArrowOffsetPw) ]
        transform = { rotate = 225 }
      })
    ]
  })
}


let imgBgComp = @(scale) @() {
  watch = isStickActiveByStick
  size = flex()
  opacity = isStickActiveByStick.value ? 0.5 : 1.0
  children = isStickActiveByStick.value ? imgBg(scale) : fullImgBg(scale)
  transform = {}
}

function imgStick(scale) {
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

let tankMoveStickBase = @(zoneSize, scale) @() {
  watch = [IsTracked, currentTankMoveCtrlType]
  key = currentTankMoveCtrlType
  size = [zoneSize, zoneSize]

  behavior = TouchScreenSteeringStick
  touchStickAction = {
    horizontal = "gm_steering"
    vertical = "gm_throttle"
  }
  deadZoneForTurnAround = 75
  deadZoneForStraightMove = 20
  valueAfterDeadZone = 0.34
  steeringTable = [
    [12, 0],
    [13, 0.2],
    [60, 0.5],
    [74, 0.9],
    [75, 1.0]
  ]
  maxValueRadius = zoneSize * zoneToBgRadius
  useCenteringOnTouchBegin = currentTankMoveCtrlType.value == "stick"

  onChange = @(v) stickDelta(Point2(v.x, v.y))

  function onTouchBegin() {
    setVirtualAxisValue("gm_brake_left", 0)
    setVirtualAxisValue("gm_brake_right", 0)
    isStickActiveByStick(true)
    setMoveControlByArrows(false)
  }
  function onTouchEnd() {
    setVirtualAxisValue("gm_brake_left", 1)
    setVirtualAxisValue("gm_brake_right", 1)
    isStickActiveByStick(false)
    setMoveControlByArrows(true)
  }
  function onDetach() {
    setVirtualAxisValue("gm_brake_left", 0)
    setVirtualAxisValue("gm_brake_right", 0)
    isStickActiveByStick(false)
    setMoveControlByArrows(true)
  }
  children = [
    imgBgComp(scale)
    imgStick(scale)
  ]
}

function tankMoveStick(scale) {
  let zoneSize = scaleEven(stickZoneSize, scale)
  return @() {
    watch = isTankMoveEnabled
    size = [zoneSize, zoneSize]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_LEFT
    children = isTankMoveEnabled.get() ? tankMoveStickBase(zoneSize, scale)
      : imgBg(scale)
  }
}

function gamepadStick(scale) {
  let children = imgStick(scale)
  return function() {
    let dir = Point2(stickDelta.value)
    if (dir.lengthSq() > 1)
      dir.normalize()
    return {
      watch = stickDelta
      size = [0, 0]
      pos = [pw(50.0 - 50.0 * dir.x), ph(50.0 - 50.0 * dir.y)]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children
    }
  }
}

let gamepadAxisListener = axisListener({
  [gm_steering] = function(v) {
    stickDelta(Point2(-v, stickDelta.value.y))
    setVirtualAxisValue("gm_steering", -v)
  },
  [gm_throttle] = function(v) {
    stickDelta(Point2(stickDelta.value.x, v))
    setVirtualAxisValue("gm_throttle", v)
  },
  [gm_mouse_aim_x] = @(v) setVirtualAxisValue("gm_mouse_aim_x", v),
  [gm_mouse_aim_y] = @(v) setVirtualAxisValue("gm_mouse_aim_y", v),
})

let updateStickActive = @(delta) isStickActiveByStick(delta.lengthSq() > 0.04)

let tankGamepadStick = @(scale) {
  key = {}
  size = array(2, scaleEven(imgBgSize, scale))
  function onAttach() {
    stickDelta.subscribe(updateStickActive)
    updateStickActive(stickDelta.value)
  }
  function onDetach() {
    stickDelta.unsubscribe(updateStickActive)
    updateStickActive(Point2(0, 0))
  }
  children = [
    {
      size = flex()
      opacity = 0.75
      children = fullImgBg(scale)
    }
    gamepadStick(scale)
    gamepadAxisListener
  ]
}

let tankGamepadMoveBlock = @(scale) @() {
  watch = isTankMoveEnabled
  size = array(2, scaleEven(stickZoneSize, scale))
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = isTankMoveEnabled.get() ? tankGamepadStick(scale) : null
}

let tankMoveStickView = {
  size = [stickZoneSize, stickZoneSize]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    fullImgBg(1)
    imgStick(1)
  ]
}

return {
  tankMoveStick
  tankGamepadMoveBlock
  tankMoveStickView
}