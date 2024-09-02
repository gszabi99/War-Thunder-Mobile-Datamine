from "%globalsDarg/darg_library.nut" import *
let { playSound } = require("sound_wt")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { translucentSlotButton, getBorderCommand, lineWidth, slotBtnSize,
  COMMADN_STATE
} = require("%rGui/components/translucentButton.nut")
let { myUnits, allUnitsCfg, curUnit } = require("%appGlobals/pServer/profile.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitLock, bgUnit, mkUnitSelectedGlow,
  mkUnitPlateBorder
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")
let { openUnitsTreeWnd } = require("%rGui/unitsTree/unitsTreeState.nut")
let { slots, setUnitToSlot, buyUnitSlot, newSlotPriceGold, slotsNeedAddAnim,
  getSlotAnimTrigger, onFinishSlotAnim, selectedSlotIdx
} = require("slotBarState.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { CS_COMMON } = require("%rGui/components/currencyStyles.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { slotBarTreeHeight, unitPlateSize, unitPlateHeader } = require("slotBarConsts.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { openUnitModsSlotsWnd } = require("%rGui/unitMods/unitModsSlotsState.nut")
let { mkSlotLevel } = require("%rGui/attributes/slotAttr/slotLevelComp.nut")
let { unseenSlotModsByCategory } = require("%rGui/unitMods/unitModsState.nut")
let { priorityUnseenMark, unseenSize } = require("%rGui/components/unseenMark.nut")
let { openSlotAttrWnd, unseenSlotAttrByIdx } = require("%rGui/attributes/slotAttr/slotAttrState.nut")
let { infoPanelWidth } = require("%rGui/unitsTree/unitsTreeComps.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")


let slotsGap = hdpx(4)
let gap = hdpx(10)
let marginVert = hdpx(5)
let buyIconSize = hdpxi(40)
let actionBtnSize = slotBtnSize
let actionBtnsBlockSize = [unitPlateSize[0], actionBtnSize[1] + unseenSize[0]]
let slotBarSize = [saSize[0] - defButtonMinWidth, unitPlateSize[1] + actionBtnsBlockSize[1] + unitPlateHeader + marginVert]
let slotBarUnitsTreePadding = hdpx(20)
let slotBarUnitsTreeWidth = saSize[0] - infoPanelWidth + saBorders[0] * 2

let aTimeSlotRemove = 0.5
let aTimeSlotAddAppear = 0.2
let aTimeSlotAddBlink = 0.3

let removeUnitTrigger = {}

let playSlotRemove = @() playSound("meta_unit_remove")
let playSlotRemoveDelayed = @() resetTimeout(0.01, playSlotRemove)

function skipRemoveAnim() {
  anim_skip(removeUnitTrigger)
  clearTimer(playSlotRemove)
}

let emptySlotText = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = loc("slotbar/empty")
}.__update(fontVeryTinyAccented)

let function emptySelectSlot(idx) {
  let isSelected = Computed(@() selectedSlotIdx.get() == idx)
  let stateFlags = Watched(0)
  return {
    key = "empty"
    size = unitPlateSize
    behavior = Behaviors.Button
    function onClick() {
      setUnitToSlot(idx)
      curSelectedUnit.set(null)
      selectedSlotIdx.set(idx)
    }
    onElemState = @(s) stateFlags(s)
    clickableInfo = loc("mainmenu/btnSelect")
    sound = { click = "choose" }
    rendObj = ROBJ_IMAGE
    image = bgUnit
    children = [
      emptySlotText
      mkUnitSelectedGlow(null, Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER)))
      mkUnitPlateBorder(isSelected)
    ]
    animations = [{ prop = AnimProp.opacity, to = 0.0, duration = aTimeSlotAddAppear,
      easing = OutQuad, playFadeOut = true }]
  }
}

