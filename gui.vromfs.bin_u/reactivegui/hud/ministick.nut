from "%globalsDarg/darg_library.nut" import *
from "%rGui/controls/shortcutConsts.nut" import *
let { get_mission_time } = require("mission")
let { TouchScreenStick } = require("wt.behaviors")
let { Point2 } = require("dagor.math")
let { rnd_int } = require("dagor.random")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { mkGamepadShortcutImage, mkContinuousButtonParams } = require("%rGui/controls/shortcutSimpleComps.nut")
let axisListener = require("%rGui/controls/axisListener.nut")
let { STICK } = require("%rGui/hud/stickState.nut")
let { hudWhiteColor } = require("%rGui/style/hudColors.nut")


let stickHeadSize = evenPx(120)
let stickTouchAreaSize = stickHeadSize
let stickDragAreaSize = 2 * (stickHeadSize * 0.82 + 0.5).tointeger()

let defaultGamepadParams = {
  shortcutId = null,
  activeStick = STICK.LEFT
}

function stickDragAreaBg(scale) {
  let size = scaleEven(stickDragAreaSize, scale)
  return {
    size = [size, size]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#hud_voice_stick_bg.svg:{size}:{size}:P")
    color = hudWhiteColor
  }
}

function stickHeadBg(scale, ovr) {
  let size = scaleEven(stickHeadSize, scale)
  return {
    size = [size, size]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#joy_head.svg:{size}:{size}:P")
    color = hudWhiteColor
  }.__update(ovr)
}
















let mkMiniStick = kwarg(function mkMiniStick(
  isStickActive,
  stickDelta,
  stickHeadChild = null,
  stickCooldownEndTime = Watched(-1),
  stickCooldownTimeSec = Watched(-1),
  isStickEnabled = Watched(true),
  gamepadParams = defaultGamepadParams
) {
  let animUID = rnd_int(0, 0xFFFF)

  let stickHeadBase = @(scale, ovr = {}) stickHeadBg(scale, { children = stickHeadChild?(scale, true) }.__update(ovr))
  let stickHeadControl = @(scale) stickHeadBase(scale, { transform = {} })
  let { shortcutId, activeStick } = gamepadParams

  let stickDragAreaControl = @(scale) @() {
    watch = isStickActive
    size = flex()
    transform = {}
    children = isStickActive.get() ? stickDragAreaBg(scale) : null
  }

  let gamepadAxisListener = axisListener({
    [activeStick == STICK.LEFT ? JOY_XBOX_REAL_AXIS_L_THUMB_H : JOY_XBOX_REAL_AXIS_R_THUMB_H] = function(v) {
      stickDelta.set(Point2(-v, stickDelta.get().y))
    },
    [activeStick == STICK.LEFT ? JOY_XBOX_REAL_AXIS_L_THUMB_V : JOY_XBOX_REAL_AXIS_R_THUMB_V] = function(v) {
      stickDelta.set(Point2(stickDelta.get().x, v))
    },
  })

  let btn = @() {
    watch = isStickActive
    children = [
      mkContinuousButtonParams(
        @() isStickActive.set(true),
        @() isStickActive.set(false),
        shortcutId),
      mkGamepadShortcutImage(shortcutId, {pos = [pw(70), ph(-50)]})
    ]
    transform = { scale = isStickActive.get() ? [0.8, 0.8] : [1.0, 1.0] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }

  let stickControlEnabled = @(size, scale) {
    behavior = TouchScreenStick
    size = [size, size]
    watch = [isGamepad, isStickActive]

    useCenteringOnTouchBegin = true
    maxValueRadius = scaleEven(stickDragAreaSize, 0.5 * scale)
    deadZone = 0.5

    onChange = @(v) stickDelta.set(Point2(v.x, v.y))
    onTouchBegin = @() isStickActive.set(true)
    onTouchEnd = @() isStickActive.set(false)
    onAttach = @() isStickActive.set(false)
    onDetach = @() isStickActive.set(false)

    children = [
      stickDragAreaControl(scale)
      stickHeadControl(scale)
      !isGamepad.get() ? null : btn
      isGamepad.get() && isStickActive.get() ? gamepadAxisListener : null
    ]
  }

  let stickControlDisabled = @(size, scale) {
    size = [size, size]
    function children() {
      let cdLeft = stickCooldownEndTime.get() - get_mission_time()
      let isCdValid = cdLeft > 0 && stickCooldownTimeSec.get() > 0
      return stickHeadBase(scale,
        { children = stickHeadChild?(scale, false) }
          .__update(!isCdValid ? {}
            : {
                watch = [stickCooldownEndTime, stickCooldownTimeSec]
                rendObj = ROBJ_PROGRESS_CIRCULAR
                fgColor = hudWhiteColor
                bgColor = 0
                fValue = 1.0
                key = $"{animUID}_{stickCooldownEndTime.get()}"
                animations = [
                  {
                    prop = AnimProp.fValue, to = 1.0, play = true,
                    from = 1.0 - (cdLeft / stickCooldownTimeSec.get()),
                    duration = cdLeft
                  }
                ]
              }))
    }
  }

  function stickControl(scale) {
    let size = scaleEven(stickTouchAreaSize, scale)
    return @() { watch = isStickEnabled }
      .__update(isStickEnabled?.get() ? stickControlEnabled(size, scale) : stickControlDisabled(size, scale))
  }

  let stickView = {
    size = [stickTouchAreaSize, stickTouchAreaSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = stickHeadBase(1)
  }

  return {
    stickControl
    stickView
  }
})

return {
  mkMiniStick
  stickHeadSize
}
