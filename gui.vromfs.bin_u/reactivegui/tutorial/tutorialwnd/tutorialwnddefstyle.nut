from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { commonTextColor } = require("%rGui/style/stdColors.nut")
let { simpleHorGrad } = require("%rGui/style/gradients.nut")
let { sizePosToBox, getLinkArrowMiddleCfg, createHighlight, incBoxSizeUnlimited } = require("tutorialUtils.nut")
let { btnAUp } = require("%rGui/controlsMenu/gpActBtn.nut")


let borderWidth = hdpx(1)
let defMsgPadding = [hdpx(20), hdpx(40)] //to not be too close to highlighted objects.
let characterSize = [hdpxi(644), hdpxi(914)]
let shadeColor = 0xC0020B19
let msgBgColor = 0xCC000000
let msgBorderColor = 0x60484848
let msgBorderWidth = hdpxi(3)

let characters = {
  mary_with_notebook = "review_cue_1.avif"
  mary_points = "review_cue_2.avif"
  mary_salutes = "review_cue_3.avif"
  mary_points_sad = "review_cue_4.avif"
  mary_like = "review_cue_5.avif"
}
  .map(@(v) $"!ui/images/{v}")
let defaultCharacter = characters.mary_with_notebook

function mkSizeTable(box, content) {
  let { l, r, t, b } = box
  return {
    size = [r - l, b - t]
    pos = [l, t]
  }.__update(content)
}

let lightCtor = @(box, override = {}) mkSizeTable(incBoxSizeUnlimited(box, 2 * borderWidth), {
  rendObj = ROBJ_BOX
  borderWidth
  borderColor = 0xFFFFFFFF
  behavior = Behaviors.Button
}.__update(override))

let darkCtor = @(box) mkSizeTable(box, {
  rendObj = ROBJ_SOLID
  color = shadeColor
})

let anyTapHint = {
  rendObj = ROBJ_TEXT
  text = loc("TapAnyToContinue")
  color = 0xFFA0A0A0
}.__update(fontTiny)

let nextKeyHintCtor = @(nextKeyAllowed, onClick) onClick == null ? null
  : @() !nextKeyAllowed.get() ? { watch = nextKeyAllowed }
    : {
        watch = nextKeyAllowed
        size = [flex(), SIZE_TO_CONTENT]
        margin = [hdpx(10), 0, 0, 0]
        behavior = Behaviors.Button
        onClick
        sound = { click  = "click" }
        flow = FLOW_HORIZONTAL
        gap = hdpx(20)
        valign = ALIGN_CENTER
        children = [
          {
            size = [flex(), msgBorderWidth]
            rendObj = ROBJ_IMAGE
            image = simpleHorGrad
            color = msgBorderColor
          }
          anyTapHint.__merge({ hotkeys = [[$"{btnAUp} | Space", onClick]] })
          {
            size = [flex(), msgBorderWidth]
            rendObj = ROBJ_IMAGE
            image = simpleHorGrad
            color = msgBorderColor
            flipX = true
          }
        ]
      }

let messageCtor = @(text, nextKeyAllowed, onNext, textOverride = {}) {
  padding = defMsgPadding
  rendObj = ROBJ_BOX
  fillColor = msgBgColor
  borderColor = msgBorderColor
  borderWidth = msgBorderWidth
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    { //include only because padding not correct count by calc_comp_size while in textarea.
      maxWidth = characterSize[0]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text
      color = commonTextColor
      halign = ALIGN_CENTER
    }.__update(fontSmall, textOverride)
    nextKeyHintCtor(nextKeyAllowed, onNext)
  ]
}

let skipTrigger = {}
let skipStateFlags = Watched(0)
let isSkipPushed = Watched(false)
let updateSkipPushed = @() isSkipPushed.set((skipStateFlags.get() & S_ACTIVE) != 0)
skipStateFlags.subscribe(@(_) deferOnce(updateSkipPushed))
isSkipPushed.subscribe(@(v) v ? anim_start(skipTrigger) : anim_skip(skipTrigger))