let function slotToPurchase(priceGold) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = unitPlateSize
    rendObj = ROBJ_BOX
    fillColor = 0x80000000
    borderColor = 0xFFFFFFFF
    borderWidth = hdpx(3)
    behavior = Behaviors.Button
    onClick = buyUnitSlot
    onElemState = @(s) stateFlags(s)
    children = [
      mkUnitSelectedGlow(null, Computed(@() stateFlags.get() & S_HOVER))
      {
        size = array(2, buyIconSize)
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        keepAspect = true
        image = Picture($"ui/gameuiskin#icon_slot_buy.svg:{buyIconSize}:{buyIconSize}:P")
      }
      {
        pos = [hdpx(10), hdpx(-10)]
        vplace = ALIGN_BOTTOM
        children = mkCurrencyComp(
          priceGold,
          GOLD,
          CS_COMMON.__merge({ fontStyle = fontTinyAccented }))
      }
    ]
  }
}

let mkMark = {
  pos = [0, -unseenSize[0] / 2]
  vplace = ALIGN_TOP
  hplace = ALIGN_CENTER
}

function statusAttrMark(idx) {
  let unseenAttr = unseenSlotAttrByIdx(idx)
  return @() {
    watch = unseenAttr
    children = unseenAttr.get().statusByCat.len() ? priorityUnseenMark : null
  }.__update(mkMark)
}

function statusArsenalMark(unit) {
  let unseenMods = unseenSlotModsByCategory(unit)
  return @() {
    watch = unseenMods
    children = unseenMods.get().len() ? priorityUnseenMark : null
  }.__update(mkMark)
}

let slotIndicatorSize = hdpx(16)

let mkUnseenIndicator = @(ovr = {}) {
  size = [hdpx(45), unitPlateHeader]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(2)
  fillColor = 0xFFFFB70B
  color = 0xFFFFB70B
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    size = [slotIndicatorSize, slotIndicatorSize]
    rendObj = ROBJ_IMAGE
    color = 0xFFFFFF
    image = Picture($"ui/gameuiskin#button_notify_marker.svg:{slotIndicatorSize}:{slotIndicatorSize}:P")
    keepAspect = true
  }
  commands = [[VECTOR_POLY, 0, 100, 50, 0, 100, 0, 50, 100, 0, 100]]
}.__update(ovr)

let mkSlotHeaderTitle = @(text, isSelected) {
  rendObj = ROBJ_TEXT
  color = isSelected ? 0xFF383B3E : 0xFFFFFFFF
  text
}.__update(fontVeryTinyAccented)

function mkSlotHeaderIndicator(unit, idx) {
  let unseenMods = unseenSlotModsByCategory(unit)
  let unseenAttr = unseenSlotAttrByIdx(idx)
  return @() {
    watch = [unseenMods, unseenAttr]
    children = unseenMods.get().len() == 0 && unseenAttr.get().statusByCat.len() == 0 ? null
      : mkUnseenIndicator({ pos = [-hdpx(25), 0] })
  }
}

function mkSlotHeader(slot, idx, unit, isSelected) {
  let { level = 0 } = slot

  return @(){
    watch = isSelected
    size = [unitPlateSize[0], unitPlateHeader]
    flow = FLOW_HORIZONTAL
    rendObj = ROBJ_BOX
    fillColor = isSelected.get() ? 0xFFFFFFFF : 0xFF383B3E
    children = [
      {
        padding = [0, hdpx(10)]
        hplace = ALIGN_LEFT
        children = mkSlotHeaderTitle(loc("gamercard/slot/title", { idx = idx + 1 }), isSelected.get())
      }
      {
        size = flex()
      }
      {
        hplace = ALIGN_RIGHT
        pos = [hdpx(5), hdpx(1)]
        children = [
          mkSlotHeaderIndicator(unit, idx)
          mkSlotLevel(level,
            hdpx(26),
            { size = [hdpx(110), unitPlateHeader] },
            { fillColor = 0xFF383B3E, color = isSelected.get() ? 0xFFFFFFFF : 0xFFA0A0A0})
          ]
      }
    ]
  }
}

