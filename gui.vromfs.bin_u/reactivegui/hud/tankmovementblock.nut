from "%globalsDarg/darg_library.nut" import *
from "%rGui/controls/shortcutConsts.nut" import *
let { Point2 } = require("dagor.math")
let { currentTankMoveCtrlType } = require("%rGui/options/chooseMovementControls/tankMoveControlType.nut")
let { setVirtualAxisValue } = require("%globalScripts/controls/shortcutActions.nut")
let { isStickActiveByStick, stickDelta } = require("stickState.nut")
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { IsTracked } = require("%rGui/hud/tankState.nut")
let axisListener = require("%rGui/controls/axisListener.nut")
let { gm_mouse_aim_x, gm_mouse_aim_y, gm_throttle, gm_steering } = require("%rGui/controls/shortcutsMap.nut").gamepadAxes
let { setMoveControlByArrows } = require("hudState")
let { enabledControls, isAllControlsEnabled, isControlEnabled } = require("%rGui/controls/disabledControls.nut")

let stickZoneSize = [shHud(40), shHud(40)]
let bgRadius = shHud(15)
let imgBgSize = 2 * bgRadius
let imgRotationSize = (0.1 * imgBgSize).tointeger()
let imgArrowW = (0.1 * imgBgSize).tointeger()
let imgArrowH = (23.0 / 35 * imgArrowW).tointeger()
let imgArrowGap = shHud(0.4)
let imgArrowSmallW = (0.08 * imgBgSize).tointeger()
let imgArrowSmallH = (23.0 / 35 * imgArrowW).tointeger()
let imgArrowSmallPosX = 0.35 * imgBgSize + 0.5 * imgArrowSmallW
let imgArrowSmallPosY = 0.35 * imgBgSize + 0.5 * imgArrowSmallH
let stickSize = shHud(11)

let isTankMoveEnabled = Computed(@()
  isControlEnabled("gm_throttle", enabledControls.get(), isAllControlsEnabled.get())
    || isControlEnabled("gm_steering", enabledControls.get(), isAllControlsEnabled.get()))

let imgRotaion = {
  size = [imgRotationSize, imgRotationSize]
  pos = [-0.5 * imgRotationSize, 0]
  vplace = ALIGN_CENTER
  image = Picture($"ui/gameuiskin#hud_tank_stick_rotation.svg:{imgRotationSize}:{imgRotationSize}:P")
  rendObj = ROBJ_IMAGE
}

let imgArrow = {
  size = [imgArrowW, imgArrowH]
  pos = [0, -imgArrowH - imgArrowGap]
  hplace = ALIGN_CENTER
  image = Picture($"ui/gameuiskin#hud_tank_stick_arrow.svg:{imgArrowW}:{imgArrowH}:P")
  rendObj = ROBJ_IMAGE
}

let imgArrowSmall = {
  size = [imgArrowSmallW, imgArrowSmallH]
  pos = [ -imgArrowSmallPosX, -imgArrowSmallPosY ]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  image = Picture($"ui/gameuiskin#hud_tank_stick_arrow.svg:{imgArrowSmallW}:{imgArrowSmallH}:P")
  rendObj = ROBJ_IMAGE
  transform = { rotate = -45 }
}

let imgBg = {
  size = [imgBgSize, imgBgSize]
  image = Picture($"ui/gameuiskin#hud_tank_stick_bg.svg:{imgBgSize}:{imgBgSize}:P")
  rendObj = ROBJ_IMAGE
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  color = borderColor
}

let fullImgBg = imgBg.__merge({ children = [
  imgRotaion.__merge({
    flipX = true
  })
  imgRotaion.__merge({
    pos = [0.5 * imgRotationSize, 0]
    hplace = ALIGN_RIGHT
  })
  imgArrow
  imgArrow.__merge({
    pos = [0, imgArrowH + imgArrowGap]
    vplace = ALIGN_BOTTOM
    transform = { rotate = 180 }
  })
  imgArrowSmall
  imgArrowSmall.__merge({
    pos = [ imgArrowSmallPosX, -imgArrowSmallPosY ]
    transform = { rotate = 45 }
  })
  imgArrowSmall.__merge({
    pos = [ imgArrowSmallPosX, imgArrowSmallPosY ]
    transform = { rotate = 135 }
  })
  imgArrowSmall.__merge({
    pos = [ -imgArrowSmallPosX, imgArrowSmallPosY ]
    transform = { rotate = 225 }
  })
] })


let imgBgComp = @() {
  watch = isStickActiveByStick
  size = flex()
  opacity = isStickActiveByStick.value ? 0.5 : 1.0
  children = isStickActiveByStick.value ? imgBg : fullImgBg
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

let tankMoveStickBase  = @() {
  watch = [IsTracked, currentTankMoveCtrlType]
  key = currentTankMoveCtrlType
  behavior = Behaviors?.TouchScreenSteeringStick ?? Behaviors.TouchScreenStick
  size = stickZoneSize
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
  maxValueRadius = bgRadius
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
    imgBgComp
    imgStick
  ]
}

let tankMoveStick = @() {
  watch = isTankMoveEnabled
  size = stickZoneSize
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_LEFT
  children = isTankMoveEnabled.value ? tankMoveStickBase : imgBg
}

function gamepadStick() {
  let dir = Point2(stickDelta.value)
  if (dir.lengthSq() > 1)
    dir.normalize()
  return {
    watch = stickDelta
    size = [0, 0]
    pos = [pw(50.0 - 50.0 * dir.x), ph(50.0 - 50.0 * dir.y)]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = imgStick
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

let tankGamepadStick = {
  key = {}
  size = [imgBgSize, imgBgSize]
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
      children = fullImgBg
    }
    gamepadStick
    gamepadAxisListener
  ]
}

let tankGamepadMoveBlock = @() {
  watch = isTankMoveEnabled
  size = stickZoneSize
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = isTankMoveEnabled.value ? tankGamepadStick : null
}

let tankMoveStickView = {
  size = stickZoneSize
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    fullImgBg
    imgStick
  ]
}

return {
  tankMoveStick
  tankGamepadMoveBlock
  tankMoveStickView
}