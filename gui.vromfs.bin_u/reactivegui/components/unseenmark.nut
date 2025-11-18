from "%globalsDarg/darg_library.nut" import *
let { gradRadial } = require("%rGui/style/gradients.nut")
let { UNSEEN_LOW, UNSEEN_NORMAL, UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")

let fillColor = 0xFFFFB70B
let lowPriorityFillColor = 0xFF808080
let borderColor = 0xFF000000
let frameColor = 0xFFFFE9B5

let fillColorFeature = 0xFF38FF92
let borderColorFeature = 0xFF206E56
let frameColorFeature = 0xFF9EF7CD

let minOpacity = 0.4
let maxOpacity = 1.0
let DURATION = 1.2
let DELAY_BETWEEN = 0.3
let DELAY_FRAME = DURATION / 2 - 0.1
let LOOP_DURATION = 3.0

let unseenSize = [hdpx(22), hdpx(22)]
let unseenSizeBig = [hdpx(32), hdpx(32)]

let opacityAnim = [{
  prop = AnimProp.opacity, from = minOpacity, to = maxOpacity, easing = CosineFull,
  delay = DELAY_BETWEEN, duration = DURATION, play = true, globalTimer = true,
  trigger = "opacityAnim", onStart = @() anim_start("frameAnim")
}]

let opacityAnimLoop = [{
  prop = AnimProp.opacity, from = minOpacity, to = maxOpacity, easing = CosineFull,
  duration = LOOP_DURATION, play = true, loop = true, globalTimer = true
}]

let frameAnim = [
  {
    prop = AnimProp.scale, from = [1.0, 1.0], to = [2.2, 2.2],
    delay = DELAY_FRAME, duration = DURATION / 2, easing = Linear,
    trigger = "frameAnim"
  }
  {
    prop = AnimProp.opacity, from = 0.0, to = maxOpacity,
    delay = DELAY_FRAME, duration = DURATION / 2, easing = CosineFull,
    trigger = "frameAnim", onFinish = @() anim_start("opacityAnim")
  }
]

let coreUnseenBox = {
  size = flex()
  rendObj = ROBJ_BOX
  fillColor
  borderColor
  borderWidth = hdpx(1)
  opacity = minOpacity
  animations = opacityAnim
  children = {
    size = flex()
    rendObj = ROBJ_IMAGE
    image = gradRadial
  }
}

let animatedFrame = {
  size = flex()
  rendObj = ROBJ_FRAME
  borderWidth = hdpx(2)
  color = frameColor
  transform = {}
  opacity = 0.0
  animations = frameAnim
}

let priorityUnseenMark = {
  key = {}
  size = unseenSize
  transform = { rotate = 45 }
  children = [
    coreUnseenBox
    animatedFrame
  ]
}

let priorityUnseenMarkFeature = {
  key = {}
  size = unseenSize
  transform = { rotate = 45 }
  children = [
    coreUnseenBox.__merge({ fillColor = fillColorFeature, borderColor = borderColorFeature })
    animatedFrame.__merge({color = frameColorFeature})
  ]
}

let priorityUnseenMarkLight = {
  key = {}
  size = unseenSizeBig
  transform = { rotate = 45 }
  children = [
    coreUnseenBox.__merge({ fillColor = 0, borderColor = 0 })
    animatedFrame
  ]
}

let unseenMark = coreUnseenBox.__merge({
  key = {}
  size = unseenSize
  opacity = 1.0
  transform = { rotate = 45 }
  animations = opacityAnimLoop
})

let lowPriorityUnseenMark = unseenMark.__merge({
  key = {}
  fillColor = lowPriorityFillColor
})

let markByPriority = {
  [UNSEEN_LOW] = lowPriorityUnseenMark,
  [UNSEEN_NORMAL] = unseenMark,
  [UNSEEN_HIGH] = priorityUnseenMark,
}

let mkUnseenMark = @(priorirty, ovr = {}) @() {
  watch = priorirty
  children = markByPriority?[priorirty.get()]
}.__update(ovr)

let mkPriorityUnseenMarkWatch = @(watch, ovr = {}) @() {
  watch
  children = watch.get() ? priorityUnseenMark : null
}.__update(ovr)

return {
  priorityUnseenMark
  unseenMark
  unseenSize
  lowPriorityUnseenMark
  mkUnseenMark
  mkPriorityUnseenMarkWatch
  priorityUnseenMarkFeature
  priorityUnseenMarkLight
}
