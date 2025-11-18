from "%globalsDarg/darg_library.nut" import *
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { hudRedColor } = require("%rGui/style/hudColors.nut")

let debufBlinkTime = 0.7
let debuffColor = hudRedColor
let debuffBlinkColor = 0xFFE28010 

let debuffAnims = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.3, easing = OutQuad, play = true }
  { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.5, 1.5], duration = debufBlinkTime,
    easing = DoubleBlink, play = true }
  { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.5, 1.5], duration = debufBlinkTime,
    easing = DoubleBlink, play = true, delay = debufBlinkTime }
  { prop = AnimProp.color, from = debuffColor, to = debuffBlinkColor, duration = debufBlinkTime,
    easing = DoubleBlink, play = true }
  { prop = AnimProp.color, from = debuffColor, to = debuffBlinkColor, duration = debufBlinkTime,
    easing = DoubleBlink, play = true, delay = debufBlinkTime }
  { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, easing = OutQuad, playFadeOut = true }
]

let mkDebuffIcon = @(image, iconSize) {
  size = [iconSize, iconSize]
  rendObj = ROBJ_IMAGE
  color = debuffColor
  image = Picture($"{image}:{iconSize}:{iconSize}:P")
  transform = {}
  animations = debuffAnims
}

let mkDebuffIconEditView = @(image, iconSize) {
  size = [iconSize, iconSize]
  rendObj = ROBJ_IMAGE
  color = borderColor
  image = Picture($"{image}:{iconSize}:{iconSize}:P")
}

return {
  mkDebuffIcon
  mkDebuffIconEditView
}