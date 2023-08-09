from "%globalsDarg/darg_library.nut" import *
let { set_camera_shift_centered, set_camera_shift_upper } = require("hangar")
let { get_time_msec } = require("dagor.time")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { isGamepad } = require("%rGui/activeControls.nut")
let { wndSwitchAnim, WND_REVEAL } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkGamercard } = require("%rGui/mainMenu/gamercard.nut")
let { playerLevelInfo, allUnitsCfg, myUnits, curUnit } = require("%appGlobals/pServer/profile.nut")
let { getUnitPresentation, getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { hangarUnitName, loadedHangarUnitName, setHangarUnit } = require("hangarUnit.nut")
let { sortUnits, getUnitAnyPrice } = require("%appGlobals/unitUtils.nut")
let { buyUnitsData, canBuyUnits, canBuyUnitsStatus, rankToReqPlayerLvl, getUnitLockedShortText,
  setCurrentUnit, US_TOO_LOW_LEVEL, US_NOT_FOR_SALE
} = require("%appGlobals/unitsState.nut")
let { unitInProgress, curUnitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { translucentButtonsVGap } = require("%rGui/components/translucentButton.nut")
let { textButtonPrimary, textButtonPurchase, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { infoBlueButton } = require("%rGui/components/infoButton.nut")
let { mkDiscountPriceComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let purchaseUnit = require("%rGui/unit/purchaseUnit.nut")
let { unitPlateWidth, unitPlateHeight, unutEquppedTopLineFullHeight, unitSelUnderlineFullHeight,
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitCanPurchaseShade, mkUnitTexts, mkUnitLevel, mkUnitPrice,
  mkUnitLockedFg, mkUnitEquippedFrame, mkUnitEquippedTopLine, mkUnitSelectedUnderline,
  mkPlatoonPlateFrame, platoonSelPlatesGap, mkPlatoonEquippedIcon, mkPlatoonSelectedGlow,
  mkUnitEmptyLockedFg, bgPlatesTranslate, mkPlateText, plateTextsPad
} = require("%rGui/unit/components/unitPlateComp.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { unitInfoPanel, unitInfoPanelDefPos } = require("%rGui/unit/components/unitInfoPanel.nut")
let btnOpenUnitAttr = require("%rGui/unitAttr/btnOpenUnitAttr.nut")
let { curFilters, optName, optCountry, optUnitClass, optMRank, optStatus
} = require("%rGui/unit/unitsFilterState.nut")
let mkUnitsFilter = require("%rGui/unit/mkUnitsFilter.nut")
let modalPopupWnd = require("%rGui/components/modalPopupWnd.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let mkUnitPkgDownloadInfo = require("mkUnitPkgDownloadInfo.nut")
let { isPurchEffectVisible } = require("unitPurchaseEffectScene.nut")
let { gradTranspDoubleSideX, gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let openBuyExpWithUnitWnd = require("%rGui/levelUp/buyExpWithUnitWnd.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { PURCH_SRC_UNITS, PURCH_TYPE_UNIT, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { abs } = require("%sqstd/math.nut")
let { justUnlockedUnits, justBoughtUnits, deleteJustBoughtUnit, UNLOCK_DELAY } = require("%rGui/unit/justUnlockedUnits.nut")
let { scaleAnimation, revealAnimation, raisePlatesAnimation, RAISE_PLATE_TOTAL
} = require("%rGui/unit/components/unitUnlockAnimation.nut")
let { lqTexturesWarningHangar } = require("%rGui/hudHints/lqTexturesWarning.nut")

const MIN_HOLD_MSEC = 700
let premiumDays = 30
let isOpened = mkWatched(persist, "isOpened", false)
let isFiltersVisible = Watched(false)
let filters = [optName, optCountry, optUnitClass, optMRank, optStatus]
let activeFilters = Watched(0)

let gapFromUnitsBlockToBtns = hdpx(4)

let isAttached = Watched(false)
isAttached.subscribe(function(v) {
  if (v)
    set_camera_shift_upper()
  else if (!isPurchEffectVisible.value)
    set_camera_shift_centered()
})
loadedHangarUnitName.subscribe(@(_) isAttached.value ? set_camera_shift_upper() : null)

let holdInfo = {} //unitName = { press = int, release = int }

let availableUnitsList = Computed(@() allUnitsCfg.value
  .filter(@(u) !u?.isHidden || u.name in myUnits.value)
  .map(@(u, id) myUnits.value?[id] ?? u)
  .values()
  .sort(sortUnits))

let curSelectedUnit = Watched(null)
let curSelectedUnitLevel = Computed(@() rankToReqPlayerLvl.value?[allUnitsCfg.value
  .findvalue(@(u) u.name == curSelectedUnit.value)?.rank] ?? 0)
let curUnitName = Computed(@() curUnit.value?.name)

let curSelectedUnitPrice = Computed(@()
  (allUnitsCfg.value?[curSelectedUnit.value]?.costGold ?? 0) + (allUnitsCfg.value?[curSelectedUnit.value]?.costWp ?? 0))

let canEquipSelectedUnit = Computed(@() (curSelectedUnit.value in myUnits.value) && (curSelectedUnit.value != curUnit.value?.name))
let isShowedUnitOwned = Computed(@() hangarUnitName.value in myUnits.value)

curUnitName.subscribe(function(v) {
  if (v != null && !isAttached.value && curSelectedUnit.value != null)
    curSelectedUnit(v)
})

let countActiveFilters = @() activeFilters(filters.reduce(function(res, f) {
  let { value } = f.value
  if (value != null && value != ""
      && (type(value) != "table" || value.len() < f.allValues.value.len()))
    res++
  return res
}, 0))
countActiveFilters()
foreach (f in filters) {
  f.value.subscribe(@(_) countActiveFilters())
  f?.allValues.subscribe(@(_) countActiveFilters())
}

let isFitAllFilters = @(unit) filters.findvalue(@(f) f.value.value != null && !f.isFit(unit, f.value.value)) == null
curFilters.subscribe(function(_) {
  let unit = allUnitsCfg.value?[curSelectedUnit.value]
  if (unit != null && isFitAllFilters(unit))
    return
  let first = availableUnitsList.value.findvalue(isFitAllFilters)
  curSelectedUnit(first?.name)
})

let function close() {
  curSelectedUnit(null)
  isOpened(false)
}

let function onSetCurrentUnit() {
  if (curSelectedUnit.value == null || curUnitInProgress.value != null)
    return
  setCurrentUnit(curSelectedUnit.value)
  isOpened(false)
}

let function onBuyUnit() {
  if (curSelectedUnit.value == null || unitInProgress.value != null)
    return
  let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_UNITS, PURCH_TYPE_UNIT, curSelectedUnit.value)
  purchaseUnit(curSelectedUnit.value, bqPurchaseInfo)
}

curSelectedUnit.subscribe(function(unitId) {
  if (unitId != null)
    setHangarUnit(unitId)
})

let unitsPlateCombinedHeight = unutEquppedTopLineFullHeight + unitPlateHeight + unitSelUnderlineFullHeight

const FILTER_UID = "units_filter"
let closeFilters = @() modalPopupWnd.remove(FILTER_UID)
let openFilters = @(event)
  modalPopupWnd.add(event.targetRect, {
    uid = FILTER_UID
    children = mkUnitsFilter(filters, availableUnitsList, hdpx(1000))
    padding = hdpx(20)
    popupValign = ALIGN_BOTTOM
    popupHalign = ALIGN_LEFT
    popupOffset = unitsPlateCombinedHeight + hdpx(20)
    hotkeys = [[btnBEscUp, closeFilters]]
    onAttach = @() isFiltersVisible(true)
    onDetach = @() isFiltersVisible(false)
  })

let filterStateFlags = Watched(0)
let getFiltersText = @(count) count <= 0 ? loc("showFilters") : loc("activeFilters", { count })
let unitFilterButton = @() {
  watch = [isFiltersVisible, isGamepad]
  vplace = ALIGN_TOP
  pos = [saBorders[0], saBorders[1] + saSize[1]]
}.__update(isGamepad.value
  ? {
      key = filterStateFlags
      children = { hotkeys = [["^J:LT", getFiltersText(activeFilters.value), openFilters]] }
    }
  : {
      padding = hdpx(10)
      rendObj = ROBJ_SOLID
      color = isFiltersVisible.value ? 0xA0000000 : 0

      behavior = Behaviors.Button
      onElemState = @(s) filterStateFlags(s)
      onClick = openFilters
      children = @() {
        watch = [filterStateFlags, activeFilters]
        rendObj = ROBJ_TEXT
        color = activeFilters.value > 0 || (filterStateFlags.value & S_ACTIVE) ? 0xFFFFFFFF : 0xFFA0A0A0
        text = getFiltersText(activeFilters.value)
      }.__update(fontTiny)
      transitions = [{ prop = AnimProp.color, duration = 0.3, easing = InOutQuad }]
    })

let unitTweakingButtons = @() isShowedUnitOwned.value
  ? {
      watch = isShowedUnitOwned
      size = SIZE_TO_CONTENT
      vplace = ALIGN_BOTTOM
      children = btnOpenUnitAttr
    }
  : { watch = isShowedUnitOwned }

let bgTextMessage = {
  size = [SIZE_TO_CONTENT, hdpx(50)]
  color = 0x8F000000
  valign = ALIGN_CENTER
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  screenOffs = hdpx(50)
  texOffs = gradCircCornerOffset
}

let function findGoodsPrem(shopGoodsList){
  local res = null
  local delta = 0
  foreach (g in shopGoodsList) {
    if ((g?.premiumDays ?? 0) <= 0
      || (g?.gold ?? 0) > 0 || (g?.wp ?? 0) > 0 || (g?.items.len() ?? 0) > 0
      || (g?.units.len() ?? 0) > 0 || (g?.unitUpgrades.len() ?? 0) > 0)
      continue
    let d = abs(g.premiumDays - premiumDays)
    if (d == 0)
      return g
    if (res != null && d >= delta)
      continue
    delta = d
    res = g
  }
  return res
}

let function unitActionButtons() {
  let children = []
  if (canEquipSelectedUnit.value)
    children.append(
      textButtonPrimary(utf8ToUpper(loc("msgbox/btn_choose")), onSetCurrentUnit, { hotkeys = ["^J:X"] }))
  else if (curSelectedUnit.value in canBuyUnits.value) {
    let unit = canBuyUnits.value[curSelectedUnit.value]
    let isForLevelUp = playerLevelInfo.value.isReadyForLevelUp && (unit?.name in buyUnitsData.value.canBuyOnLvlUp)
    let price = getUnitAnyPrice(unit, isForLevelUp)
    if (price != null) {
      let priceComp = mkDiscountPriceComp(price.fullPrice, price.price, price.currencyId, CS_INCREASED_ICON)
      children.append(
        textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")), priceComp,
          onBuyUnit, { hotkeys = ["^J:X"] }))
    }
  }
  else if (canBuyUnitsStatus.value?[curSelectedUnit.value] == US_TOO_LOW_LEVEL){
    let deltaLevels = curSelectedUnitLevel.value - playerLevelInfo.value.level
    if(deltaLevels >= 2)
      children.append(bgTextMessage.__merge({
        children = @(){
          size = SIZE_TO_CONTENT
          rendObj = ROBJ_TEXT
          color = 0xFFFFFF
          text = curSelectedUnitPrice.value == 0
            ? loc("unitWnd/coming_soon")
            : loc("unitWnd/explore_request")
        }.__update(fontTiny)
      }))
    else if(deltaLevels == 1 && canBuyUnitsStatus.value?[curSelectedUnit.value] != US_NOT_FOR_SALE) {
      let premId = findGoodsPrem(shopGoods.value)?.id
      children.append(
        textButtonPurchase(
          utf8ToUpper(loc("units/btn_speed_explore")),
          havePremium.value || premId == null ? @() openBuyExpWithUnitWnd(curSelectedUnit.value)
            : @() openGoodsPreview(premId)
        )
      )
    }
  }
  children.append(
    infoBlueButton(
      @() unitDetailsWnd({ name = hangarUnitName.value })
      {
        size = [defButtonHeight, defButtonHeight]
        hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
      }
      fontBig)
  )

  return {
    watch = [
      curSelectedUnit,curSelectedUnitPrice,
      canBuyUnits, canEquipSelectedUnit, havePremium,
      canBuyUnitsStatus, playerLevelInfo, curCampaign,
      shopGoods, buyUnitsData]
    size = SIZE_TO_CONTENT
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(24)
    children
  }
}

let unitActions = mkSpinnerHideBlock(Computed(@() unitInProgress.value != null || curUnitInProgress.value != null),
  unitActionButtons,
  {
    size = [flex(), defButtonHeight]
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
  })

let mkOnElemState = @(holdId, stateFlags = Watched(0)) function(sf) {
  local { release = 0, press = 0 } = holdInfo?[holdId]
  let isPressed = (sf & S_ACTIVE) != 0
  let wasPressed = release < press
  stateFlags(sf)
  if (isPressed == wasPressed)
    return
  if (isPressed)
    press = get_time_msec()
  else
    release = get_time_msec()
  holdInfo[holdId] <- { release, press }
}

let function isHold(id) {
  local { release = 0, press = 0 } = holdInfo?[id]
  let time = release < press ? get_time_msec() - press
    : get_time_msec() - release < 50 ? release - press
    : 0
  return time >= MIN_HOLD_MSEC
}

let hoverBg = {
  vplace = ALIGN_CENTER
  size = [ flex(), hdpx(19) ]
  rendObj = ROBJ_BOX
}

let function mkPlatoonPlates(unit) {
  let platoonUnits = unit.platoonUnits
  let platoonSize = platoonUnits?.len() ?? 0
  let canPurchase = Computed(@() unit.name in canBuyUnits.value)
  let isLocked = Computed(@() (unit.name not in myUnits.value) && (unit.name not in canBuyUnits.value))
  let isSelected = Computed(@() curSelectedUnit.value == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.value)
  let justUnlockedDelay = Computed(@() justUnlockedUnits.value?[unit.name])
  let justBoughtDelay = Computed(@() !justBoughtUnits.value?[unit.name] ? null
    : justUnlockedDelay.value ? justBoughtUnits.value?[unit.name]
    : WND_REVEAL)

  return @() {
    watch = [isSelected, justUnlockedDelay, justBoughtDelay]
    size = flex()
    children = platoonUnits?.map(@(_, idx) {
      size = flex()
      transform = { translate = bgPlatesTranslate(platoonSize, idx, isSelected.value || justBoughtDelay.value) }
      transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
      animations = raisePlatesAnimation(justBoughtDelay.value,
        bgPlatesTranslate(platoonSize, idx, isSelected.value || justBoughtDelay.value), idx, platoonSize,
          @() deleteJustBoughtUnit(unit.name))
      children = [
        mkUnitBg(unit, {}, justUnlockedDelay.value)
        mkUnitCanPurchaseShade(canPurchase)
        mkUnitEmptyLockedFg(isLocked, justUnlockedDelay.value)
        mkPlatoonPlateFrame(isEquipped, isLocked, justUnlockedDelay.value)
        !justBoughtDelay.value ? null : mkPlateText(loc(getUnitPresentation(platoonUnits?[platoonSize - idx - 1]).locId),
          { vplace = ALIGN_TOP, hplace = ALIGN_RIGHT, padding = plateTextsPad, animations = revealAnimation() })
      ]
    })
  }
}

let function mkPlatoonPlate(unit) {
  let stateFlags = Watched(0)
  if (unit == null)
    return null

  let function onClick() {
    curSelectedUnit(unit.name)
    if (isHold(unit.name))
      unitDetailsWnd({ name = hangarUnitName.value })
  }
  let isSelected = Computed(@() curSelectedUnit.value == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.value)
  let canPurchase = Computed(@() unit.name in canBuyUnits.value)
  let isLocked = Computed(@() (unit.name not in myUnits.value) && (unit.name not in canBuyUnits.value))
  let canBuyForLvlUp = playerLevelInfo.value.isReadyForLevelUp && (unit?.name in buyUnitsData.value.canBuyOnLvlUp)
  let price = canPurchase.value ? getUnitAnyPrice(unit, canBuyForLvlUp) : null
  let justUnlockedDelay = Computed(@() justUnlockedUnits.value?[unit.name])
  let lockedText = Computed(@() getUnitLockedShortText(unit,
    justUnlockedDelay.value ? US_TOO_LOW_LEVEL : canBuyUnitsStatus.value?[unit.name],
    rankToReqPlayerLvl.value?[unit.rank]))

  return @() {
    watch = [isSelected, stateFlags, justUnlockedDelay]
    behavior = Behaviors.Button
    clickableInfo = isSelected.value ? { skipDescription = true } : loc("mainmenu/btnSelect")
    sound = { click  = "choose" }
    onClick
    onElemState = mkOnElemState(unit.name, stateFlags)
    xmbNode = XmbNode()
    flow = FLOW_VERTICAL
    children = [
      stateFlags.value & S_HOVER ? hoverBg : null
      {
        size = [ unitPlateWidth, unitPlateHeight ]
        children = [
          mkPlatoonPlates(unit)
          mkUnitBg(unit, {}, justUnlockedDelay.value)
          mkPlatoonSelectedGlow(unit, isSelected, justUnlockedDelay.value)
          mkUnitImage(unit)
          mkUnitCanPurchaseShade(canPurchase)
          mkUnitTexts(unit, loc(getUnitLocId(unit)), justUnlockedDelay.value)
          unit?.level == null ? null : mkUnitLevel(unit.level, justUnlockedDelay.value)
          price != null ? mkUnitPrice(price, justUnlockedDelay.value) : null
          mkUnitLockedFg(isLocked, lockedText, justUnlockedDelay.value, unit.name)
          mkPlatoonPlateFrame(isEquipped, isLocked, justUnlockedDelay.value)
          mkPlatoonEquippedIcon(unit, isEquipped, justUnlockedDelay.value)
        ]
      }
      mkUnitSelectedUnderline(isSelected, justUnlockedDelay.value)
    ]
  }
}

let function mkUnitPlate(unit) {
  let stateFlags = Watched(0)
  if (unit == null)
    return null

  let function onClick() {
    curSelectedUnit(unit.name)
    if (isHold(unit.name))
      unitDetailsWnd({ name = hangarUnitName.value })
  }
  let p = getUnitPresentation(unit)
  let isSelected = Computed(@() curSelectedUnit.value == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.value)
  let canPurchase = Computed(@() unit.name in canBuyUnits.value)
  let isLocked = Computed(@() (unit.name not in myUnits.value) && (unit.name not in canBuyUnits.value))
  let canBuyForLvlUp = playerLevelInfo.value.isReadyForLevelUp && (unit?.name in buyUnitsData.value.canBuyOnLvlUp)
  let price = canPurchase.value ? getUnitAnyPrice(unit, canBuyForLvlUp) : null
  let justUnlockedDelay = Computed(@() justUnlockedUnits.value?[unit.name])
  let lockedText = Computed(@() getUnitLockedShortText(unit,
    justUnlockedDelay.value ? US_TOO_LOW_LEVEL : canBuyUnitsStatus.value?[unit.name],
    rankToReqPlayerLvl.value?[unit.rank]))

  return @() {
    watch = [isSelected, stateFlags, justUnlockedDelay]
    size = [ unitPlateWidth, unitsPlateCombinedHeight ]
    behavior = Behaviors.Button
    clickableInfo = isSelected.value ? { skipDescription = true } : loc("mainmenu/btnSelect")
    sound = { click  = "choose" }
    onClick
    onElemState = mkOnElemState(unit.name, stateFlags)
    xmbNode = XmbNode()
    flow = FLOW_VERTICAL
    children = [
      stateFlags.value & S_HOVER ? hoverBg : null
      mkUnitEquippedTopLine(isEquipped, justUnlockedDelay.value)
      {
        size = [ unitPlateWidth, unitPlateHeight ]
        transform = {}
        animations = scaleAnimation(justUnlockedDelay.value, [1.05, 1.05])
        children = [
          mkUnitBg(unit, {}, justUnlockedDelay.value)
          mkUnitSelectedGlow(unit, isSelected, justUnlockedDelay.value)
          mkUnitImage(unit)
          mkUnitCanPurchaseShade(canPurchase)
          mkUnitTexts(unit, loc(p.locId), justUnlockedDelay.value)
          unit?.level == null ? null : mkUnitLevel(unit.level, justUnlockedDelay.value)
          price != null ? mkUnitPrice(price, justUnlockedDelay.value) : null
          mkUnitLockedFg(isLocked, lockedText, justUnlockedDelay.value, unit.name)
          mkUnitEquippedFrame(unit, isEquipped, justUnlockedDelay.value)
        ]
      }
      mkUnitSelectedUnderline(isSelected, justUnlockedDelay.value)
    ]
  }
}

let scrollHandler = ScrollHandler()
let mkHorizPannableArea = @(content) {
  size = flex()
  flow = FLOW_HORIZONTAL
  children = {
    size = flex()
    behavior = Behaviors.Pannable
    scrollHandler = scrollHandler
    children = content
    xmbNode = XmbContainer({
      canFocus = false
      scrollSpeed = 5.0
      isViewport = true
    })
  }
}

let unitsBarHorizPad = {
  size = [ saBorders[0], flex() ]
}

let noUnitsMsg = {
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = loc("noUnitsByCurrentFilters")
  color = 0xFFFFFFFF
}.__update(fontSmall)

local listWatches = [availableUnitsList]
foreach (f in filters)
  listWatches.append(f?.value, f?.allValues)
listWatches = listWatches.filter(@(w) w != null)

let function unitsBlock() {
  local filtered = availableUnitsList.value
  foreach (f in filters) {
    let { value } = f.value
    if (value != null)
      filtered = filtered.filter(@(u) f.isFit(u, value))
  }
  let platoonSize = (filtered?[0].platoonUnits ?? []).len()
  let gap = platoonSize > 0 ? (platoonSize + 0.8) * platoonSelPlatesGap : 0
  return {
    watch = listWatches
    size = [filtered.len() == 0 ? flex() : SIZE_TO_CONTENT, unitsPlateCombinedHeight]
    flow = FLOW_HORIZONTAL
    gap
    onAttach = function() {
      if (curSelectedUnit.value == null)
        curSelectedUnit(curUnitName.value)
      let selUnitIdx = filtered.findindex(@(u) u.name == curSelectedUnit.value) ?? 0
      let scrollPosX = (unitPlateWidth + gap) * selUnitIdx - (0.5 * (saSize[0] - unitPlateWidth))
      scrollHandler.scrollToX(scrollPosX)
    }
    children = filtered.len() == 0 ? noUnitsMsg
      : [ unitsBarHorizPad ]
          .extend(filtered.map(@(u) platoonSize > 0 ? mkPlatoonPlate(u) : mkUnitPlate(u)))
          .append(unitsBarHorizPad)
  }
}

let gamercardPlace = {
  children = [
    mkGamercard(close)
    unitInfoPanel({
      pos = unitInfoPanelDefPos
      behavior = [ Behaviors.Button, Behaviors.HangarCameraControl ]
      eventPassThrough = true
      onClick = @() unitDetailsWnd({ name = hangarUnitName.value })
      clickableInfo = loc("msgbox/btn_more")
      hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
    })
  ]
}

let function platoonsHeader() {
  let revealDelay = Computed(@() !justBoughtUnits.value ? null
    : !justUnlockedUnits.value ? RAISE_PLATE_TOTAL + 1.0
    : UNLOCK_DELAY + RAISE_PLATE_TOTAL + 1.0)

  return curCampaign.value != "tanks" ? { watch = [curCampaign] } : {
    watch = [curCampaign]
    size = [hdpx(800), hdpx(80)]
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = gradTranspDoubleSideX
    color = 0xA0000000
    margin = [0 , 0, hdpx(5), 0]
    animations = revealAnimation(revealDelay.value)
    children = [
      {
        text = loc("header/platoons")
        rendObj = ROBJ_TEXT
        color = 0xFFFFFFFF
        fontFx = FFT_GLOW
        fontFxFactor = max(64, hdpx(64))
        fontFxColor = 0xFF000000
      }.__update(fontMedium)
    ]
  }
}

let unitsWnd = {
  key = {}
  size = [ sw(100), sh(100) ]
  stopMouse = true
  stopHotkeys = true
  behavior = Behaviors.HangarCameraControl
  onAttach = @() isAttached(true)
  onDetach = @() isAttached(false)
  children = [
    lqTexturesWarningHangar
    {
      size = [ flex(), unitsPlateCombinedHeight ]
      pos = [ 0, sh(100) - unitsPlateCombinedHeight - saBorders[1] ]
      children = mkHorizPannableArea(unitsBlock)
    }
    {
      size = [ saSize[0],
        saSize[1] - unitsPlateCombinedHeight - translucentButtonsVGap - gapFromUnitsBlockToBtns ]
      pos = [ 0, saBorders[1] ]
      hplace = ALIGN_CENTER
      children = [
        gamercardPlace
        unitTweakingButtons
        unitActions
        {
          vplace = ALIGN_BOTTOM
          hplace = ALIGN_CENTER
          flow = FLOW_VERTICAL
          gap = hdpx(20)
          children = [
            mkUnitPkgDownloadInfo(Computed(@() allUnitsCfg.value?[curSelectedUnit.value]))
            platoonsHeader
          ]
        }

      ]
    }
    unitFilterButton
  ]
  animations = wndSwitchAnim
}

registerScene("unitsWnd", unitsWnd, close, isOpened)

return @() isOpened(true)
