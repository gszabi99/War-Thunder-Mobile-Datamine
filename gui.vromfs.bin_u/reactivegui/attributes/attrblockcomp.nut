from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { playSound } = require("sound_wt")

let { btnTextDec, btnTextInc, btnBg, slider, mkSliderKnob, sliderValueSound } = require("%rGui/components/slider.nut")
let { textColor, badTextColor, hoverColor } = require("%rGui/style/stdColors.nut")
let { getSpCostText, setAttribute } = require("%rGui/attributes/attrState.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")

let MAX_ATTRIBUTE_INDICATORS = 5

let progressBtnSize = evenPx(72)
let progressBtnGap = hdpx(30)
let rowHeight = hdpx(100)
let costColW = hdpx(55)
let rowsPosPadL = progressBtnSize + progressBtnGap
let rowsPosPadR = rowsPosPadL + progressBtnGap + costColW
let knobWidth = evenPx(42)
let knobHeight = evenPx(21)
let sliderTouchableHeight = knobHeight + hdpx(44)
let cellH = evenPx(21)
let cellGap = hdpx(5)
let infoImgSize = hdpxi(30)
let pageWidth = hdpx(855)
let sliderWidth = pageWidth * 0.6

let cellColorFilled = 0xFF10AFE2
let cellColorNew    = 0xFF7FE5FF
let cellColorCanBuy = 0xFF476269
let cellColorEmpty  = 0x00000000

let newValueColor = 0xFF90FAFA

let glareWidth = hdpx(32)
let incBtnAnimDuration = 0.3
let incBtnAnimRepeat = 2

let startIncBtnGlare = @() anim_start("incBtnGlareAnim")

let boost_cooldown = 500
local lastClickTime = 0

let progressBtnBase = {
  size = [progressBtnSize, progressBtnSize]
  behavior = Behaviors.Button
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  transitions = [{ prop = AnimProp.scale, duration = 0.1, easing = InOutQuad }]
}

let incBtnGlare = @() {
  rendObj = ROBJ_IMAGE
  size = [glareWidth, progressBtnSize]
  image = gradTranspDoubleSideX
  color = 0x00A0A0A0
  transform = { translate = [-progressBtnSize / 2, -progressBtnSize / 2], rotate = 45 }
  animations = [{
    prop = AnimProp.translate
    duration = incBtnAnimDuration
    to = [progressBtnSize / 2, progressBtnSize / 2]
    trigger = "incBtnGlareAnim"
  }]
}

let progressBtnContentBase = {
  size = [progressBtnSize, progressBtnSize]
  rendObj = ROBJ_MASK
  image = Picture($"ui/gameuiskin#rhombus.svg:{progressBtnSize}:{progressBtnSize}:P")
  halign = ALIGN_CENTER
}

let mkProgressBtnContentDec = @(isAvailable) @(sf)
  @() progressBtnContentBase.__merge({
    watch = isAvailable
    opacity = isAvailable.get() ? 1 : 0.33
    children = [
      bgShaded.__merge({ size = flex() })
      btnBg.__merge({ size  = flex() })
      sf & S_HOVER ? btnTextDec.__merge({ color = hoverColor }) : btnTextDec
    ]
  })

let mkProgressBtnContentInc = @(isAvailable) @(sf)
  @() progressBtnContentBase.__merge({
    watch = isAvailable
    clipChildren = true
    opacity = isAvailable.get() ? 1 : 0.33
    children = [
      bgShaded.__merge({ size = flex() })
      btnBg.__merge({ size  = flex() })
      sf & S_HOVER ? btnTextInc.__merge({ color = hoverColor }) : btnTextInc
      isAvailable.get() ? incBtnGlare : null
    ]
  })

function mkProgressBtn(childrenCtor, onClick) {
  let stateFlags = Watched(0)
  return @() progressBtnBase.__merge({
    watch = stateFlags
    onClick
    onElemState = @(v) stateFlags(v)
    children = childrenCtor(stateFlags.get())
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
  })
}

let txt = @(ovr) {
  rendObj = ROBJ_TEXT
  behavior = Behaviors.Marquee
  color = textColor
  fontFx = FFT_GLOW
  fontFxFactor = hdpx(64)
  fontFxColor = 0xFF000000
}.__merge(fontTiny, ovr)

