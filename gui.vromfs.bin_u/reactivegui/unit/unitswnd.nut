from "%globalsDarg/darg_library.nut" import *
let { set_camera_shift_centered, set_camera_shift_upper } = require("hangar")
let { get_time_msec } = require("dagor.time")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { isGamepad } = require("%rGui/activeControls.nut")
let { wndSwitchAnim, WND_REVEAL } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { levelBlock, gamercardWithoutLevelBlock, gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { playerLevelInfo, allUnitsCfg, myUnits, curUnit } = require("%appGlobals/pServer/profile.nut")
let { getUnitPresentation, getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { hangarUnitName, loadedHangarUnitName, setHangarUnit } = require("hangarUnit.nut")
let { sortUnits, getUnitAnyPrice } = require("%appGlobals/unitUtils.nut")
let { buyUnitsData, canBuyUnits, canBuyUnitsStatus, setCurrentUnit, US_TOO_LOW_LEVEL, US_NOT_FOR_SALE
} = require("%appGlobals/unitsState.nut")
let { unitInProgress, curUnitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { translucentButtonsVGap } = require("%rGui/components/translucentButton.nut")
let { textButtonPrimary, textButtonPricePurchase, mkCustomButton } = require("%rGui/components/textButton.nut")
let { textButtonPlayerLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let { infoBlueButton } = require("%rGui/components/infoButton.nut")
let { mkDiscountPriceComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let purchaseUnit = require("%rGui/unit/purchaseUnit.nut")
let { unitPlateWidth, unitPlateHeight, unutEquppedTopLineFullHeight, unitSelUnderlineFullHeight,
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitCanPurchaseShade, mkUnitTexts, mkUnitLock, mkUnitShortPrice,
  mkUnitLockedFg, mkUnitEquippedFrame, mkUnitEquippedTopLine, mkUnitSelectedUnderline,
  mkPlatoonPlateFrame, platoonSelPlatesGap, mkPlatoonEquippedIcon, mkPlatoonSelectedGlow,
  mkUnitEmptyLockedFg, bgPlatesTranslate, mkPlateText, plateTextsPad
} = require("%rGui/unit/components/unitPlateComp.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { unitInfoPanel, unitInfoPanelDefPos, mkUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
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
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isUnitsWndAttached, isUnitsWndOpened } = require("%rGui/mainMenu/mainMenuState.nut")
let { doubleSideGradient } = require("%rGui/components/gradientDefComps.nut")
let { gamercardGap } = require("%rGui/components/currencyStyles.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { mkPriorityUnseenMarkWatch } = require("%rGui/components/unseenMark.nut")
let { unseenUnits, markUnitSeen } = require("unseenUnits.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let { levelProgressBarHeight } = require("%rGui/components/levelBlockPkg.nut")
let { unitDiscounts } = require("unitsDiscountState.nut")
let { discountTagUnitBig } = require("%rGui/components/discountTag.nut")

const MIN_HOLD_MSEC = 700
let premiumDays = 30
let isFiltersVisible = Watched(false)
let filters = [optName, optCountry, optUnitClass, optMRank, optStatus]
let activeFilters = Watched(0)
let profileStateFlags = Watched(0)

let gapFromUnitsBlockToBtns = hdpx(4)
let levelProgressWidth = hdpx(600)

let premBGHoverColor = 0x01B28600
let defaultBgHoverColor = 0xFF50C0FF

isUnitsWndAttached.subscribe(function(v) {
  if (v)
    set_camera_shift_upper()
  else if (!isPurchEffectVisible.value)
    set_camera_shift_centered()
})
loadedHangarUnitName.subscribe(@(_) isUnitsWndAttached.value ? set_camera_shift_upper() : null)

let holdInfo = {} //unitName = { press = int, release = int }

let availableUnitsList = Computed(@() allUnitsCfg.value
  .filter(@(u) !u?.isHidden || u.name in myUnits.value)
  .map(@(u, id) myUnits.value?[id] ?? u)
  .values()
  .sort(sortUnits))

let scrollHandler = ScrollHandler()
let scrollPos = Computed(@() (scrollHandler.elem?.getScrollOffsX() ?? 0))

let sizePlatoon = Computed(@() (availableUnitsList.value?[0].platoonUnits ?? []).len())
let gap = Computed(@() sizePlatoon.value > 0 ? (sizePlatoon.value + 0.8) * platoonSelPlatesGap : 0)

let curSelectedUnit = Watched(null)
let curUnitName = Computed(@() curUnit.value?.name)

curCampaign.subscribe(@(_) curSelectedUnit(curUnitName.value))

let curSelectedUnitPrice = Computed(@()
  (allUnitsCfg.value?[curSelectedUnit.value]?.costGold ?? 0) + (allUnitsCfg.value?[curSelectedUnit.value]?.costWp ?? 0))

let canEquipSelectedUnit = Computed(@() (curSelectedUnit.value in myUnits.value) && (curSelectedUnit.value != curUnit.value?.name))
let isShowedUnitOwned = Computed(@() hangarUnitName.value in myUnits.value)

curUnitName.subscribe(function(v) {
  if (v != null && !isUnitsWndAttached.value && curSelectedUnit.value != null)
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
  isUnitsWndOpened(false)
}

let function onSetCurrentUnit() {
  if (curSelectedUnit.value == null || curUnitInProgress.value != null)
    return
  setCurrentUnit(curSelectedUnit.value)
  isUnitsWndOpened(false)
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
    let price = getUnitAnyPrice(unit, isForLevelUp, unitDiscounts.value)
    if (price != null) {
      let priceComp = mkDiscountPriceComp(price.fullPrice, price.price, price.currencyId, CS_INCREASED_ICON)
      children.append(
        textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")), priceComp,
          onBuyUnit, { hotkeys = ["^J:X"] }))
    }
  }
  else if (canBuyUnitsStatus.value?[curSelectedUnit.value] == US_TOO_LOW_LEVEL){
    let { rank = 0, starRank = 0 } = allUnitsCfg.value.findvalue(@(u) u.name == curSelectedUnit.value)
    let deltaLevels = rank - playerLevelInfo.value.level
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
        textButtonPlayerLevelUp(utf8ToUpper(loc("units/btn_speed_explore")), rank, starRank,
          havePremium.value || premId == null
            ? @() openBuyExpWithUnitWnd(curSelectedUnit.value)
            : @() openGoodsPreview(premId), { hotkeys = ["^J:Y"] })
      )
    }
  }
  children.append(
    (availableUnitsList.value.findvalue(@(unit) unit.name == curSelectedUnit.value)?.platoonUnits.len() ?? 0) > 0
      ? mkCustomButton(
          {
            rendObj = ROBJ_TEXT
            text = loc("squadSize/platoon")
          }.__update(fontSmall),
          @() unitDetailsWnd({ name = hangarUnitName.value }),
          {
            ovr = {
              size = [SIZE_TO_CONTENT,  defButtonHeight]
              fillColor = Color(5, 147, 173)
              borderColor = Color(35, 109, 181)
            }
            gradientOvr = {color = Color(22, 178, 233)}
          }
      )
      : infoBlueButton(
          @() unitDetailsWnd({ name = hangarUnitName.value })
          {
            size = [defButtonHeight, defButtonHeight]
            hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
          }
          fontBig
      )
  )
  return {
    watch = [
      curSelectedUnit, curSelectedUnitPrice, allUnitsCfg,
      canBuyUnits, canEquipSelectedUnit, havePremium,
      canBuyUnitsStatus, playerLevelInfo, curCampaign,
      shopGoods, buyUnitsData, availableUnitsList, unitDiscounts
    ]
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

let hoverBG = @(color){
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture("ui/gameuiskin#hovermenu_shop_button_glow.avif")
  color
}

let function mkPlatoonPlate(unit) {
  let stateFlags = Watched(0)
  if (unit == null)
    return null

  let function onClick() {
    curSelectedUnit(unit.name)
    markUnitSeen(unit)
    if (isHold(unit.name))
      unitDetailsWnd({ name = hangarUnitName.value })
  }
  let isSelected = Computed(@() curSelectedUnit.value == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.value)
  let canPurchase = Computed(@() unit.name in canBuyUnits.value)
  let isLocked = Computed(@() (unit.name not in myUnits.value) && (unit.name not in canBuyUnits.value))
  let canBuyForLvlUp = Computed(@() playerLevelInfo.value.isReadyForLevelUp && (unit?.name in buyUnitsData.value.canBuyOnLvlUp))
  let price = Computed(@() canPurchase.value ? getUnitAnyPrice(unit, canBuyForLvlUp.value, unitDiscounts.value) : null)
  let justUnlockedDelay = Computed(@() justUnlockedUnits.value?[unit.name])
  let needShowUnseenMark = Computed(@() unit.name in unseenUnits.value)
  let color = unit?.isUpgraded || unit?.isPremium ? premBGHoverColor : defaultBgHoverColor
  let discount = Computed(@() unitDiscounts?.value[unit.name])
  return @() {
    watch = [isSelected, stateFlags, justUnlockedDelay, price, discount]
    behavior = Behaviors.Button
    clickableInfo = isSelected.value ? { skipDescription = true } : loc("mainmenu/btnSelect")
    sound = { click  = "choose" }
    onClick
    onElemState = mkOnElemState(unit.name, stateFlags)
    xmbNode = XmbNode()
    flow = FLOW_VERTICAL
    children = [
      {
        size = [ unitPlateWidth, unitPlateHeight ]
        children = [
          mkPlatoonPlates(unit)
          mkUnitBg(unit, {}, justUnlockedDelay.value)
          stateFlags.value & S_HOVER
            ? hoverBG(color)
            : null
          mkPlatoonSelectedGlow(unit, isSelected, justUnlockedDelay.value)
          mkUnitImage(unit)
          mkUnitCanPurchaseShade(canPurchase)
          mkUnitLockedFg(isLocked, justUnlockedDelay.value)
          mkUnitTexts(unit, loc(getUnitLocId(unit)), justUnlockedDelay.value)
          unit.mRank <= 0
            ? null
            : mkUnitLock(unit, isLocked.value, justUnlockedDelay.value)
          mkPlatoonPlateFrame(isEquipped, isLocked, justUnlockedDelay.value)
          mkPlatoonEquippedIcon(unit, isEquipped, justUnlockedDelay.value)
          mkPriorityUnseenMarkWatch(needShowUnseenMark)
          {
            flow = FLOW_HORIZONTAL
            hplace = ALIGN_LEFT
            vplace = ALIGN_BOTTOM
            children = [
              discount.value != null ? discountTagUnitBig(discount.value.discount) : null
              price.value != null ? mkUnitShortPrice(price.value, justUnlockedDelay.value) : null
            ]
          }
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
    markUnitSeen(unit)
    if (isHold(unit.name))
      unitDetailsWnd({ name = hangarUnitName.value })
  }
  let isSelected = Computed(@() curSelectedUnit.value == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.value)
  let canPurchase = Computed(@() unit.name in canBuyUnits.value)
  let canBuyForLvlUp = Computed(@() playerLevelInfo.value.isReadyForLevelUp && (unit?.name in buyUnitsData.value.canBuyOnLvlUp))
  let price = Computed(@() canPurchase.value ? getUnitAnyPrice(unit, canBuyForLvlUp.value, unitDiscounts.value) : null)
  let isLocked = Computed(@() (unit.name not in myUnits.value) && (unit.name not in canBuyUnits.value))
  let justUnlockedDelay = Computed(@() justUnlockedUnits.value?[unit.name])
  let needShowUnseenMark = Computed(@() unit.name in unseenUnits.value)
  let color = unit?.isUpgraded || unit?.isPremium ? premBGHoverColor : defaultBgHoverColor
  let discount = Computed(@() unitDiscounts?.value[unit.name])
  return @() {
    watch = [isSelected, stateFlags, justUnlockedDelay, price, discount]
    size = [ unitPlateWidth, unitsPlateCombinedHeight ]
    behavior = Behaviors.Button
    clickableInfo = isSelected.value ? { skipDescription = true } : loc("mainmenu/btnSelect")
    sound = { click  = "choose" }
    onClick
    onElemState = mkOnElemState(unit.name, stateFlags)
    xmbNode = XmbNode()
    flow = FLOW_VERTICAL
    children = [
      mkUnitEquippedTopLine(isEquipped, justUnlockedDelay.value)
      {
        size = [ unitPlateWidth, unitPlateHeight ]
        transform = {}
        animations = scaleAnimation(justUnlockedDelay.value, [1.05, 1.05])
        children = [
          mkUnitBg(unit, {}, justUnlockedDelay.value)
          stateFlags.value & S_HOVER
            ? hoverBG(color)
            : null
          mkUnitSelectedGlow(unit, isSelected, justUnlockedDelay.value)
          mkUnitImage(unit)
          mkUnitCanPurchaseShade(canPurchase)
          mkUnitLockedFg(isLocked, justUnlockedDelay.value)
          mkUnitTexts(unit, loc(getUnitLocId(unit)), justUnlockedDelay.value)
          unit.mRank <= 0
            ? null
            : mkUnitLock(unit, isLocked.value, justUnlockedDelay.value)
          mkUnitEquippedFrame(unit, isEquipped, justUnlockedDelay.value)
          mkPriorityUnseenMarkWatch(needShowUnseenMark)
          {
            flow = FLOW_HORIZONTAL
            hplace = ALIGN_LEFT
            vplace = ALIGN_BOTTOM
            children = [
              discount.value != null ? discountTagUnitBig(discount.value.discount) : null
              price.value != null ? mkUnitShortPrice(price.value, justUnlockedDelay.value) : null
            ]
          }
        ]
      }
      mkUnitSelectedUnderline(isSelected, justUnlockedDelay.value)
    ]
  }
}

let unseenUnitsIndex = Computed(function(){
  let res = {}
  if (unseenUnits.value.len() == 0 || !isUnitsWndOpened.value)
    return res
  foreach(idx, unit in availableUnitsList.value){
    if(unit.name in unseenUnits.value)
      res[unit.name] <- idx
  }
  return res
})

let needShowUnseenMarkArrowL = Computed(@()
  null != unseenUnitsIndex.value.findvalue(
    @(index) scrollPos.value > (index + 0.2) * (unitPlateWidth + gap.value)))

let needShowUnseenMarkArrowR = Computed(@()
  null != unseenUnitsIndex.value.findvalue(
    @(index) scrollPos.value + sw(100) < (index + 0.5) * (unitPlateWidth + gap.value)))

let scrollArrowsBlock = @(){
  watch = availableUnitsList
  size = [flex(),unitsPlateCombinedHeight]
  pos = [0, (availableUnitsList.value?[0].platoonUnits ?? []).len() > 0 ? hdpx(-15) : 0]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    {
      size = flex()
      children = [
        {
          hplace = ALIGN_LEFT
          pos = [hdpx(50), hdpx(20)]
          children = mkPriorityUnseenMarkWatch(needShowUnseenMarkArrowL)
        }
        mkScrollArrow(scrollHandler, MR_L)
      ]
    }
    {
      size = flex()
      children = [
        {
          hplace = ALIGN_RIGHT
          pos = [-hdpx(50), hdpx(20)]
          children = mkPriorityUnseenMarkWatch(needShowUnseenMarkArrowR)
        }
        mkScrollArrow(scrollHandler, MR_R)
      ]
    }
  ]
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

local listWatches = [availableUnitsList, gap, sizePlatoon]
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
  return {
    watch = listWatches
    key = "unitsWndList"
    size = [filtered.len() == 0 ? flex() : SIZE_TO_CONTENT, unitsPlateCombinedHeight]
    flow = FLOW_HORIZONTAL
    gap = gap.value
    function onAttach() {
      if (curSelectedUnit.value == null)
        curSelectedUnit(curUnitName.value)
      let selUnitIdx = filtered.findindex(@(u) u.name == curSelectedUnit.value) ?? 0
      let scrollPosX = (unitPlateWidth + gap.value) * selUnitIdx - (0.5 * (saSize[0] - unitPlateWidth))
      scrollHandler.scrollToX(scrollPosX)
    }
    children = filtered.len() == 0 ? noUnitsMsg
      : [ unitsBarHorizPad ]
          .extend(filtered.map(@(u) sizePlatoon.value > 0 ? mkPlatoonPlate(u) : mkUnitPlate(u)))
          .append(unitsBarHorizPad)
  }
}

let function closeByBackBtn() {
  close()
  sendNewbieBqEvent("leaveUnitsListWndByBackBtn")
}

let gamercardLevelBlock = {
  children = [
    @(){
      watch = [profileStateFlags, curCampaign]
      rendObj = ROBJ_TEXT
      text = loc($"gamercard/levelCamp/header/{curCampaign.value}")
      flow = FLOW_HORIZONTAL
      pos = [hdpx(70), -hdpx(30)]
      behavior = Behaviors.Button
      onElemState = @(sf) profileStateFlags(sf)
      color = profileStateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
    }.__update(fontSmall)
    {
      size = [0, 0]
      children = doubleSideGradient.__merge(
        {
          padding = [hdpx(5), hdpx(50)]
          pos = [hdpx(20) hdpx(45)]
          children = @() {
            watch = playerLevelInfo
            halign = ALIGN_LEFT
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            maxWidth = hdpx(600)
            text = playerLevelInfo.value?.nextLevelExp == 0
              ? loc("gamercard/levelCamp/maxLevel/campaign")
              : loc("gamercard/levelCamp/desc")
          }.__update(fontVeryTiny)
        })
    }
    levelBlock({pos = [0, 0]}, { size = [levelProgressWidth, levelProgressBarHeight] }, true)
  ]
}

let mkLevelBlock = @(backCb) {
  size = [ SIZE_TO_CONTENT, gamercardHeight ]
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_LEFT
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = [
    backCb != null ? backButton(backCb, { vplace = ALIGN_CENTER }) : null
    gamercardLevelBlock
  ]
}

let mkGamercardUnitWnd = @(backCb = null) {
  size = [ saSize[0], gamercardHeight ]
  hplace = ALIGN_CENTER
  children = [
    mkLevelBlock(backCb)
    gamercardWithoutLevelBlock
  ]
}

let gamercardPlace = {
  children = [
    mkGamercardUnitWnd(closeByBackBtn)
    unitInfoPanel({
      pos = unitInfoPanelDefPos
      behavior = [ Behaviors.Button, Behaviors.HangarCameraControl ]
      eventPassThrough = true
      onClick = @() unitDetailsWnd({ name = hangarUnitName.value })
      clickableInfo = loc("msgbox/btn_more")
      hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
    }, mkUnitTitle )
  ]
}

let function platoonsHeader() {
  let revealDelay = Computed(@() !justBoughtUnits.value ? null
    : !justUnlockedUnits.value ? RAISE_PLATE_TOTAL + 1.0
    : UNLOCK_DELAY + RAISE_PLATE_TOTAL + 1.0)

  return curCampaign.value != "tanks" ? { watch = [curCampaign] } : {
    watch = [curCampaign]
    size = [hdpx(500), hdpx(80)]
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
  function onAttach() {
    isUnitsWndAttached(true)
    sendNewbieBqEvent("openUnitsListWnd")
  }
  onDetach = @() isUnitsWndAttached(false)
  children = [
    lqTexturesWarningHangar
    {
      size = [ flex(), unitsPlateCombinedHeight]
      pos = [ 0, sh(100) - unitsPlateCombinedHeight - saBorders[1] ]
      valign = ALIGN_CENTER
      children = [
        horizontalPannableAreaCtor(sw(100),
          [saBorders[0], saBorders[0]], [hdpx(10), hdpx(10)])(unitsBlock,
            {},
            {
              behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ],
              scrollHandler = scrollHandler
            }
          )
        scrollArrowsBlock
      ]
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

registerScene("unitsWnd", unitsWnd, close, isUnitsWndOpened)

return function(value = null) {
  curSelectedUnit(value)
  isUnitsWndOpened(true)
}
