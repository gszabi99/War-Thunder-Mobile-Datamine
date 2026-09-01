from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, gradDoubleTexOffset


const textBlockDuration = 0.3
const textOpacityDuration = 0.1
const textScaleDuration = textOpacityDuration
const borderColorDelay = textBlockDuration
const borderColorDuration = 0.5
const textBlockScaleDuration = textBlockDuration / 3
const textBlockScaleDelay = textBlockScaleDuration

const orangeBgColor = 0x66663900
const noBgColor = 0x00000000
const blackBgColor = 0xFF000000

let animatedTextBlock = @(text) {
  size = FLEX
  rendObj = ROBJ_9RECT
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  image = gradTranspDoubleSideX
  texOffs = [0 , gradDoubleTexOffset]
  screenOffs = [0, hdpx(250)]
  transform = {}
  color = orangeBgColor
  animations = [
    { prop = AnimProp.scale, from = [0.7, 0.1], to = [0.8, 0.1], duration = textBlockScaleDuration,
      easing = InQuad, play = true }
    { prop = AnimProp.scale, from = [0.8, 0.1], to = [1.0, 1.0], duration = textBlockScaleDuration,
      easing = InQuad, play = true, delay = textBlockScaleDelay }
    { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.05, 1.2], duration = textBlockScaleDuration,
      easing = CosineFull, play = true, delay = (textBlockScaleDelay) * 2 }
  ]
  children = {
    rendObj = ROBJ_TEXT
    text
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0.0, to = 0.0, duration = textOpacityDuration, play = true }
      { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = textOpacityDuration, play = true,
        easing = InQuad }
      { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.15, 1.15], duration = textScaleDuration,
        play = true, easing = InQuad }
    ]
  }.__update(fontVeryLargeShaded)
}

let purchaseEffectText = @(text) {
  rendObj = ROBJ_BOX
  size = const [sw(100), hdpx(180)]
  hplace = ALIGN_CENTER
  margin = const [sh(10), 0, 0, 0]
  borderWidth = const [8, 0]
  borderColor = blackBgColor
  transform = {}
  animations = [
    { prop = AnimProp.borderColor, from = noBgColor, to = noBgColor,
      play = true, duration = borderColorDelay }
    { prop = AnimProp.borderColor, from = noBgColor, to = blackBgColor,
      easing = InQuad, play = true, delay = borderColorDelay, duration = borderColorDuration }
  ]
  children = animatedTextBlock(text)
}

return { purchaseEffectText }