let mkRowLabel = @(label) txt({
  size=[flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_TOP
  valign = ALIGN_BOTTOM
  text = label
})

let valueCtors = {
  [ROBJ_TEXT] = @(value, color) txt({ text = value, color }),
  [ROBJ_IMAGE] = @(value, _) mkCurrencyImage(value, infoImgSize)
}

let mkValuesList = @(cfgList, color, ovr = {}) {
  flow = FLOW_HORIZONTAL
  children = cfgList.map(@(c) valueCtors?[c?.ctor](c?.value, color))
    .filter(@(v) v != null)
}.__update(ovr)

let toValTxt = txt({ text = " >>> ", color = newValueColor })

let mkRowValue = @(curValueData, selValueData) {
  size = SIZE_TO_CONTENT
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  valign = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  children = [
    @() mkValuesList(curValueData.get(), textColor, { watch = curValueData })
    @() {
      watch = selValueData
      flow = FLOW_HORIZONTAL
      children = selValueData.get().len() == 0 ? null
        : [
            toValTxt
            mkValuesList(selValueData.get(), newValueColor)
          ]
    }
  ]
}

let mkNextIncCost = @(nextIncCost, canInc, totalSp) {
  size = [costColW, SIZE_TO_CONTENT]
  children = @() totalSp.get() > 0
    ? txt({
        watch = [totalSp, nextIncCost, canInc]
        hplace = ALIGN_RIGHT
        color = (canInc.get() || nextIncCost.get() == 0) ? textColor : badTextColor
        text = nextIncCost.get() > 0
          ? getSpCostText(nextIncCost.get())
          : loc("ui/maximum/short")
      })
    : { watch = [ totalSp, nextIncCost, canInc ] }
}

function mkRowCell(cellColor, onClick, level, hoveredLevel, isInteractive) {
  local stateFlags = Watched(0)
  let needHover = Computed(@() isInteractive.get() && hoveredLevel.get() >= level)
  return @() {
    watch = [needHover, isInteractive]
    key = level
    size = [flex(), cellH]
    rendObj = ROBJ_BOX
    fillColor = 0xFF000000
    borderColor = needHover.get() ? 0xFFE0ECF4 : 0xFF383B3D
    borderWidth = hdpx(1)
    borderRadius = hdpx(5)
    padding = hdpx(3)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = isInteractive.get() ? Behaviors.Button : null
    function onElemState(sf) {
      let wasHovered = (stateFlags.get() & S_HOVER) != 0
      let isHovered = (sf & S_HOVER) != 0
      stateFlags(sf)
      if (isHovered == wasHovered)
        return
      if (isHovered && hoveredLevel.get() < level)
        hoveredLevel.set(level)
      else if (!isHovered && hoveredLevel.get() == level)
        hoveredLevel.set(-1)
    }
    clickableInfo = loc("mainmenu/btnSelect")
    onClick
    children = @() {
      watch = cellColor
      size = flex()
      rendObj = ROBJ_BOX
      fillColor = cellColor.get()
      borderWidth = 0
      borderRadius = hdpx(2)
      borderColor = 0
    }
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.8, 0.8] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
  }
}

function applyAttrRowChange(catId, attrId, tryValue, selLevel, minLevel, maxLevel) {
  local val = clamp(tryValue, minLevel.get(), maxLevel.get())
  if (val == selLevel.get() && tryValue <= maxLevel.get())
    val = max(val - 1, minLevel.get())
  if (val == selLevel.get())
    return false
  playSound("click")
  setAttribute(catId, attrId, val)
  lastClickTime = get_time_msec()
  return true
}

let knobCtor = @(relValue, stateFlags, fullW)
  mkSliderKnob(relValue, stateFlags, fullW,
    {
      size = [knobWidth, knobHeight],
      rendObj = ROBJ_SOLID,
    })

function mkProgressBarSlider(minLevel, selLevel, maxLevel, totalLevels, mkCellOnClick) {
  let intermediateValue = Watched(selLevel.get())

  selLevel.subscribe(@(v) intermediateValue.set(v))
  intermediateValue.subscribe(function(v) {
    if (v != selLevel.get())
      deferOnce(mkCellOnClick(v))
  })

  let sliderOverride = {
    min = 0
    max = totalLevels
    size = [sliderWidth, sliderTouchableHeight]
    function onChange(v) {
      if (v < minLevel.get() || v > maxLevel.get())
        return
      sliderValueSound()
      intermediateValue.set(v)
    }
  }

  return slider(intermediateValue, sliderOverride, knobCtor)
}

function mkProgressBarIndicators(minLevel, selLevel, maxLevel, totalLevels, mkCellOnClick) {
  let hoveredLevel = Watched(-1)

  return array(totalLevels).map(function(_, i) {
    let level = i + 1
    let cellColor = Computed(@() level <= minLevel.get() ? cellColorFilled
      : level <= selLevel.get() ? cellColorNew
      : level <= maxLevel.get() ? cellColorCanBuy
      : cellColorEmpty)
    let isInteractive = Computed(@() level > minLevel.get())
    return mkRowCell(cellColor, mkCellOnClick(level), level, hoveredLevel, isInteractive)
  })
}

let mkRowProgressBar = @(minLevel, selLevel, maxLevel, totalLevels, mkCellOnClick) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = cellGap
}.__update(totalLevels > MAX_ATTRIBUTE_INDICATORS
  ? { children = mkProgressBarSlider(minLevel, selLevel, maxLevel, totalLevels, mkCellOnClick) }
  : {
      size = [sliderWidth, SIZE_TO_CONTENT]
      children = mkProgressBarIndicators(minLevel, selLevel, maxLevel, totalLevels, mkCellOnClick)
    })

return {
  mkProgressBtnContentDec
  mkProgressBtnContentInc
  mkRowProgressBar
  mkProgressBtn
  mkNextIncCost
  mkRowLabel
  mkRowValue

  applyAttrRowChange
  startIncBtnGlare
  incBtnAnimRepeat
  boost_cooldown
  progressBtnGap
  lastClickTime
  rowsPosPadL
  rowsPosPadR
  rowHeight
  pageWidth
}
