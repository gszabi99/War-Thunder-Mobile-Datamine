from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "sound_wt" import playSound
from "%rGui/attributes/attrState.nut" import getSpCostText, setAttribute
from "%rGui/components/currencyComp.nut" import mkCurrencyImage
from "%rGui/components/slider.nut" import btnTextDec, btnTextInc, mkIconBtn, btnBg, slider, mkSliderKnob,
  mkSliderOnChangeSound
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, mkColoredGradientY
from "%rGui/style/stdColors.nut" import textColor, badTextColor, hoverColor, selectColor


let progressBtnSize = evenPx(72)
const progressBtnGap = hdpx(30)
const rowHeight = hdpx(100)
const costColW = hdpx(55)
let rowsPosPadL = progressBtnSize + progressBtnGap
let rowsPosPadR = rowsPosPadL + progressBtnGap + costColW
let knobWidth = evenPx(13)
let knobHeight = evenPx(31)
let sliderTouchableHeight = knobHeight + hdpx(44)
let cellH = evenPx(21)
const cellGap = hdpx(5)
const infoImgSize = hdpxi(30)
const pageWidth = hdpx(855)
const sliderWidth = pageWidth * 0.6

let cellColorFilled = selectColor
const cellColorNew    = 0xFFBCD5FF
const cellColorCanBuy = 0xFF53688C
const cellColorEmpty  = 0x00000000

const newValueColor = cellColorNew

const glareWidth = hdpx(32)
const incBtnAnimDuration = 0.3
const incBtnAnimRepeat = 2

let startIncBtnGlare = @() anim_start("incBtnGlareAnim")

const boost_cooldown = 500
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
      bgShaded.__merge({ size = FLEX })
      btnBg.__merge({ size  = FLEX })
      mkIconBtn(sf & S_HOVER ? btnTextDec.__merge({ color = hoverColor }) : btnTextDec)
    ]
  })

let mkProgressBtnContentInc = @(isAvailable) @(sf)
  @() progressBtnContentBase.__merge({
    watch = isAvailable
    clipChildren = true
    opacity = isAvailable.get() ? 1 : 0.33
    children = [
      bgShaded.__merge({ size = FLEX })
      btnBg.__merge({ size  = FLEX })
      mkIconBtn(sf & S_HOVER ? btnTextInc.__merge({ color = hoverColor }) : btnTextInc)
      isAvailable.get() ? incBtnGlare : null
    ]
  })

function mkProgressBtn(childrenCtor, onClick) {
  let stateFlags = Watched(0)
  return @() progressBtnBase.__merge({
    watch = stateFlags
    onClick
    onElemState = @(v) stateFlags.set(v)
    children = childrenCtor(stateFlags.get())
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
  })
}

let txt = @(ovr) {
  rendObj = ROBJ_TEXT
  behavior = Behaviors.Marquee
  color = textColor
}.__merge(fontTinyShaded, ovr)

let mkRowLabel = @(label) txt({
  size=FLEX_H
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
  size = const [costColW, SIZE_TO_CONTENT]
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
    size = [FLEX, cellH]
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
      stateFlags.set(sf)
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
      size = FLEX
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
  setAttribute(catId, attrId, val)
  lastClickTime = get_time_msec()
  return true
}

let knobCtor = @(relValue, stateFlags, fullW)
  mkSliderKnob(relValue, stateFlags, fullW,
    {
      rendObj = ROBJ_BOX
      size = [knobWidth, knobHeight]
      borderColor = 0xFF000000
      borderWidth = hdpx(2)
      children = {
        rendObj = ROBJ_IMAGE
        size = FLEX
        image = mkColoredGradientY(0xFFFFFFFF, 0xFF555555)

      }
    })

function mkProgressBarSlider(selLevel, totalLevels, onChangeValue, hasChanges) {
  let sliderOverride = {
    min = 0
    max = totalLevels
    size = [sliderWidth, sliderTouchableHeight]
    onChange = mkSliderOnChangeSound(onChangeValue)
    color = hasChanges ? cellColorNew : selectColor
  }
  return slider(selLevel, sliderOverride, knobCtor)
}

function mkProgressBarIndicators(minLevel, selLevel, maxLevel, totalLevels, onChangeValue) {
  let hoveredLevel = Watched(-1)

  return array(totalLevels).map(function(_, i) {
    let level = i + 1
    let cellColor = Computed(@() level <= minLevel.get() ? cellColorFilled
      : level <= selLevel.get() ? cellColorNew
      : level <= maxLevel.get() ? cellColorCanBuy
      : cellColorEmpty)
    let isInteractive = Computed(@() level > minLevel.get())
    function onClick() {
      if (onChangeValue(level))
        playSound("click")
      else
        playSound("meta_denied")
    }
    return mkRowCell(cellColor, onClick, level, hoveredLevel, isInteractive)
  })
}

let mkRowProgressBar = @(minLevel, selLevel, maxLevel, totalLevels, onChangeValue) {
  size = const [sliderWidth, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = cellGap
  children = mkProgressBarIndicators(minLevel, selLevel, maxLevel, totalLevels, onChangeValue)
}

return {
  mkProgressBtnContentDec
  mkProgressBtnContentInc
  mkProgressBarSlider
  mkRowProgressBar
  mkProgressBtn
  mkNextIncCost
  mkRowLabel
  mkRowValue
  knobCtor

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
  progressBtnSize
}
