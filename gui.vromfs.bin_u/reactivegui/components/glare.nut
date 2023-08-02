from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")

let glareSize = [hdpx(64), ph(140)]
let glareAnimDuration = 0.4
let glareRepeatDelay = 6

let function mkGlare(parentWidth, size = glareSize) {
  let trigger = {}
  let startGlareAnim = @() anim_start(trigger)
  return {
    key = {}
    rendObj = ROBJ_IMAGE
    size = size
    image = gradTranspDoubleSideX
    color = 0x00A0A0A0
    transform = { translate = [-size[0] * 3, 0], rotate = 25 }
    vplace = ALIGN_CENTER
    hplace = ALIGN_LEFT
    onAttach = @() clearTimer(startGlareAnim)
    animations = [{
      prop = AnimProp.translate, duration = glareAnimDuration, delay = 0.5, play = true,
      to = [parentWidth + size[0] * 2, 0],
      trigger,
      onFinish = @() resetTimeout(glareRepeatDelay, startGlareAnim),
    }]
  }
}

return {
  mkGlare
  commonGlare = mkGlare(hdpx(500))
}