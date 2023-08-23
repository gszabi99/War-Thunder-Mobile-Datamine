from "%globalsDarg/darg_library.nut" import *
let { playSound } = require("sound_wt")
let { get_time_msec } = require("dagor.time")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { btnTextDec, btnTextInc, btnBg } = require("%rGui/components/slider.nut")
let { getUnitTagsShop } = require("%appGlobals/unitTags.nut")
let { curCategory, curCategoryId, totalUnitSp, leftUnitSp, getSpCostText, unitAttributes,
  selAttributes, getMaxAttrLevelData, setAttribute, attrUnitName, attrUnitType
} = require("%rGui/unitAttr/unitAttrState.nut")
let { getAttrLabelText, getAttrValData } = require("%rGui/unitAttr/unitAttrValues.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { textColor, badTextColor, hoverColor } = require("%rGui/style/stdColors.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { unitMods } = require("%rGui/unitMods/unitModsState.nut")
let buyUnitLevelWnd = require("buyUnitLevelWnd.nut")

let progressBtnSize = evenPx(72)
let progressBtnGap = hdpx(30)
let rowHeight = hdpx(100)
let costColW = hdpx(55)
let rowsPosPadL = progressBtnSize + progressBtnGap
let rowsPosPadR = rowsPosPadL + progressBtnGap + costColW
let cellH = hdpx(20)
let cellGap = hdpx(5)
let infoImgSize = hdpxi(30)

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

let progressBtnBase = {
  size = [ progressBtnSize, progressBtnSize ]
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
    opacity = isAvailable.value ? 1 : 0.33
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
    opacity = isAvailable.value ? 1 : 0.33
    children = [
      bgShaded.__merge({ size = flex() })
      btnBg.__merge({ size  = flex() })
      sf & S_HOVER ? btnTextInc.__merge({ color = hoverColor }) : btnTextInc
      isAvailable.value ? incBtnGlare : null
    ]
  })

let function mkProgressBtn(childrenCtor, onClick) {
  let stateFlags = Watched(0)
  return @() progressBtnBase.__merge({
    watch = stateFlags
    onClick
    onElemState = @(v) stateFlags(v)
    children = childrenCtor(stateFlags.value)
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
  })
}

let txt = @(ovr) {
  rendObj = ROBJ_TEXT
  color = textColor
  fontFx = FFT_GLOW
  fontFxFactor = hdpx(64)
  fontFxColor = 0xFF000000
}.__merge(fontTiny, ovr)

let mkRowLabel = @(label) txt({
  vplace = ALIGN_TOP
  valign = ALIGN_BOTTOM
  text = label
})

let valueCtors = {
  [ROBJ_TEXT] = @(value, color) txt({ text = value,  color }),
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
    @() mkValuesList(curValueData.value, textColor, { watch = curValueData })
    @() {
      watch = selValueData
      flow = FLOW_HORIZONTAL
      children = selValueData.value.len() == 0 ? null
        : [
            toValTxt
            mkValuesList(selValueData.value, newValueColor)
          ]
    }
  ]
}

let mkNextIncCost = @(nextIncCost, canInc, totalSp) {
  size = [ costColW, SIZE_TO_CONTENT ]
  children = @() totalSp.value > 0
    ? txt({
        watch = [ totalSp, nextIncCost, canInc ]
        hplace = ALIGN_RIGHT
        color = (canInc.value || nextIncCost.value == 0) ? textColor : badTextColor
        text = nextIncCost.value > 0
          ? getSpCostText(nextIncCost.value)
          : loc("ui/maximum/short")
      })
    : { watch = [ totalSp, nextIncCost, canInc ] }
}

let function mkRowCell(cellColor, onClick, level, hoveredLevel, isInteractive) {
  local stateFlags = Watched(0)
  let needHover = Computed(@() isInteractive.value && hoveredLevel.value >= level)
  return @() {
    watch = [needHover, isInteractive]
    key = level
    size = [ flex(), cellH ]
    rendObj = ROBJ_BOX
    fillColor = 0xFF000000
    borderColor = needHover.value ? 0xFFE0ECF4 : 0xFF383B3D
    borderWidth = hdpx(1)
    borderRadius = hdpx(5)
    padding = hdpx(3)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = isInteractive.value ? Behaviors.Button : null
    function onElemState(sf) {
      let wasHovered = (stateFlags.value & S_HOVER) != 0
      let isHovered = (sf & S_HOVER) != 0
      stateFlags(sf)
      if (isHovered == wasHovered)
        return
      if (isHovered && hoveredLevel.value < level)
        hoveredLevel(level)
      else if (!isHovered && hoveredLevel.value == level)
        hoveredLevel(-1)
    }
    clickableInfo = loc("mainmenu/btnSelect")
    onClick
    children = @() {
      watch = cellColor
      size = flex()
      rendObj = ROBJ_BOX
      fillColor = cellColor.value
      borderWidth = 0
      borderRadius = hdpx(2)
      borderColor = 0
    }
    transform = { scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.8, 0.8] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
  }
}