let function mkUnitSlot(unit, idx, onClick) {
  if (unit == null)
    return emptySelectSlot(idx)

  let stateFlags = Watched(0)
  let isSelected = Computed(@() selectedSlotIdx.get() == idx)
  let trigger = getSlotAnimTrigger(idx, unit.name)
  let needPlayOnAttach = slotsNeedAddAnim.get()?[idx] == unit.name
  return @() {
    watch = [isSelected, stateFlags]
    key = $"slot_{idx}_{unit.name}"
    size = unitPlateSize
    behavior = Behaviors.Button
    onClick
    onElemState = @(s) stateFlags(s)
    clickableInfo = isSelected.get() ? { skipDescription = true } : loc("mainmenu/btnSelect")
    sound = { click  = "choose" }
    children = [
      mkUnitBg(unit)
      mkUnitSelectedGlow(unit, Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER)))
      mkUnitImage(unit)
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
      mkUnitLock(unit, false)
      mkUnitPlateBorder(isSelected)
    ]
    transform = { pivot = [0.5, 0.5] }
    animations = [
      { prop = AnimProp.translate, to = unitPlateSize.map(@(v) v / 4), duration = aTimeSlotRemove,
        easing = InOutQuad, playFadeOut = true, trigger = removeUnitTrigger, onStart = playSlotRemoveDelayed }
      { prop = AnimProp.scale, to = [0.5, 0.5], duration = aTimeSlotRemove,
        easing = InOutQuad, playFadeOut = true, trigger = removeUnitTrigger }
      { prop = AnimProp.opacity, to = 0.0, duration = aTimeSlotRemove,
        easing = InOutQuad, playFadeOut = true, trigger = removeUnitTrigger }

      { prop = AnimProp.scale, from = [0.8, 0.8], duration = aTimeSlotAddAppear,
        easing = InQuad, trigger, play = needPlayOnAttach, sound = { start = "meta_unit_place" } }
      { prop = AnimProp.scale, to = [1.1, 1.1], duration = aTimeSlotAddBlink, delay = aTimeSlotAddAppear,
        easing = Blink, trigger, play = needPlayOnAttach, onFinish = @() onFinishSlotAnim(idx) }
      { prop = AnimProp.opacity, from = 0.0, duration = aTimeSlotAddAppear,
        easing = OutQuad, trigger, play = needPlayOnAttach }
    ]
  }
}

let function actionBtns(unit, idx) {
  let showBtns = Computed(@() selectedSlotIdx.get() == idx)
  return @() {
    watch = showBtns
    size = actionBtnsBlockSize
    pos = [lineWidth / 2, 0]
    margin = [0, 0, marginVert, 0]
    valign = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    gap = lineWidth
    children = !showBtns.get() ? null : [
      translucentSlotButton("ui/gameuiskin#icon_slot_change.svg",
        openUnitsTreeWnd,
        null,
        { commands = getBorderCommand(COMMADN_STATE.LEFT) })
      !unit.get()
        ? translucentSlotButton("ui/gameuiskin#arsenal.svg", @() null, null,
            { fillColor = 0x9F000000, watch = null })
        : translucentSlotButton("ui/gameuiskin#arsenal.svg", openUnitModsSlotsWnd, statusArsenalMark(unit))
      translucentSlotButton("ui/gameuiskin#slot_crew.svg",
        @() openSlotAttrWnd(),
        statusAttrMark(idx),
        { commands = getBorderCommand(COMMADN_STATE.RIGHT) })
    ]
  }
}

function onUnitSlotClick(unit, idx) {
  if (unit.get() == null || selectedSlotIdx.get() == idx)
    return

  let unitName = unit.get().name

  if (unitName != curUnit.get()?.name)
    setCurrentUnit(unitName)

  curSelectedUnit.set(unitName)
  selectedSlotIdx.set(idx)
}

