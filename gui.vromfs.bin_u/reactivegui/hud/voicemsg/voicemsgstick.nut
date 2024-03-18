from "%globalsDarg/darg_library.nut" import *
let { get_mission_time = @() ::get_mission_time() } = require("mission")
let { Point2 } = require("dagor.math")
let { COOLDOWN_TIME_SEC, isVoiceMsgEnabled, voiceMsgCooldownEndTime, isVoiceMsgStickActive, voiceMsgStickDelta
} = require("%rGui/hud/voiceMsg/voiceMsgState.nut")

let stickHeadSize = shHud(11)
let stickTouchAreaSize = stickHeadSize
let stickDragAreaSize = (stickHeadSize * 1.63 + 0.5).tointeger()
let stickHeadIconSize = (stickHeadSize * 0.5 + 0.5).tointeger()

let imgBg = {
  size = [stickDragAreaSize, stickDragAreaSize]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_voice_stick_bg.svg:{stickDragAreaSize}:{stickDragAreaSize}:P")
  color = 0xFFFFFFFF
}

let imgBgComp = @() {
  watch = isVoiceMsgStickActive
  size = flex()
  transform = {}
  children = isVoiceMsgStickActive.get() ? imgBg : null
}

let stickIcon = {
  size = [stickHeadIconSize, stickHeadIconSize]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#voice_messages.svg:{stickHeadIconSize}:{stickHeadIconSize}:P")
  keepAspect = true
  color = 0xFFFFFFFF
}

let imgStick = {
  size = [stickHeadSize, stickHeadSize]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#joy_head.svg:{stickHeadSize}:{stickHeadSize}:P")
  color = 0xFFFFFFFF
  children = stickIcon
}

let imgStickComp = imgStick.__merge({
  transform = {}
})

let voiceMsgStickBlockEnabled = {
  behavior = Behaviors.TouchScreenStick
  size = [stickTouchAreaSize, stickTouchAreaSize]

  useCenteringOnTouchBegin = true
  maxValueRadius = stickDragAreaSize / 2
  deadZone = 0.5

  // Compatibility for pre-1.5.2.X clients
  touchStickAction = { horizontal = "wheelmenu_x", vertical = "wheelmenu_y" }
  steeringTable = [ [12, 0], [13, 0.2], [60, 0.5], [74, 0.9], [75, 1.0] ]
  deadZoneForTurnAround = 75
  deadZoneForStraightMove = 20
  valueAfterDeadZone = 0.55

  onChange = @(v) voiceMsgStickDelta.set(Point2(v.x, v.y))
  onTouchBegin = @() isVoiceMsgStickActive.set(true)
  onTouchEnd = @() isVoiceMsgStickActive.set(false)
  onAttach = @() isVoiceMsgStickActive.set(false)
  onDetach = @() isVoiceMsgStickActive.set(false)

  children = [
    imgBgComp
    imgStickComp
  ]
}

let voiceMsgStickBlockDisabled = {
  size = [stickTouchAreaSize, stickTouchAreaSize]
  function children() {
    let cdLeft = voiceMsgCooldownEndTime.get() - get_mission_time()
    return imgStick.__merge({
      watch = voiceMsgCooldownEndTime
      rendObj = ROBJ_PROGRESS_CIRCULAR
      fgColor = 0xFFFFFFFF
      bgColor = 0
      fValue = 1.0
      key = $"voicemsg_{voiceMsgCooldownEndTime}"
      animations = [
        {
          prop = AnimProp.fValue, to = 1.0, play = true,
          from = 1.0 - (cdLeft / COOLDOWN_TIME_SEC),
          duration = cdLeft
        }
      ]
      children = stickIcon.__merge({
        opacity = 0.5
      })
    })
  }
}

let voiceMsgStickBlock = @() { watch = isVoiceMsgEnabled }
  .__update(isVoiceMsgEnabled?.get() ? voiceMsgStickBlockEnabled : voiceMsgStickBlockDisabled)

let voiceMsgStickView = {
  size = [stickTouchAreaSize, stickTouchAreaSize]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = imgStick
}

return {
  voiceMsgStickBlock
  voiceMsgStickView
}
