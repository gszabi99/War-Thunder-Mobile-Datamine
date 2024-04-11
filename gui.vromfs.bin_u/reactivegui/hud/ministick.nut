from "%globalsDarg/darg_library.nut" import *
let { get_mission_time = @() ::get_mission_time() } = require("mission")
let { Point2 } = require("dagor.math")
let { rnd_int } = require("dagor.random")

let stickHeadSize = evenPx(120)
let stickTouchAreaSize = stickHeadSize
let stickDragAreaSize = 2 * (stickHeadSize * 0.82 + 0.5).tointeger()

let stickDragAreaBg = {
  size = [stickDragAreaSize, stickDragAreaSize]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_voice_stick_bg.svg:{stickDragAreaSize}:{stickDragAreaSize}:P")
  color = 0xFFFFFFFF
}

let stickHeadBg = {
  size = [stickHeadSize, stickHeadSize]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#joy_head.svg:{stickHeadSize}:{stickHeadSize}:P")
  color = 0xFFFFFFFF
}

/**
 * Creates a mini touch stick control component, for example for navigating in a pieMenuComp. Or for any other purposes.
 * @param {Watched(bool)} isStickActive - Watched flag, if user is touching the stick with a finger right now.
 *                                        Just pass Watched(false) here, stick will control this state itself.
 * @param {Watched(Point2)} stickDelta - Watched X/Y coordinates of current stick position (get it from miniStick).
 *                                       Just pass Watched(Point2(0, 0)) here, stick will control this state itself.
 * @param {table} [stickHeadChild] - Optional component to be placed on stick head (for example icon).
 * @param {Watched(float)} [stickCooldownEndTime] - Optional watched mission time when cooldown should finish.
 *                                                  When no cooldown, pass any time less than current mission time (like -1).
 * @param {Watched(float)} [stickCooldownTimeSec] - Optional watched total cooldown time in seconds. Should be > 0, can be constant.
 * @param {Watched(bool)} [isStickEnabled] - Optional watched flag, if stick is enabled, by cooldown and/or other states.
 *                                           If you are using cooldown, you should set this flag to false when in cooldown.
 * @return {table} - Table with "stickControl" (stick component for HUD) and "stickView" (stick component for HudEditor).
 */
let mkMiniStick = kwarg(function mkMiniStick(
  isStickActive,
  stickDelta,
  stickHeadChild = null,
  stickCooldownEndTime = Watched(-1),
  stickCooldownTimeSec = Watched(-1),
  isStickEnabled = Watched(true)
) {
  let animUID = rnd_int(0, 0xFFFF)

  let stickHeadBase = stickHeadBg.__merge({
    children = stickHeadChild
  })

  let stickHeadControl = stickHeadBase.__merge({
    transform = {}
  })

  let stickDragAreaControl = @() {
    watch = isStickActive
    size = flex()
    transform = {}
    children = isStickActive.get() ? stickDragAreaBg : null
  }

  let stickControlEnabled = {
    behavior = Behaviors.TouchScreenStick
    size = [stickTouchAreaSize, stickTouchAreaSize]

    useCenteringOnTouchBegin = true
    maxValueRadius = stickDragAreaSize / 2
    deadZone = 0.5

    onChange = @(v) stickDelta.set(Point2(v.x, v.y))
    onTouchBegin = @() isStickActive.set(true)
    onTouchEnd = @() isStickActive.set(false)
    onAttach = @() isStickActive.set(false)
    onDetach = @() isStickActive.set(false)

    children = [
      stickDragAreaControl
      stickHeadControl
    ]
  }

  let stickControlDisabled = {
    size = [stickTouchAreaSize, stickTouchAreaSize]
    function children() {
      let cdLeft = stickCooldownEndTime.get() - get_mission_time()
      let isCdValid = cdLeft > 0 && stickCooldownTimeSec.get() > 0
      return stickHeadBase.__merge({
        children = stickHeadChild?.__merge({ opacity = 0.5 })
      }, !isCdValid ? {} : {
        watch = [stickCooldownEndTime, stickCooldownTimeSec]
        rendObj = ROBJ_PROGRESS_CIRCULAR
        fgColor = 0xFFFFFFFF
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
      })
    }
  }

  let stickControl = @() { watch = isStickEnabled }
    .__update(isStickEnabled?.get() ? stickControlEnabled : stickControlDisabled)

  let stickView = {
    size = [stickTouchAreaSize, stickTouchAreaSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = stickHeadBase
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
