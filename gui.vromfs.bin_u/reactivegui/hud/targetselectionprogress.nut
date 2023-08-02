from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { getSvgImage } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { targetUnitName } = require("%rGui/hudState.nut")

let color = Color(255, 255, 255, 255)

let defTransform = {}
let cooldownEndTime = Watched(0.0)
let cooldownTime = Watched(0.0)
let showTargetName = Watched(false)

let TARGET_UPSCALE = 0.3
let targetSize = hdpx(16)
let targetImage = getSvgImage("target_lock_corner", targetSize)
let targetOffset = [0, - hdpx(20)]

subscribe("on_delayed_target_select:show", function(data) {
  let { lockTime = 0.0, endTime = 0.0 } = data
  cooldownEndTime(endTime)
  cooldownTime(lockTime)
  showTargetName(true)
})

subscribe("on_delayed_target_select:hide", function(_) {
  cooldownEndTime(0.0)
  showTargetName(false)
})

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

let function mkTargetSelectionData(endTime, cooldown, textSize) {
  if (endTime <= 0 || cooldown <= 0)
    return null

  let cdLeft = (endTime - ::get_mission_time())
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

let targetName = @(text) {
  pos = targetOffset
  rendObj = ROBJ_TEXT
  color
  opacity = 1.0
  text
  animations = [
    {
      prop = AnimProp.opacity, from = 0.0, to = 1.0, play = true,
      duration = 0.5
    }
  ]
}.__update(fontTiny)

let targetSelectionProgress = @() {
  watch = [cooldownTime, cooldownEndTime, targetUnitName]
  transform = defTransform
  behavior = Behaviors.Indicator
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    showTargetName.value ? targetName(targetUnitName.value) : null
    mkTargetSelectionData(cooldownEndTime.value, cooldownTime.value, calc_str_box(targetUnitName.value, fontTiny))
  ]
}

return {
  targetSelectionProgress
  targetName
  mkTargetSelectionData
}