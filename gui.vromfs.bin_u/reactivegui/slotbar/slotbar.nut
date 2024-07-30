from "%globalsDarg/darg_library.nut" import *
let { translucentIconButton, translucentButtonsHeight } = require("%rGui/components/translucentButton.nut")
let { myUnits, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { set_current_unit } = require("%appGlobals/pServer/pServerApi.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitLock, bgUnit, mkUnitSelectedGlow
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { btnOpenUnitAttrCustom } = require("%rGui/unitAttr/btnOpenUnitAttr.nut")
let { openUnitsTreeWnd } = require("%rGui/unitsTree/unitsTreeState.nut")
let { slots, setUnitToSlot, buyUnitSlot, newSlotPriceGold, slotsNeedAddAnim, getSlotAnimTrigger,
  onFinishSlotAnim
} = require("slotBarState.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { CS_COMMON } = require("%rGui/components/currencyStyles.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { slotBarTreeGap, slotBarTreeHeight, unitPlateSize } = require("slotBarConsts.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { isHangarUnitHasWeaponSlots, openUnitModsSlotsWnd } = require("%rGui/unitMods/unitModsSlotsState.nut")
let { hasSlotAttrPreset } = require("%rGui/unitAttr/unitAttrState.nut")


let gap = hdpx(10)
let gapVert = hdpx(5)
let buyIconSize = hdpxi(40)
let actionIconSize = (translucentButtonsHeight * 0.5).tointeger()
let actionBtnSize = [translucentButtonsHeight * 1.1, translucentButtonsHeight * 0.7]
let actionBtnsBlockSize = [translucentButtonsHeight * 1.1, actionBtnSize[1] + actionIconSize * 0.5 + gapVert]
let slotBarSize = [saSize[0] - defButtonMinWidth, unitPlateSize[1] + actionBtnsBlockSize[1] + gapVert]

let aTimeSlotRemove = 0.5
let aTimeSlotAddAppear = 0.2
let aTimeSlotAddBlink = 0.3

let removeUnitTrigger = {}

let emptySlotText = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = loc("slotbar/empty")
}.__update(fontTinyAccented)

let function emptySelectSlot(idx) {
  let stateFlags = Watched(0)
  return {
    key = "empty"
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

let function mkUnitSlot(unit, idx, onClick) {
  if (unit == null)
    return emptySelectSlot(idx)

  let stateFlags = Watched(0)
  let isSelected = Computed(@() hangarUnitName.get() == unit.name)
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
    ]
    transform = { pivot = [0.5, 0.5] }
    animations = [
      { prop = AnimProp.translate, to = unitPlateSize.map(@(v) v / 4), duration = aTimeSlotRemove,
        easing = InOutQuad, playFadeOut = true, trigger = removeUnitTrigger }
      { prop = AnimProp.scale, to = [0.5, 0.5], duration = aTimeSlotRemove,
        easing = InOutQuad, playFadeOut = true, trigger = removeUnitTrigger }
      { prop = AnimProp.opacity, to = 0.0, duration = aTimeSlotRemove,
        easing = InOutQuad, playFadeOut = true, trigger = removeUnitTrigger }
      { prop = AnimProp.scale, from = [0.8, 0.8], duration = aTimeSlotAddAppear,
        easing = InQuad, trigger, play = needPlayOnAttach }
      { prop = AnimProp.scale, to = [1.1, 1.1], duration = aTimeSlotAddBlink, delay = aTimeSlotAddAppear,
        easing = Blink, trigger, play = needPlayOnAttach, onFinish = @() onFinishSlotAnim(idx) }
      { prop = AnimProp.opacity, from = 0.0, duration = aTimeSlotAddAppear,
        easing = OutQuad, trigger, play = needPlayOnAttach }
    ]
  }
}

let function actionBtns(unit) {
  let showBtns = Computed(@() hangarUnitName.get() == unit?.name)
  return @() {
    watch = [showBtns, isHangarUnitHasWeaponSlots]
    size = actionBtnsBlockSize
    valign = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    gap = hdpx(5)
    children = !unit || !showBtns.get() ? null : [
      translucentIconButton(
        "ui/gameuiskin#icon_slot_change.svg",
        openUnitsTreeWnd,
        actionIconSize,
        actionBtnSize)
      hasSlotAttrPreset.get() ? null
        : btnOpenUnitAttrCustom(actionIconSize, actionBtnSize)
      !isHangarUnitHasWeaponSlots.get() ? null
        : translucentIconButton(
          "ui/gameuiskin#arsenal.svg",
          openUnitModsSlotsWnd,
          actionIconSize,
          actionBtnSize)
    ]
  }
}

let function mkSlotWithButtons(slot, idx) {
  let unit = Computed(@() myUnits.get()?[slot?.name] ?? allUnitsCfg.get()?[slot?.name])
  return @() {
    watch = unit
    flow = FLOW_VERTICAL
    gap = gapVert
    children = [
      actionBtns(unit.get())
      mkUnitSlot(unit.get(), idx,
        function() {
          if (unit.get() == null)
            return
          curSelectedUnit.set(unit.get().name)
          set_current_unit(unit.get().name)
        })
    ]
  }
}

let mainMenuPannable = horizontalPannableAreaCtor(saSize[0] - defButtonMinWidth, array(2, saBorders[0]))
let slotBarMainMenu = mainMenuPannable(@() {
  watch = slots
  key = "slotBarMainMenu"
  onDetach = @() anim_skip(removeUnitTrigger)
  flow = FLOW_HORIZONTAL
  gap
  children = slots.get().map(mkSlotWithButtons)
})

function mkSlotCommon(slot, idx) {
  let { name = "" } = slot
  let unit = Computed(@() myUnits.get()?[name] ?? allUnitsCfg.get()?[name])
  return @() {
    watch = unit
    valign = ALIGN_BOTTOM
    children = mkUnitSlot(unit.get(), idx, @() name != "" ? curSelectedUnit.set(name) : null)
  }
}

let unitsTreePannable = horizontalPannableAreaCtor(saSize[0] - statsWidth, array(2, saBorders[0]))
let slotBarUnitsTree = {
  key = {}
  size = [sw(100), sh(100)]
  valign = ALIGN_BOTTOM
  onDetach = @() anim_skip(removeUnitTrigger)
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
    children = [
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
  onDetach = @() anim_skip(removeUnitTrigger)
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
