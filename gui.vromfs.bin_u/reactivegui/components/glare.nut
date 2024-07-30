from "%globalsDarg/darg_library.nut" import *
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")

let defGlareHeight = ph(140)
let defGlareWidth = hdpx(64)
let defTranslateXMult = 3
let defAnimToXMult = 2
let glareAnimDuration = 0.4
let glareDelay = 0.5
let glareRepeatDelay = 6

function mkGlare(parentWidth, timeParams = null, positionParams = null, animParams = null) {
  let { glareWidth = defGlareWidth } = positionParams
  let { duration = glareAnimDuration, delay = glareDelay, repeatDelay = glareRepeatDelay } = timeParams
  let { translateXMult = defTranslateXMult, animToXMult = defAnimToXMult } = animParams
  return {
    key = {}
    rendObj = ROBJ_IMAGE
    size = [glareWidth, defGlareHeight]
    image = gradTranspDoubleSideX
    color = 0x00A0A0A0
    transform = { translate = [-glareWidth * translateXMult, 0], rotate = 25 }
    vplace = ALIGN_CENTER
    hplace = ALIGN_LEFT
    animations = [{
      prop = AnimProp.translate, duration, delay, play = true,
      to = [parentWidth + glareWidth * animToXMult, 0],
      loop = true, loopPause = delay + repeatDelay,
      easing = @(t) t * duration < duration ? t : 0
    }]
  }
}

let withGlareEffect = @(child, parentWidth, timeParams = null, positionParams = null, animParams = null) {
  clipChildren = true
  children = [
    child
    mkGlare(parentWidth, timeParams, positionParams, animParams)
  ]
}

return {
  mkGlare
  commonGlare = mkGlare(hdpx(500))
  withGlareEffect

  defGlareWidth
}