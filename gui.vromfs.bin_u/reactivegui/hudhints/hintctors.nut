from "%globalsDarg/darg_library.nut" import *
let { gradTranspDobuleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let teamColors = require("%rGui/style/teamColors.nut")

let defBgColor = 0x66125B5C
let winBgColor = 0x66663900
let failBgColor = 0x66550101
let warningBgColor = 0x66664102 //0xFFffa406
let hintWidth = hdpx(800)
let hintSideGradWidth = hdpx(150)
let warningHintWidth = min(saSize[0] - hdpx(1100), hintWidth)
let textGap = hdpx(10)

let appearTime = 0.4
let bounceTime = 0.35
let fadeOutTime = 0.3

let fontShade = {
  fontFx = FFT_GLOW
  fontFxFactor = max(64, hdpx(64))
  fontFxColor = 0xFF000000
}

let fontByWidth = @(text, width) calc_str_box(text, fontSmall)[0] > width
  ? fontTiny : fontSmall

let mkGradientBlock = @(color, children, width = hintWidth, padding = hdpx(20)) {
  size = [width, SIZE_TO_CONTENT]
  children = [
    {
      size = flex()
      rendObj = ROBJ_9RECT
      image = gradTranspDobuleSideX
      texOffs = [0,  gradDoubleTexOffset]
      screenOffs = [0, hintSideGradWidth]
      color
      transform = {}
      animations = [
        { prop = AnimProp.scale, from = [0.0, 1.0], to = [1.0, 1.0], duration = appearTime,
          easing = InQuad, play = true }
        { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.05, 1.2], delay = appearTime, duration = bounceTime,
          easing = CosineFull, play = true }
        { prop = AnimProp.scale, from = [1.0, 1.0], to = [0.0, 1.0], duration = fadeOutTime,
          easing = InQuad, playFadeOut = true }
      ]
    }
    {
      size = [flex(), SIZE_TO_CONTENT]
      margin = padding
      halign = ALIGN_CENTER
      children
      transform = {}
      animations = [
        { prop = AnimProp.opacity, from = 0.0, to = 0.0, duration = 0.5 * appearTime,
          easing = InQuad, play = true }
        { prop = AnimProp.opacity, from = 0.0, to = 1.0, delay = 0.5 * appearTime, duration = appearTime,
          easing = InQuad, play = true }
        { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.05, 1.2], delay = appearTime, duration = bounceTime,
          easing = CosineFull, play = true }
        { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = fadeOutTime,
          easing = OutQuad, playFadeOut = true }
      ]
    }
  ]
}

let mkTextByWidth = @(text, width = hintWidth, ovr = {}) {
  size = [width, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color = 0xFFFFFFFF
  halign = ALIGN_CENTER
  colorTable = teamColors
}.__update(fontByWidth(text, width), fontShade, ovr)

let errorText = @(text) {
  size = [0.3 * saSize[0], SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color = 0xFFFF1010
}.__update(fontVeryTiny, fontShade)

let simpleText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color = 0xFFFFFFFF
  colorTable = teamColors
}.__update(fontSmall, fontShade, ovr)

let function mkTextWithIcon(text, icon, iconSize, width) {
  let imgSize = (iconSize ?? array(2, hdpx(30))).map(@(v) v.tointeger())
  return {
    size = [width, SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = textGap
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = imgSize
        image = Picture($"{icon}:{imgSize[0]}:{imgSize[1]}")
      }
      mkTextByWidth(text, width - imgSize[0] - textGap,
        { size = SIZE_TO_CONTENT, halign = ALIGN_LEFT, maxWidth = width })
    ]
  }
}

let function defaultHintCtor(hint) {
  let res = mkGradientBlock(defBgColor, mkTextByWidth(hint?.text ?? loc(hint?.locId ?? "")))
  return hint?.key == null ? res : res.__update({ key = hint.key })
}

let hintCtors = {
  win = @(hint) mkGradientBlock(winBgColor, mkTextByWidth(hint?.text ?? ""))
  fail = @(hint) mkGradientBlock(failBgColor, mkTextByWidth(hint?.text ?? ""))

  warningWithIcon = @(hint) mkGradientBlock(warningBgColor,
    mkTextWithIcon(hint?.text ?? "", hint?.icon, hint?.iconSize, warningHintWidth),
    warningHintWidth,
    hdpx(10))

  errorText = @(hint) errorText(hint.text)
  simpleText = @(hint) simpleText(hint.text)
  simpleTextTiny = @(hint) simpleText(hint.text, { halign = ALIGN_CENTER }.__update(fontTiny))
}

let function registerHintCreator(id, ctor) {
  if (id in hintCtors) {
    assert(false, $"try to register duplicate hint creator {id}")
    return
  }
  hintCtors[id] <- ctor
}

return {
  hintCtors = freeze(hintCtors)
  defaultHintCtor
  registerHintCreator
  mkGradientBlock

  failBgColor
}