let function mkSlotWithButtons(slot, idx) {
  let unit = Computed(@() myUnits.get()?[slot?.name] ?? allUnitsCfg.get()?[slot?.name])
  return @() {
    watch = [unit, slots]
    flow = FLOW_VERTICAL
    children = [
      actionBtns(unit, idx)
      mkSlotHeader(slot, idx, unit, Computed(@() selectedSlotIdx.get() == idx))
      mkUnitSlot(unit.get(), idx, @() onUnitSlotClick(unit, idx))
    ]
  }
}

let mainMenuPannable = horizontalPannableAreaCtor(saSize[0] - defButtonMinWidth, [0, 0])
let slotBarMainMenu = mainMenuPannable(@() {
  watch = slots
  key = "slotBarMainMenu"
  onDetach = skipRemoveAnim
  flow = FLOW_HORIZONTAL
  gap = slotsGap
  children = slots.get().map(mkSlotWithButtons)
})

function mkSlotCommon(slot, idx) {
  let { name = "" } = slot
  let unit = Computed(@() myUnits.get()?[name] ?? allUnitsCfg.get()?[name])
  return @() {
    watch = unit
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    children = [
      mkSlotHeader(slot, idx, unit, Computed(@() selectedSlotIdx.get() == idx))
      mkUnitSlot(unit.get(), idx, @() name != "" ? curSelectedUnit.set(name) : null)
    ]
  }
}

let unitsTreePannable = horizontalPannableAreaCtor(slotBarUnitsTreeWidth, [0, 0])
let slotBarUnitsTree = {
  key = {}
  size = [slotBarUnitsTreeWidth, sh(100)]
  valign = ALIGN_BOTTOM
  onDetach = skipRemoveAnim
  children = [
    {
      size = [slotBarUnitsTreeWidth - saBorders[1], hdpx(2)]
      pos = [0, - slotBarTreeHeight - saBorders[1]]
      hplace = ALIGN_RIGHT
      rendObj = ROBJ_IMAGE
      image = gradTranspDoubleSideX
      color = 0xFFD4D4D4
    }
    {
      size = [flex(), slotBarTreeHeight + saBorders[1]]
      padding = [slotBarUnitsTreePadding, 0, saBorders[1], saBorders[0]]
      rendObj = ROBJ_SOLID
      color = 0x40000000
      flow = FLOW_HORIZONTAL
      children = unitsTreePannable(@() {
        watch = [slots, newSlotPriceGold]
        flow = FLOW_HORIZONTAL
        gap = slotsGap
        children = slots.get().map(mkSlotCommon)
          .append(newSlotPriceGold.get() == null ? null : slotToPurchase(newSlotPriceGold.get()))
      })
    }
  ]
  animations = wndSwitchAnim
}

let frame = {
  size = flex()
  rendObj = ROBJ_BOX
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  borderColor = 0xFFFFFFFF
  borderWidth = hdpx(3)
}

function mkSlotSelect(slot, idx) {
  let unit = Computed(@() myUnits.get()?[slot?.name] ?? allUnitsCfg.get()?[slot?.name])
  return @() {
    watch = unit
    valign = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    children = [
      mkSlotHeader(slot, idx, unit, Computed(@() selectedSlotIdx.get() == idx))
      mkUnitSlot(unit.get(), idx, @() setUnitToSlot(idx))
      frame
    ]
  }
}

let slotBarSelectWnd = @() {
  watch = [slots, newSlotPriceGold]
  key = "slotBarSelectWnd"
  size = [sw(100), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  onDetach = skipRemoveAnim
  flow = FLOW_HORIZONTAL
  padding = hdpx(10)
  gap
  children = slots.get().map(mkSlotSelect)
    .append(newSlotPriceGold.get() == null ? null : slotToPurchase(newSlotPriceGold.get()))
}

return {
  slotBarMainMenu
  slotBarSize
  slotBarUnitsTree
  slotBarTreeHeight
  slotBarSelectWnd
}
