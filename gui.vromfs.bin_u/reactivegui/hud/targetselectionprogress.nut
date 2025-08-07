from "%globalsDarg/darg_library.nut" import *
let { Indicator } = require("wt.behaviors")
let { get_mission_time } = require("mission")
let { eventbus_subscribe } = require("eventbus")
let { getSvgImage } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { targetUnitName, hasTarget } = require("%rGui/hudState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let color = 0xFFFFFFFF
let cooldownColor = 0xFFB0B0B0

let defTransform = {}
let cooldownEndTime = Watched(0.0)
let cooldownTime = Watched(0.0)
let showTargetName = Watched(false)

let asmCaptureEndTime = Watched(0.0)
let asmCaptureTime = Watched(0.0)

let TARGET_UPSCALE = 0.3
let targetSize = hdpx(16)
let targetImage = getSvgImage("target_lock_corner", targetSize)
let targetOffset = [0, - hdpx(20)]

eventbus_subscribe("on_delayed_target_select:show", function(data) {
  let { lockTime = 0.0, endTime = 0.0 } = data
  cooldownEndTime.set(endTime)
  cooldownTime.set(lockTime)
  showTargetName.set(true)
})

eventbus_subscribe("on_asm_capture:show", function(data) {
  let { lockTime = 0.0, endTime = 0.0 } = data
  asmCaptureEndTime.set(endTime)
  asmCaptureTime.set(lockTime)
})

let nameTrigger = {}

let hasTargetName = Computed(@() showTargetName.get() && targetUnitName.get() != null && targetUnitName.get() != "")

function hide_asm() {
  asmCaptureEndTime.set(0.0)
  asmCaptureTime.set(0.0)
}

function hide_delayed_target_select() {
  cooldownEndTime.set(0.0)
  asmCaptureEndTime.set(0.0)
  showTargetName.set(false)
}

isInBattle.subscribe(function(_) {
  hide_asm()
  hide_delayed_target_select()
})
eventbus_subscribe("on_asm_capture:hide", @(_) hide_asm())
eventbus_subscribe("on_delayed_target_select:hide", @(_) hide_delayed_target_select())
hasTarget.subscribe(function(value){
  if (value == false)
    showTargetName.set(false)
})
targetUnitName.subscribe(@(_) anim_start(nameTrigger))

let mkTargetCorner = @(cdLeft, delay, ovr) {
  rendObj = ROBJ_PROGRESS_CIRCULAR
  fgColor = color
  bgColor = 0
  opacity = 1.0
  fValue = 1.0
  image = targetImage
  animations = [
    {
      prop = AnimProp.opacity, from = 0.0, to = 0.0, play = true,
      duration = delay
    }
    {
      prop = AnimProp.fValue, from = 0.0, to = 0.75, play = true,
      delay, duration = cdLeft / 5.0
    }
  ]
}.__update(ovr)

function mkTargetSelectionData(endTime, cooldown, textSize) {
  if (endTime <= 0 || cooldown <= 0)
    return null

  let cdLeft = max(endTime - get_mission_time(), 0.0)
  let iconSize = [targetSize, targetSize]
  let delay = - cdLeft * (1 - cdLeft / cooldown)
  let upscaleX = textSize[0] ? (hdpx(15) / textSize[0] + 1.0) : 1.1

  return {
    pos = targetOffset
    size = [textSize[0] + hdpx(30), textSize[1] + hdpx(10)]
    key = $"reload_sector_{endTime}_{cooldown}_{color}_{textSize[0]}"
    transform = {}
    animations = [
      {
        prop = AnimProp.scale, from = [1.0, 1.0], to = [upscaleX, 1.1], play = true,
        delay = cdLeft, duration = TARGET_UPSCALE, easing = InOutQuad
      }
    ]
    children = [
      mkTargetCorner(cdLeft, delay, {
        vplace = ALIGN_TOP
        hplace = ALIGN_RIGHT
        size = iconSize
        transform = { rotate = - 90 }
      })
      mkTargetCorner(cdLeft, delay + cdLeft * 0.25, {
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_RIGHT
        size = iconSize
      })
      mkTargetCorner(cdLeft, delay + cdLeft * 0.5, {
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_LEFT
        size = iconSize
        transform = { rotate = 90 }
      })
      mkTargetCorner(cdLeft, delay + cdLeft * 0.75, {
        vplace = ALIGN_TOP
        hplace = ALIGN_LEFT
        size = iconSize
        transform = { rotate = 180 }
      })
    ]
  }
}

let targetName = @() {
  watch = targetUnitName
  pos = targetOffset
  rendObj = ROBJ_TEXT
  color
  opacity = 1.0
  text = targetUnitName.get()
  animations = [
    {
      prop = AnimProp.opacity, from = 0.0, to = 1.0, play = true,
      duration = 0.6, trigger = nameTrigger
    }
  ]
}.__update(fontTiny)

let targetSelectionProgress = @() {
  watch = [hasTarget, hasTargetName, cooldownTime, cooldownEndTime, targetUnitName]
  transform = defTransform
  behavior = Indicator
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = !hasTargetName.get() ? null
    : [
        targetName
        mkTargetSelectionData(cooldownEndTime.get(), cooldownTime.get(), calc_str_box(targetUnitName.get(), fontTiny))
      ]
}

let cornerSize = [hdpx(75), hdpx(35)]
let travel = hdpx(30)
let mkItem = @(key, hplace, vplace, from, duration, commands) {
  key
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(2)
  fillColor = 0
  color
  size = cornerSize
  transform = {}
  hplace
  vplace
  commands
  animations = [
    {
      prop = AnimProp.translate, play = true,
      duration, easing = Linear,
      from, to = [0, 0]
    }
    {
      prop = AnimProp.color, play = true,
      duration
      from = cooldownColor, to = cooldownColor
    }
  ]
}

function mkAsmCaptureData(endTime, cooldown) {
  if (endTime <= 0 || cooldown <= 0)
    return null
  let cdLeft = (endTime - get_mission_time())
  return {
    size = [cornerSize[0] * 2, cornerSize[1] * 2]
    transform = { pivot = [0.5, 0.5] }
    children = [
      mkItem("rightTop", ALIGN_RIGHT, ALIGN_TOP, [travel, -travel], cdLeft,
        [ [VECTOR_LINE, 0, 50, 50, 50], [VECTOR_LINE, 50, 50, 50, 100] ])
      mkItem("rightDown", ALIGN_RIGHT, ALIGN_BOTTOM, [travel, travel], cdLeft,
        [ [VECTOR_LINE, 0, 50, 50, 50], [VECTOR_LINE, 50, 50, 50, 0] ])
      mkItem("leftTop", ALIGN_LEFT, ALIGN_TOP, [-travel, -travel], cdLeft,
        [ [VECTOR_LINE, 50, 100, 50, 50], [VECTOR_LINE, 50, 50, 100, 50] ])
      mkItem("leftDown", ALIGN_LEFT, ALIGN_BOTTOM, [-travel, travel], cdLeft,
        [ [VECTOR_LINE, 50, 0, 50, 50], [VECTOR_LINE, 50, 50, 100, 50] ])
      mkItem("Top", ALIGN_CENTER, ALIGN_TOP, [0, -travel * 2], cdLeft,
        [ [VECTOR_LINE, 50, 0, 50, 50] ])
      mkItem("Bottom", ALIGN_CENTER, ALIGN_BOTTOM, [0, travel * 2], cdLeft,
        [ [VECTOR_LINE, 50, 100, 50, 50] ])
      mkItem("Left", ALIGN_LEFT, ALIGN_CENTER, [-travel * 2, 0], cdLeft,
        [ [VECTOR_LINE, 0, 50, 50, 50] ])
      mkItem("Right", ALIGN_RIGHT, ALIGN_CENTER, [travel * 2, 0], cdLeft,
        [ [VECTOR_LINE, 100, 50, 50, 50] ])
    ]
    animations = [ { prop=AnimProp.opacity, from=1, to=0, play = true, duration=0.3, easing=DoubleBlink, delay = cdLeft } ]
  }
}

let asmCaptureProgress = @() {
  watch = [asmCaptureTime, asmCaptureEndTime]
  transform = defTransform
  size = 0
  behavior = Indicator
  useTargetCenterPos = true
  offsetY = 10
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    mkAsmCaptureData(asmCaptureEndTime.get(), asmCaptureTime.get())
  ]
}

return {
  targetSelectionProgress
  targetName
  mkTargetSelectionData
  asmCaptureProgress
}