local  lastClickTime = 0

let function applyAttrRowChange(catId, attrId, tryValue, selLevel, minLevel, maxLevel) {
  local val = clamp(tryValue, minLevel.value, maxLevel.value)
  if (val == selLevel.value && tryValue <= maxLevel.value)
    val = max(val - 1, minLevel.value)
  if (val == selLevel.value)
    return false
  playSound("click")
  setAttribute(catId, attrId, val)
  lastClickTime = get_time_msec()
  return true
}

let function applyAttrRowChangeOrBoost(catId, attr, tryValue, selLevel, minLevel, maxLevel) {
  if (!applyAttrRowChange(catId, attr.id, tryValue, selLevel, minLevel, maxLevel)) {
    let currTime = get_time_msec()
    if (lastClickTime + boost_cooldown < currTime) { //cooldown check
      let nextIncCost = attr.levelCost?[selLevel.value] ?? 0 //for max level reach condition
      if (nextIncCost > 0)
        buyUnitLevelWnd(attrUnitName.value)
    }
  }
}

let function mkRowProgressBar(minLevel, selLevel, maxLevel, totalLevels, mkCellOnClick) {
  let hoveredLevel = Watched(-1)
  return {
    size = [ flex(), SIZE_TO_CONTENT ]
    flow = FLOW_HORIZONTAL
    gap = cellGap
    children = array(totalLevels).map(function(_, i) {
      let level = i + 1
      let cellColor = Computed(@() level <= minLevel.value ? cellColorFilled
        : level <= selLevel.value ? cellColorNew
        : level <= maxLevel.value ? cellColorCanBuy
        : cellColorEmpty)
      let isInteractive = Computed(@() level > minLevel.value)
      return mkRowCell(cellColor, mkCellOnClick(level), level, hoveredLevel, isInteractive)
    })
  }
}

let function mkAttrRow(attr) {
  let shopCfg = getUnitTagsShop(attrUnitName.value)
  let catId = curCategoryId.value
  let minLevel = Computed(@() unitAttributes.value?[catId][attr.id] ?? 0) // Current applied level
  let selLevel = Computed(@() max(selAttributes.value?[catId][attr.id] ?? minLevel.value, minLevel.value)) // User selected new level
  let maxLevel = Computed(@() getMaxAttrLevelData(attr, selLevel.value, leftUnitSp.value).maxLevel) // Can buy max level
  let totalLevels = attr.levelCost.len() // Total level progress steps
  let nextIncCost = Computed(@() attr.levelCost?[selLevel.value] ?? 0)
  let canDec = Computed(@() selLevel.value > minLevel.value)
  let canInc = Computed(@() selLevel.value < maxLevel.value)
  let attrLocName = getAttrLabelText(attrUnitType.value, attr.id)
  let mkBtnOnClick = @(diff) @() applyAttrRowChangeOrBoost(catId, attr, selLevel.value + diff, selLevel, minLevel, maxLevel)
  let mkCellOnClick = @(val) @() applyAttrRowChange(catId, attr.id, val, selLevel, minLevel, maxLevel)
  let curValueData = Computed(@() getAttrValData(attrUnitType.value, attr, minLevel.value, shopCfg, serverConfigs.value, unitMods.value))
  let selValueData = Computed(@() selLevel.value > minLevel.value
    ? getAttrValData(attrUnitType.value, attr, selLevel.value, shopCfg, serverConfigs.value, unitMods.value)
    : [])

  return {
    size = [ flex(), rowHeight ]
    flow = FLOW_HORIZONTAL
    gap = progressBtnGap
    valign = ALIGN_CENTER
    children = [
      mkProgressBtn(mkProgressBtnContentDec(canDec), mkBtnOnClick(-1))
      {
        size = flex()
        valign = ALIGN_CENTER
        children = [
          mkRowLabel(attrLocName)
          mkRowValue(curValueData, selValueData)
          mkRowProgressBar(minLevel, selLevel, maxLevel, totalLevels, mkCellOnClick)
        ]
      }
      mkProgressBtn(mkProgressBtnContentInc(canInc), mkBtnOnClick(1))
      mkNextIncCost(nextIncCost, canInc, totalUnitSp)
    ]
  }
}

let unitAttrPage = @() {
  key = startIncBtnGlare
  watch = curCategory
  size = [ flex(), SIZE_TO_CONTENT ]
  onAttach = @() setInterval(incBtnAnimRepeat, startIncBtnGlare)
  onDetach = @() clearTimer(startIncBtnGlare)
  children = {
    key = curCategory.value
    size = [ flex(), SIZE_TO_CONTENT ]
    flow = FLOW_VERTICAL
    children = (curCategory.value?.attrList ?? []).map(mkAttrRow)
    animations = wndSwitchAnim
  }
}

return {
  unitAttrPage
  rowsPosPadL
  rowsPosPadR
  rowHeight
}
