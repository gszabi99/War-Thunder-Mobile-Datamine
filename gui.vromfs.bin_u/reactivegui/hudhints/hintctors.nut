from "%globalsDarg/darg_library.nut" import *
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let teamColors = require("%rGui/style/teamColors.nut")

let defBgColor = 0x66202020
let winBgColor = 0x66663900
let failBgColor = 0x66550101
let warningBgColor = 0x66664102 
let hintWidth = hdpx(800)
let hintSideGradWidth = hdpx(150)
let maxHintWidth = min(saSize[0] - hdpx(1100), hintWidth)
let textGap = hdpx(10)

let appearTime = 0.4
let bounceTime = 0.35
let fadeOutTime = 0.3


let fontByWidth = @(text, width) calc_str_box(text, fontSmall)[0] > width
  ? fontTinyShaded : fontSmallShaded

let mkGradientBlock = @(color, children, width = hintWidth, padding = hdpx(10)) {
  size = [width, SIZE_TO_CONTENT]
  children = [
    {
      size = flex()
      rendObj = ROBJ_9RECT
      image = gradTranspDoubleSideX
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
}.__update(fontByWidth(text, width), ovr)

let errorText = @(text, ovr = {}) {
  size = [0.3 * saSize[0], SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color = 0xFFFF1010
}.__update(fontVeryTinyShaded, ovr)

let simpleText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color = 0xFFFFFFFF
  colorTable = teamColors
}.__update(fontSmallShaded, ovr)

let warningText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color = Color(255,  90,  82)
  colorTable = teamColors
  animations = [
    { prop = AnimProp.opacity, from = 0.0, to = 1.0, easing = CosineFull, duration = 0.8, play = true, loop = true  }
  ]
}.__update(fontSmallShaded, ovr)

function mkTextWithIcon(text, icon, iconSize, width) {
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

function simpleTextWithIcon(text, icon, bgColor, width) {
  let imgSize = array(2, hdpx(30)).map(@(v) v.tointeger())
  let textWidth = width - imgSize[0] - textGap
  let content = {
    size = [width, SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = textGap
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      mkTextByWidth(text, textWidth,
        { size = SIZE_TO_CONTENT, halign = ALIGN_LEFT, maxWidth = textWidth })
      {
        rendObj = ROBJ_IMAGE
        size = imgSize
        image = Picture($"{icon}:{imgSize[0]}:{imgSize[1]}")
      }
    ]
  }
  return mkGradientBlock(bgColor, content, width)
}

function commonHintCtor(hint, bgColor, width = hintWidth) {
  let res = mkGradientBlock(bgColor, mkTextByWidth(hint?.text ?? loc(hint?.locId ?? ""), width))
  return hint?.key == null ? res : res.__update({ key = hint.key })
}

function expHint(hint) {
  let res = mkGradientBlock(defBgColor, simpleText(hint.text, { maxWidth = maxHintWidth }.__update(fontSmallShaded)))
  return hint?.key == null ? res : res.__update({ key = hint.key })
}

let hintCtors = {
  win = @(hint, _) commonHintCtor(hint, winBgColor)
  fail = @(hint, _) commonHintCtor(hint, failBgColor)
  mission = @(hint, _) commonHintCtor(hint, defBgColor, isWidescreen ? hintWidth : hdpx(600))
  expHint = @(hint, _) expHint(hint)

  warningWithIcon = @(hint, _) mkGradientBlock(warningBgColor,
    mkTextWithIcon(hint?.text ?? "", hint?.icon, hint?.iconSize, maxHintWidth),
    maxHintWidth,
    hdpx(10))

  errorText = @(hint, fontOvr) errorText(hint.text, fontOvr)
  simpleText = @(hint, fontOvr) simpleText(hint.text, { maxWidth = maxHintWidth }.__update(fontOvr))
  simpleTextTiny = @(hint, _) simpleText(hint.text,
    { halign = ALIGN_CENTER, maxWidth = maxHintWidth }.__update(fontTiny))
  simpleTextTinyGrad = @(hint, _) mkGradientBlock(defBgColor, simpleText(hint.text,
    { halign = ALIGN_CENTER }.__update(fontTiny)), hintWidth, 0)
  warningTextTiny = @(hint, _) warningText(hint.text,
      { halign = ALIGN_CENTER, maxWidth = maxHintWidth }.__update(fontTiny))
  chatLogTextTiny = @(hint, fontOvr) simpleText(hint.text,
    { halign = ALIGN_CENTER }.__update(fontTiny, fontOvr))
  simpleTextWithIcon = @(hint, _) simpleTextWithIcon(hint?.text ?? "", hint?.icon, defBgColor, maxHintWidth)
}

function registerHintCreator(id, ctor) {
  if (id in hintCtors) {
    assert(false, $"try to register duplicate hint creator {id}")
    return
  }
  hintCtors[id] <- ctor
}

return {
  hintCtors = freeze(hintCtors)
  defaultHintCtor = @(hint, _) commonHintCtor(hint, defBgColor)
  registerHintCreator
  mkGradientBlock
  maxHintWidth

  failBgColor
  defBgColor
}