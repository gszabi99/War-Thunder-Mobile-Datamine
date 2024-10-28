from "%globalsDarg/darg_library.nut" import *
let { set_camera_shift_centered, set_camera_shift_upper } = require("hangar")
let { get_time_msec } = require("dagor.time")
let { HangarCameraControl } = require("wt.behaviors")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { wndSwitchAnim, WND_REVEAL } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { levelBlock, gamercardWithoutLevelBlock, gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { playerLevelInfo, allUnitsCfg, myUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitPresentation, getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { hangarUnitName, loadedHangarUnitName } = require("hangarUnit.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { buyUnitsData, canBuyUnits } = require("%appGlobals/unitsState.nut")
let { translucentButtonsVGap } = require("%rGui/components/translucentButton.nut")
let { unitPlateWidth, unitPlateHeight, unutEquppedTopLineFullHeight, unitSelUnderlineFullSize,
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitLock, mkUnitShortPrice,
  mkUnitEquippedFrame, mkUnitEquippedTopLine, mkUnitSelectedUnderline,
  mkPlatoonPlateFrame, platoonSelPlatesGap, mkPlatoonEquippedIcon,
  bgPlatesTranslate, mkPlateText, plateTextsSmallPad
} = require("%rGui/unit/components/unitPlateComp.nut")
let { unitInfoPanel, mkUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
let { btnOpenUnitAttr } = require("%rGui/attributes/unitAttr/btnOpenUnitAttr.nut")
let { curFilters } = require("%rGui/unit/unitsFilterState.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let mkUnitPkgDownloadInfo = require("mkUnitPkgDownloadInfo.nut")
let { isPurchEffectVisible } = require("unitPurchaseEffectScene.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
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
let { curSelectedUnit, availableUnitsList, sizePlatoon, curUnitName } = require("%rGui/unit/unitsWndState.nut")
let { unitActions } = require("%rGui/unit/unitsWndActions.nut")
let { isFiltersVisible, filterStateFlags, activeFilters, getFiltersText, openFilters, filters
} = require("%rGui/unit/unitsFilterPkg.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

const MIN_HOLD_MSEC = 700
let profileStateFlags = Watched(0)

let gapFromUnitsBlockToBtns = hdpx(4)
let levelProgressWidth = hdpx(600)

isUnitsWndAttached.subscribe(function(v) {
  if (v)
    set_camera_shift_upper()
  else if (!isPurchEffectVisible.value)
    set_camera_shift_centered()
})
loadedHangarUnitName.subscribe(@(_) isUnitsWndAttached.value ? set_camera_shift_upper() : null)

let holdInfo = {} //unitName = { press = int, release = int }

let scrollHandler = ScrollHandler()
let scrollPos = Computed(@() (scrollHandler.elem?.getScrollOffsX() ?? 0))

let gap = Computed(@() (sizePlatoon.value + 0.8) * platoonSelPlatesGap)

let isShowedUnitOwned = Computed(@() hangarUnitName.value in myUnits.value)

let isFitAllFilters = @(unit) filters.findvalue(@(f) f.value.value != null && !f.isFit(unit, f.value.value)) == null
curFilters.subscribe(function(v) {
  if (v.len() == 0 || !isUnitsWndOpened.get())
    return
  let unit = allUnitsCfg.value?[curSelectedUnit.value]
  if (unit != null && isFitAllFilters(unit))
    return
  let first = availableUnitsList.value.findvalue(isFitAllFilters)
  curSelectedUnit(first?.name)
})

function close() {
  curSelectedUnit(null)
  isUnitsWndOpened(false)
}

let unitsPlateCombinedHeight = unutEquppedTopLineFullHeight + unitPlateHeight + unitSelUnderlineFullSize

let unitFilterButton = @() {
  watch = [isFiltersVisible, isGamepad]
  vplace = ALIGN_TOP
  pos = [saBorders[0], saBorders[1] + saSize[1]]
}.__update(isGamepad.value
  ? {
      key = filterStateFlags
      children = { hotkeys = [[
        "^J:LT",
        getFiltersText(activeFilters.value),
        @(e) openFilters(e, curCampaign.get() in serverConfigs.get()?.unitTreeNodes)
      ]] }
    }
  : {
      padding = hdpx(10)
      rendObj = ROBJ_SOLID
      color = isFiltersVisible.value ? 0xA0000000 : 0

      behavior = Behaviors.Button
      onElemState = @(s) filterStateFlags(s)
      onClick = @(e) openFilters(e, curCampaign.get() in serverConfigs.get()?.unitTreeNodes)
      children = @() {
        watch = [filterStateFlags, activeFilters]
        rendObj = ROBJ_TEXT
        color = activeFilters.value > 0 || (filterStateFlags.value & S_ACTIVE) ? 0xFFFFFFFF : 0xFFA0A0A0
        text = getFiltersText(activeFilters.value)
      }.__update(fontTiny)
      transitions = [{ prop = AnimProp.color, duration = 0.3, easing = InOutQuad }]
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

function isHold(id) {
  local { release = 0, press = 0 } = holdInfo?[id]
  let time = release < press ? get_time_msec() - press
    : get_time_msec() - release < 50 ? release - press
    : 0
  return time >= MIN_HOLD_MSEC
}

function mkPlatoonPlates(unit) {
  let platoonUnits = unit.platoonUnits
  let platoonSize = platoonUnits?.len() ?? 0
  let isLocked = Computed(@() (unit.name not in myUnits.value) && (unit.name not in canBuyUnits.value))
  let isSelected = Computed(@() curSelectedUnit.value == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.value)
  let justUnlockedDelay = Computed(@() justUnlockedUnits.value?[unit.name])
  let justBoughtDelay = Computed(@() !justBoughtUnits.value?[unit.name] ? null
    : justUnlockedDelay.value ? justBoughtUnits.value?[unit.name]
    : WND_REVEAL)

  return @() {
    watch = [isSelected, justUnlockedDelay, justBoughtDelay, isLocked]
    size = flex()
    children = platoonUnits?.map(@(_, idx) {
      size = flex()
      transform = { translate = bgPlatesTranslate(platoonSize, idx, isSelected.value || justBoughtDelay.value) }
      transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
      animations = raisePlatesAnimation(justBoughtDelay.value,
        bgPlatesTranslate(platoonSize, idx, isSelected.value || justBoughtDelay.value), idx, platoonSize,
          @() deleteJustBoughtUnit(unit.name))
      children = [
        mkUnitBg(unit, isLocked.get(), justUnlockedDelay.value)
        mkPlatoonPlateFrame(unit, isEquipped, isSelected, justUnlockedDelay.value)
        !justBoughtDelay.value ? null : mkPlateText(loc(getUnitPresentation(platoonUnits?[platoonSize - idx - 1]).locId),
          { vplace = ALIGN_TOP, hplace = ALIGN_RIGHT, padding = plateTextsSmallPad, animations = revealAnimation() })
      ]
    })
  }
}

function mkPlatoonPlate(unit) {
  let stateFlags = Watched(0)
  if (unit == null)
    return null

  function onClick() {
    curSelectedUnit(unit.name)
    markUnitSeen(unit)
    if (isHold(unit.name))
      unitDetailsWnd({ name = hangarUnitName.value })
  }
  let isSelected = Computed(@() curSelectedUnit.value == unit.name || (stateFlags.value & S_HOVER))
  let isEquipped = Computed(@() unit.name == curUnitName.value)
  let canPurchase = Computed(@() unit.name in canBuyUnits.value)
  let isLocked = Computed(@() (unit.name not in myUnits.value) && (unit.name not in canBuyUnits.value))
  let canBuyForLvlUp = Computed(@() playerLevelInfo.value.isReadyForLevelUp && (unit?.name in buyUnitsData.value.canBuyOnLvlUp))
  let price = Computed(@() canPurchase.value ? getUnitAnyPrice(unit, canBuyForLvlUp.value, unitDiscounts.value) : null)
  let justUnlockedDelay = Computed(@() justUnlockedUnits.value?[unit.name])
  let needShowUnseenMark = Computed(@() unit.name in unseenUnits.value)
  let discount = Computed(@() unitDiscounts?.value[unit.name])
  return @() {
    watch = [isSelected, justUnlockedDelay, price, discount, isLocked, canPurchase]
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
          mkUnitBg(unit, isLocked.get(), justUnlockedDelay.value)
          mkUnitSelectedGlow(unit, isSelected, justUnlockedDelay.value)
          mkUnitImage(unit, canPurchase.get() || isLocked.get())
          mkUnitTexts(unit, loc(getUnitLocId(unit)), isLocked.get())
          unit.mRank <= 0
            ? null
            : mkUnitLock(unit, isLocked.value, justUnlockedDelay.value)
          mkPlatoonPlateFrame(unit, isEquipped, isSelected, justUnlockedDelay.value)
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
      mkUnitSelectedUnderline(unit, isSelected, justUnlockedDelay.value)
    ]
  }
}

function mkUnitPlate(unit) {
  let stateFlags = Watched(0)
  if (unit == null)
    return null

  function onClick() {
    curSelectedUnit(unit.name)
    markUnitSeen(unit)
    if (isHold(unit.name))
      unitDetailsWnd({ name = hangarUnitName.value })
  }
  let isSelected = Computed(@() curSelectedUnit.value == unit.name || (stateFlags.value & S_HOVER))
  let isEquipped = Computed(@() unit.name == curUnitName.value)
  let canPurchase = Computed(@() unit.name in canBuyUnits.value)
  let canBuyForLvlUp = Computed(@() playerLevelInfo.value.isReadyForLevelUp && (unit?.name in buyUnitsData.value.canBuyOnLvlUp))
  let price = Computed(@() canPurchase.value ? getUnitAnyPrice(unit, canBuyForLvlUp.value, unitDiscounts.value) : null)
  let isLocked = Computed(@() (unit.name not in myUnits.value) && (unit.name not in canBuyUnits.value))
  let justUnlockedDelay = Computed(@() justUnlockedUnits.value?[unit.name])
  let needShowUnseenMark = Computed(@() unit.name in unseenUnits.value)
  let discount = Computed(@() unitDiscounts?.value[unit.name])
  return @() {
    watch = [isSelected, stateFlags, justUnlockedDelay, price, discount, isLocked, canPurchase]
    size = [ unitPlateWidth, unitsPlateCombinedHeight ]
    behavior = Behaviors.Button
    clickableInfo = isSelected.value ? { skipDescription = true } : loc("mainmenu/btnSelect")
    sound = { click  = "choose" }
    onClick
    onElemState = mkOnElemState(unit.name, stateFlags)
    xmbNode = XmbNode()
    flow = FLOW_VERTICAL
    children = [
      mkUnitEquippedTopLine(unit, isEquipped, justUnlockedDelay.value)
      {
        size = [ unitPlateWidth, unitPlateHeight ]
        transform = {}
        animations = scaleAnimation(justUnlockedDelay.value, [1.05, 1.05])
        children = [
          mkUnitBg(unit, isLocked.get(), justUnlockedDelay.value)
          mkUnitSelectedGlow(unit, isSelected)
          mkUnitImage(unit, canPurchase.get() || isLocked.get())
          mkUnitTexts(unit, loc(getUnitLocId(unit)), isLocked.get())
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
      mkUnitSelectedUnderline(unit, isSelected, justUnlockedDelay.value)
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

function unitsBlock() {
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

function closeByBackBtn() {
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

let unitButtons = @() {
  watch = [isShowedUnitOwned, isFiltersVisible]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    isShowedUnitOwned.get() && !isFiltersVisible.get() ? btnOpenUnitAttr : null
    { size = flex() }
    unitActions
  ]
}

let gamercardPlace = {
  size = flex()
  flow = FLOW_VERTICAL
  children = [
    mkGamercardUnitWnd(closeByBackBtn)
    unitInfoPanel({
      size = [SIZE_TO_CONTENT, flex()]
      hplace = ALIGN_RIGHT
      behavior = [ Behaviors.Button, HangarCameraControl ]
      eventPassThrough = true //compatibility with 2024.09.26 (before touchMarginPriority introduce)
      touchMarginPriority = TOUCH_BACKGROUND
      onClick = @() unitDetailsWnd({ name = hangarUnitName.value })
      clickableInfo = loc("msgbox/btn_more")
      hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
    }, mkUnitTitle )
    unitButtons
  ]
}

function platoonsHeader() {
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
  behavior = HangarCameraControl
  eventPassThrough = true //compatibility with 2024.09.26 (before touchMarginPriority introduce)
  touchMarginPriority = TOUCH_BACKGROUND
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
            { clipChildren = false },
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
