from "%globalsDarg/darg_library.nut" import *
let { gradRadial } = require("%rGui/style/gradients.nut")

let fillColor = 0xFFFFB70B
let borderColor = 0xFF000000
let frameColor = 0xFFFFE9B5
let minOpacity = 0.4
let maxOpacity = 1.0
let DURATION = 1.2
let DELAY_BETWEEN = 0.3
let DELAY_FRAME = DURATION / 2 - 0.1

let opacityAnim = [
  {
    prop = AnimProp.opacity, from = minOpacity, to = maxOpacity, easing = CosineFull,
    delay = DELAY_BETWEEN, duration = DURATION, play = true, globalTimer = true,
    trigger = "opacityAnim", onStart = @() anim_start("frameAnim")
  }
]

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

let mkUnseenGoodsMark = @(ovr = {}) {
  size = [hdpx(22), hdpx(22)]
  margin = hdpx(30)
  transform = { rotate = 45 }
  children = [
    {
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
    {
      size = flex()
      rendObj = ROBJ_FRAME
      borderWidth = hdpx(2)
      color = frameColor
      transform = {}
      opacity = 0.0
      animations = frameAnim
    }
  ]
}.__update(ovr)

return mkUnseenGoodsMark
