from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/gradients.nut" import gradRadial
from "%rGui/unseenPriority.nut" import UNSEEN_LOW, UNSEEN_NORMAL, UNSEEN_HIGH


const fillColor = 0xFFFFB70B
const lowPriorityFillColor = 0xFF808080
const borderColor = 0xFF000000
const frameColor = 0xFFFFE9B5

const fillColorFeature = 0xFF38FF92
const borderColorFeature = 0xFF206E56
const frameColorFeature = 0xFF9EF7CD

const minOpacity = 0.4
const maxOpacity = 1.0
const DURATION = 1.2
const DELAY_BETWEEN = 0.3
const DELAY_FRAME = DURATION / 2 - 0.1
const LOOP_DURATION = 3.0

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
  size = FLEX
  rendObj = ROBJ_BOX
  fillColor
  borderColor
  borderWidth = hdpx(1)
  opacity = minOpacity
  animations = opacityAnim
  children = {
    size = FLEX
    rendObj = ROBJ_IMAGE
    image = gradRadial
  }
}

let animatedFrame = {
  size = FLEX
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
