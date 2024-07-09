from "%globalsDarg/darg_library.nut" import *
let { debounce } = require("%sqstd/timers.nut")
let { sizePosToBox, getLinkArrowMiddleCfg, createHighlight } = require("tutorialUtils.nut")
let { btnAUp } = require("%rGui/controlsMenu/gpActBtn.nut")

let borderWidth = hdpx(1)
let defMsgPadding = [hdpx(20), hdpx(40)] //to not be too close to highlighted objects.

function mkSizeTable(box, content) {
  let { l, r, t, b } = box
  return {
    size = [r - l, b - t]
    pos = [l, t]
  }.__update(content)
}

let lightCtor = @(box, override = {}) mkSizeTable(box, {
  rendObj = ROBJ_BOX
  borderWidth
  borderColor = 0xFFFFFFFF
  behavior = Behaviors.Button
}.__update(override))

let darkCtor = @(box) mkSizeTable(box, {
  rendObj = ROBJ_SOLID
  color = 0xC0000000
})

let anyTapHint = {
  rendObj = ROBJ_TEXT
  text = loc("TapAnyToContinue")
  color = 0xFFA0A0A0
}.__update(fontSmall)

let nextKeyHintCtor = @(nextKeyAllowed, onClick) onClick == null ? null
  : @() {
      watch = nextKeyAllowed
      children = !nextKeyAllowed.value ? null : anyTapHint
        .__merge({ hotkeys = [[$"{btnAUp} | Space", onClick]] })
      behavior = Behaviors.Button
      onClick
      sound = { click  = "click" }
    }

let messageCtor = @(text, nextKeyAllowed, onNext, textOverride = {}) {
  padding = defMsgPadding
  gap = hdpx(20)
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    { //include only because padding not correct count by calc_comp_size while in textarea.
      maxWidth = fsh(80)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text
      halign = ALIGN_CENTER
    }.__update(fontMedium, textOverride)
    nextKeyHintCtor(nextKeyAllowed, onNext)
  ]
}

let skipTrigger = {}
let skipStateFlags = Watched(0)
let isSkipPushed = Watched(false) //update with debounce, to not change value too fast on calc comp size
skipStateFlags.subscribe(debounce(@(v) isSkipPushed((v & S_ACTIVE) != 0), 0.01))
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

let mkCutBg = @(boxes) boxes == null || boxes.len() == 0
  ? darkCtor({ t = 0, b = sh(100), l = 0, r = sw(100) })
  : {
      size = flex()
      children = createHighlight(boxes, @(_) null, darkCtor)
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

  //components to reuse from outside
  mkSizeTable
  nextKeyHintCtor
  defMsgPadding
})