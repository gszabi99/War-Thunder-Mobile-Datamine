from "%globalsDarg/darg_library.nut" import *
let { translucentIconButton, translucentButtonsHeight } = require("%rGui/components/translucentButton.nut")
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitLock, bgUnit, mkUnitSelectedGlow, unitPlateSmall
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { btnOpenUnitAttrCustom } = require("%rGui/unitAttr/btnOpenUnitAttr.nut")
let { openUnitsTreeWnd } = require("%rGui/unitsTree/unitsTreeState.nut")
let { slots, setUnitToSlot, buyUnitSlot, newSlotPriceGold } = require("slotBarState.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { CS_COMMON } = require("%rGui/components/currencyStyles.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")


let gap = hdpx(10)
let gapVert = hdpx(5)
let buyIconSize = hdpxi(40)
let unitPlateSize = unitPlateSmall
let actionIconSize = (translucentButtonsHeight * 0.5).tointeger()
let actionBtnSize = [translucentButtonsHeight * 1.1, translucentButtonsHeight * 0.7]
let actionBtnsBlockSize = [translucentButtonsHeight * 1.1, actionBtnSize[1] + actionIconSize * 0.5 + gapVert]
let slotBarSize = [saSize[0] - defButtonMinWidth, unitPlateSize[1] + actionBtnsBlockSize[1] + gapVert]
let slotBarSelectWndWidth = unitPlateSize[0] * 4 + gap * 3
let slotBarTreeGap = hdpx(20)
let slotBarTreeHeight = unitPlateSize[1] + slotBarTreeGap

let emptySlotText = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = loc("slotbar/empty")
}.__update(fontTinyAccented)

let function emptySelectSlot(idx) {
  let stateFlags = Watched(0)
  return {
    size = unitPlateSize
    behavior = Behaviors.Button
    onClick = @() setUnitToSlot(idx)
    onElemState = @(s) stateFlags(s)
    clickableInfo = loc("mainmenu/btnSelect")
    sound = { click = "choose" }
    rendObj = ROBJ_IMAGE
    image = bgUnit
    children = [
      emptySlotText
      mkUnitSelectedGlow(null, Computed(@() stateFlags.get() & S_HOVER))
    ]
  }
}

let emptySlot = {
  size = unitPlateSize
  rendObj = ROBJ_IMAGE
  image = bgUnit
  children = emptySlotText
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

let function mkUnitPlate(unit, idx = null) {
  if (unit == null)
    return idx == null ? emptySlot : emptySelectSlot(idx)

  let stateFlags = Watched(0)
  let isSelected = Computed(@() hangarUnitName.get() == unit.name)

  return @() {
    watch = [isSelected, stateFlags]
    size = unitPlateSize
    behavior = Behaviors.Button
    onClick = @() idx == null ? curSelectedUnit.set(unit.name) : setUnitToSlot(idx)
    onElemState = @(s) stateFlags(s)
    clickableInfo = isSelected.get() ? { skipDescription = true } : loc("mainmenu/btnSelect")
    sound = { click  = "choose" }
    children = [
      mkUnitBg(unit)
      mkUnitSelectedGlow(unit, Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER)))
      mkUnitImage(unit)
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
      mkUnitLock(unit, false)
    ]
  }
}

let function actionBtns(unit) {
  let showBtns = Computed(@() hangarUnitName.get() == unit?.name)
  return @() {
    watch = showBtns
    size = actionBtnsBlockSize
    valign = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    gap = hdpx(8)
    children = !unit || !showBtns.get() ? null : [
      translucentIconButton(
        "ui/gameuiskin#icon_slot_change.svg",
        openUnitsTreeWnd,
        actionIconSize,
        actionBtnSize)
      btnOpenUnitAttrCustom(actionIconSize, actionBtnSize)
    ]
  }
}

let function mkSlotWithButtons(slot) {
  let unit = Computed(@() allUnitsCfg.get()?[slot?.name])
  return @() {
    watch = unit
    flow = FLOW_VERTICAL
    gap = gapVert
    children = [
      actionBtns(unit.get())
      mkUnitPlate(unit.get())
    ]
  }
}

let function mkSlot(slot, idx) {
  let unit = Computed(@() allUnitsCfg.get()?[slot?.name])
  return @() {
    watch = unit
    valign = ALIGN_BOTTOM
    children = mkUnitPlate(unit.get(), idx)
  }
}

let mainMenuPannable = horizontalPannableAreaCtor(saSize[0] - defButtonMinWidth, array(2, saBorders[0]))
let slotBarMainMenu = mainMenuPannable(@() {
  watch = slots
  flow = FLOW_HORIZONTAL
  gap
  children = slots.get().map(mkSlotWithButtons)
})

let unitsTreePannable = horizontalPannableAreaCtor(saSize[0] - statsWidth, array(2, saBorders[0]))
let slotBarUnitsTree = {
  size = [sw(100), sh(100)]
  valign = ALIGN_BOTTOM
  children = [
    {
      size = [flex(), hdpx(1)]
      pos = [0, - slotBarTreeHeight - saBorders[1]]
      rendObj = ROBJ_SOLID
      color = 0xFFFFFFFF
    }
    @() {
      size = [flex(), slotBarTreeHeight + saBorders[1]]
      padding = [slotBarTreeGap, saBorders[0], saBorders[1], 0]
      rendObj = ROBJ_SOLID
      color = 0xA0000000
      flow = FLOW_HORIZONTAL
      children = unitsTreePannable(@() {
        watch = [slots, newSlotPriceGold]
        flow = FLOW_HORIZONTAL
        gap
        children = slots.get().map(@(slot) mkSlot(slot, null))
          .append(newSlotPriceGold.get() == null ? null : slotToPurchase(newSlotPriceGold.get()))
      })
    }
  ]
}

let slotBarSelectWnd = @() {
  watch = [slots, newSlotPriceGold]
  padding = [saBorders[1], saBorders[0]]
  flow = FLOW_HORIZONTAL
  gap
  children = wrap(
    slots.get().map(@(slot, idx) mkSlot(slot, idx))
      .append(newSlotPriceGold.get() == null ? null : slotToPurchase(newSlotPriceGold.get())),
    {
      width = slotBarSelectWndWidth
      vGap = gap
      hGap = gap
    })
}

return {
  slotBarMainMenu
  slotBarSize
  slotBarUnitsTree
  slotBarTreeHeight
  slotBarSelectWnd
}