let pSize = hdpx(40).tointeger()
let mkSkipProgress = @(stepSkipDelay, skipStep) {
  key = "skipProgress"
  size = [pSize, pSize]
  rendObj = ROBJ_PROGRESS_CIRCULAR
  image = Picture($"ui/gameuiskin#circular_progress_1.svg:{pSize}:{pSize}:K")
  fgColor = 0xFFFFFFFF
  bgColor = 0
  fValue = 0
  animations = [
    { prop = AnimProp.fValue, from = 0.0, to = 1.0, duration = stepSkipDelay, trigger = skipTrigger, onFinish = skipStep }
  ]
}

let mkCutBg = @(boxes, fullArea = {}) boxes == null || boxes.len() == 0
  ? darkCtor({ t = 0, b = sh(100), l = 0, r = sw(100) }.__update(fullArea))
  : {
      size = flex()
      children = createHighlight(boxes, @(_) null, darkCtor, fullArea)
    }

let skipBtnCtor = @(stepSkipDelay, skipStep, key) {
  key
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    mkSkipProgress(stepSkipDelay, skipStep)
    @() {
      watch = skipStateFlags
      key = "holdToSkip"
      behavior = Behaviors.Button
      onElemState = @(sf) skipStateFlags(sf)
      rendObj = ROBJ_TEXT
      text = loc("HoldToSkip")
      color = skipStateFlags.value & S_ACTIVE ? 0xFF808080
        : 0xA0A0A0A0
    }.__update(fontSmall)
  ]
  animations = [{ prop = AnimProp.opacity, from = 0, to = 1, duration = 3, play = true }]
}

let pointerSize = hdpx(70).tointeger()
let pointerAnimTime = 1.0
let pointerAnimOffset = hdpx(25)
let pointerArrowContent = {
  size = [pointerSize, pointerSize]
  rendObj = ROBJ_IMAGE
  color = 0xFF61B53A
  image = Picture($"ui/gameuiskin#arrow_tutor.svg:{pointerSize}:{pointerSize}:K")
  keepAspect = true
  transform = {}
  animations = [
    { prop = AnimProp.translate, from = [0, -pointerAnimOffset], to = [0, pointerAnimOffset],
      duration = pointerAnimTime, play = true, loop = true, easing = CosineFull }
    { prop = AnimProp.scale, from = [0.85, 0.85], to = [1.0, 1.0],
      duration = pointerAnimTime, play = true, loop = true, easing = CosineFull }
  ]
}

let pointerArrow = {
  padding = pointerAnimOffset
  children = pointerArrowContent
}

let mkPointerArrow = @(ovrW) {
  padding = pointerAnimOffset
  children = @() pointerArrowContent.__merge({ watch = ovrW }, ovrW.value)
}

function mkLinkArrow(boxFrom, boxTo) {
  local { pos, rotate } = getLinkArrowMiddleCfg(boxFrom, boxTo)
  let size = pointerSize + 2 * pointerAnimOffset
  pos = pos.map(@(v) v - 0.5 * size)
  return {
    box = sizePosToBox(array(2, size), pos)
    component = pointerArrow.__merge({ pos, transform = { rotate } })
  }
}

function characterCtor(charId, isRight = false) {
  if (charId != null && charId not in characters)
    logerr($"Unknown tutorial characterId = {charId}")
  let image = charId in characters ? characters[charId] : defaultCharacter
  return {
    size = characterSize
    rendObj = ROBJ_IMAGE
    image = Picture(image)
    keepAspect = true
    flipX = isRight
  }
}

return freeze({
  //required styles
  lightCtor
  darkCtor
  messageCtor
  skipBtnCtor
  pointerArrow
  mkPointerArrow
  mkLinkArrow
  mkCutBg
  characterCtor

  //components to reuse from outside
  mkSizeTable
  nextKeyHintCtor
  defMsgPadding
})