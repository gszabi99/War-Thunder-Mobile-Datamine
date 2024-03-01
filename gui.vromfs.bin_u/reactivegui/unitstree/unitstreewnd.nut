from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { isUnitsTreeOpen, closeUnitsTreeWnd, unitsMapped, countriesCfg, countriesRows, columnsCfg,
  unitsMaxRank, unitsMaxStarRank, unitsTreeBg, unitsTreeOpenRank, isUnitsTreeAttached
} = require("%rGui/unitsTree/unitsTreeState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { gamercardHeight, mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { playerLevelInfo, myUnits } = require("%appGlobals/pServer/profile.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitLock, mkPlatoonPlateFrame,
  mkUnitsTreePrice, bgPlatesTranslate, platoonPlatesGap,
  mkUnitSelectedGlow, mkUnitEquippedIcon, unitPlateSmall, mkPlateText, plateTextsSmallPad
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getUnitLocId, getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { canBuyUnits, buyUnitsData } = require("%appGlobals/unitsState.nut")
let { mkFlags, flagsWidth, levelMarkSize, levelMark, speedUpBtn, levelUpBtn, mkProgressBar,
  progressBarHeight, bgLight, noUnitsMsg, btnSize, platesGap
} = require("unitsTreeComps.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { discountTagUnit } = require("%rGui/components/discountTag.nut")
let { unitInfoPanel, mkUnitTitle, statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { curSelectedUnit, availableUnitsList, sizePlatoon, curUnitName } = require("%rGui/unit/unitsWndState.nut")
let { unitActions } = require("%rGui/unit/unitsWndActions.nut")
let { abs } = require("%sqstd/math.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { openExpWnd } = require("%rGui/mainMenu/expWndState.nut")
let { levelBorder } = require("%rGui/components/levelBlockPkg.nut")
let { unseenUnits, markUnitSeen } = require("%rGui/unit/unseenUnits.nut")
let { unseenSkins } = require("%rGui/unitSkins/unseenSkins.nut")
let { mkPriorityUnseenMarkWatch, priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { defer, resetTimeout } = require("dagor.workcycle")
let { lvlUpCost, openLvlUpWndIfCan, hasDataForLevelWnd, isSeen, isLvlUpAnimated
} = require("%rGui/levelUp/levelUpState.nut")
let { selectedLineHor } = require("%rGui/components/selectedLine.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { justBoughtUnits, deleteJustBoughtUnit } = require("%rGui/unit/justUnlockedUnits.nut")
let { revealAnimation, raisePlatesAnimation } = require("%rGui/unit/components/unitUnlockAnimation.nut")
let { ceil } = require("math")
let { isFiltersVisible, filterStateFlags, openFilters, filters, activeFilters
} = require("%rGui/unit/unitsFilterPkg.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { clearFilters } = require("%rGui/unit/unitsFilterState.nut")


let framesGapMul = 0.7
let infoPanelPadding = hdpx(45)
let gamercardOverlap = hdpx(55)
let selLineGap = hdpx(10)
let filterIconSize = hdpxi(36)
let clearIconSize = hdpxi(45)
let infoPanelBgColor = 0xE0000000
let unitPlateSize = unitPlateSmall
let blockSize = [unitPlateSize[0] + platesGap[0], unitPlateSize[1] + platesGap[1]]
let scrollBlocks = ceil((saSize[0] - saBorders[0] - flagsWidth) / blockSize[0] / 2)
let SCROLL_DELAY = 1.5
let flagTreeOffset = hdpx(60)

let scrollHandler = ScrollHandler()
let scrollPos = Computed(@() (scrollHandler.elem?.getScrollOffsX() ?? 0))
let nodeToScroll = Watched(null)

let unseenUnitsIndex = Computed(function() {
  let res = {}
  if (!isUnitsTreeOpen.get() || (unseenUnits.get().len() == 0 && unseenSkins.get().len() == 0))
    return res
  foreach(unit in availableUnitsList.value) {
    if(unit.name in unseenUnits.get() || unit.name in unseenSkins.get())
      res[unit.name] <- columnsCfg.value[unit.rank]
  }
  return res
})

let needShowArrowL = Computed(function() {
  let offsetIdx = (scrollPos.get() - flagTreeOffset).tofloat() / blockSize[0] - 1
  return null != unseenUnitsIndex.get().findvalue(@(index) offsetIdx > index)
})

let needShowArrowR = Computed(function() {
  let offsetIdx = (scrollPos.get() + sw(100) - 2 * saBorders[0] - flagsWidth - flagTreeOffset).tofloat() / blockSize[0]
    - 1
  return null != unseenUnitsIndex.get().findvalue(@(index) offsetIdx < index)
})

function scrollToUnit(name, xmbNode = null) {
  if (!name)
    return
  let selUnitIdx = availableUnitsList.value.findvalue(@(u) u.name == name)?.rank ?? 1
  let scrollPosX = blockSize[0] * (columnsCfg.value[selUnitIdx] + 1) - (0.4 * (saSize[0] - flagsWidth))
  if (abs(scrollPosX - scrollPos.value) > saSize[0] * 0.1)
    if (!xmbNode)
      scrollHandler.scrollToX(scrollPosX)
    else
      gui_scene.setXmbFocus(xmbNode)
}

function scrollToRank(rank) {
  let scrollPosX = blockSize[0] * ((columnsCfg.value?[rank] ?? 0) + 1) - 0.5 * (saSize[0] - flagsWidth)
  scrollHandler.scrollToX(scrollPosX)
}

function scrollForward() {
  if (nodeToScroll.get() != null)
    resetTimeout(SCROLL_DELAY, @() gui_scene.setXmbFocus(nodeToScroll.get()))
}
isLvlUpAnimated.subscribe(@(v) v ? scrollForward() : null)

let openFiltersPopup = @(e) openFilters(e, {
  popupOffset = levelMarkSize + hdpx(10)
  popupValign = ALIGN_TOP
  popupHalign = ALIGN_CENTER
})

function onBackButtonClick() {
  closeUnitsTreeWnd()
  curSelectedUnit.set(null)
}

let unselectBtn = {
  behavior = Behaviors.Button
  onClick = @() isLvlUpAnimated.get() ? null : curSelectedUnit.set(null)
}

let unitFilterButton = @() {
  watch = [isGamepad, filterStateFlags]
  size = btnSize
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_BOX
  borderWidth = hdpxi(1)
  fillColor = filterStateFlags.get() & S_ACTIVE ? 0x20000000 : 0x50000000
  borderColor = 0xFFFFFFFF
}.__update(isGamepad.get()
    ? {
        key = filterStateFlags
        children = { hotkeys = [["^J:LT", loc("filter"), openFiltersPopup]] }
      }
  : {
      padding = [hdpx(10), hdpx(25)]
      behavior = Behaviors.Button
      onElemState = @(s) filterStateFlags(s)
      onClick = openFiltersPopup
      flow = FLOW_HORIZONTAL
      gap = hdpx(20)
      children = [
        {
          size = [filterIconSize, filterIconSize]
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#filter_icon.svg:{filterIconSize}:{filterIconSize}:P")
        }
        {
          rendObj = ROBJ_TEXT
          text = loc("filter")
        }.__update(fontTinyAccented)
      ]
      transform = {
        scale = filterStateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1]
      }
    })

let clearFiltersButton = @() {
  key = {}
  size = [btnSize[1], btnSize[1]]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_BOX
  borderWidth = hdpxi(1)
  fillColor = 0x50000000
  borderColor = 0xFFFFFFFF
  behavior = Behaviors.Button
  onClick = clearFilters
  animations = wndSwitchAnim
  children = {
    size = [clearIconSize, clearIconSize]
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"ui/gameuiskin#btn_trash.svg:{clearIconSize}:{clearIconSize}:P")
  }
}

let mkTreeBg = @(isVisible) @() !isVisible.value ? { watch = isVisible } : {
  watch = [unitsTreeBg, isVisible]
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/images/{unitsTreeBg.get()}:0:P")
}.__merge(unselectBtn)

function mkPlatoonPlates(unit) {
  let { platoonUnits = [] } = unit
  let platoonSize = platoonUnits.len()
  let isLocked = Computed(@() (unit.name not in myUnits.value) && (unit.name not in canBuyUnits.value))
  let isSelected = Computed(@() curSelectedUnit.value == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.value)
  let justBoughtDelay = Computed(@() justBoughtUnits.value?[unit.name] != null ? 0.5 : null)

  return @() {
    watch = [isSelected, isLocked, justBoughtDelay]
    size = flex()
    children = platoonUnits?.map(@(_, idx) {
      size = flex()
      transform = {
        translate = bgPlatesTranslate(platoonSize, idx, isSelected.value || (justBoughtDelay.get() != null), framesGapMul)
      }
      transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
      animations = raisePlatesAnimation(justBoughtDelay.value,
        bgPlatesTranslate(platoonSize, idx, isSelected.value || (justBoughtDelay.get() != null), framesGapMul), idx,
          platoonSize, @() deleteJustBoughtUnit(unit.name))
      children = [
        mkUnitBg(unit, isLocked.get())
        mkPlatoonPlateFrame(unit, isEquipped, isSelected)
        !justBoughtDelay.value ? null : mkPlateText(loc(getUnitPresentation(platoonUnits?[platoonSize - idx - 1]).locId),
          {
            vplace = ALIGN_TOP
            hplace = ALIGN_RIGHT
            padding = plateTextsSmallPad
            animations = revealAnimation()
            maxWidth = unitPlateSize[0]
          })
      ]
    })
  }
}

function mkUnitPlate(unit, ovr = {}) {
  if (unit == null)
    return null

  let xmbNode = XmbNode()
  let stateFlags = Watched(0)
  let isLocked = Computed(@() (unit.name not in myUnits.value) && (unit.name not in canBuyUnits.value))
  let isSelected = Computed(@() curSelectedUnit.value == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.value)
  let canPurchase = Computed(@() unit.name in canBuyUnits.value)
  let canBuyForLvlUp = Computed(@() playerLevelInfo.value.isReadyForLevelUp && (unit?.name in buyUnitsData.value.canBuyOnLvlUp))
  let price = Computed(@() canPurchase.value ? getUnitAnyPrice(unit, canBuyForLvlUp.value, unitDiscounts.value) : null)
  let discount = Computed(@() unitDiscounts?.value[unit.name])
  let isPremium = unit?.isUpgraded || unit?.isPremium
  let needShowUnseenMark = Computed(@() unit.name in unseenUnits.get() || unit.name in unseenSkins.get())
  let justUnlockedDelay = Computed(@() hasModalWindows.get() && canBuyForLvlUp.get() ? 1000000.0
    : canBuyForLvlUp.get()
        && hasDataForLevelWnd.get()
        && !hasModalWindows.get()
        && !isSeen.get()
            ? 1.0
          : null)

  return @() {
    watch = [isSelected, isLocked, canPurchase, justUnlockedDelay]
    size = unitPlateSize
    behavior = Behaviors.Button
    function onClick() {
      if (isLvlUpAnimated.get())
        return
      curSelectedUnit.set(unit.name)
      scrollToUnit(unit.name, xmbNode)
      markUnitSeen(unit)
    }
    onAttach = unitsTreeOpenRank.get() != null
      && unit.rank == (unitsTreeOpenRank.get() + min(scrollBlocks, unitsMaxRank.get() - playerLevelInfo.get().level))
          ? nodeToScroll.set(xmbNode)
        : null
    onElemState = @(s) stateFlags(s)
    clickableInfo = isSelected.value ? { skipDescription = true } : loc("mainmenu/btnSelect")
    xmbNode
    sound = { click  = "choose" }
    children = [
      mkPlatoonPlates(unit)
      mkUnitBg(unit, isLocked.get(), justUnlockedDelay.get())
      mkUnitSelectedGlow(unit, Computed(@() isSelected.get() || (stateFlags.value & S_HOVER)), justUnlockedDelay.get())
      mkUnitImage(unit, canPurchase.get() || isLocked.get())
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)), isLocked.get())
      mkUnitLock(unit, isLocked.value, justUnlockedDelay.get())
      mkPriorityUnseenMarkWatch(needShowUnseenMark)
      @() {
        watch = [price, discount, justUnlockedDelay]
        flow = FLOW_HORIZONTAL
        hplace = ALIGN_LEFT
        vplace = ALIGN_BOTTOM
        valign = ALIGN_BOTTOM
        children = [
          discount.value != null ? discountTagUnit(discount.value.discount) : null
          price.get() != null && price.get().price > 0 ? mkUnitsTreePrice(price.get(), justUnlockedDelay.get()) : null
        ]
      }
      mkPlatoonPlateFrame(unit, isEquipped, isSelected, justUnlockedDelay.get())
      mkUnitEquippedIcon(unit, isEquipped, justUnlockedDelay.get())
      {
        size = flex()
        pos = [0, unitPlateSize[1] + selLineGap]
        children = selectedLineHor(isSelected, isPremium)
      }
    ]
  }.__update(ovr)
}

function mkUnitsBlock(listByCountry, rowIdx) {
  let mkPos = @(idx, slot) [
    blockSize[0] * (columnsCfg.value[idx + 1] + slot)
      + platoonPlatesGap * framesGapMul * sizePlatoon.value
      + platesGap[0] * 0.5,
    blockSize[1] * rowIdx
      + platoonPlatesGap * framesGapMul * sizePlatoon.value * 0.5
      + platesGap[1] * 0.5
      + levelMarkSize
  ]

  return @() {
    watch = [columnsCfg, sizePlatoon]
    valign = ALIGN_CENTER
    children = listByCountry.values().map(@(units, idx) {
      children = units.map(@(u, slot) mkUnitPlate(u, { pos = mkPos(idx, slot) }))
    })
  }
}

function mkLevelProgress(_, idx) {
  let slots = columnsCfg.value[idx + 2] - columnsCfg.value[idx + 1]
  if (slots <= 0)
    return null

  let { level, exp, nextLevelExp } = playerLevelInfo.value
  let hasLevelGap = columnsCfg.get()?[idx + 3] == columnsCfg.get()[idx + 2]
  let hasNextLevel = level >=
    (columnsCfg.get().findindex(@(v, key) v > columnsCfg.get()[idx + 1] && columnsCfg.get()?[key + 1] != v) ?? 0)
  let barWidth = slots * blockSize[0] - levelMarkSize + progressBarHeight + levelBorder
  let levelCompleted = level >= idx + 2
  let current = levelCompleted ? 1
    : level == idx + 1 ? exp
    : 0
  let required = levelCompleted ? 1 : nextLevelExp
  let levelCompletion = current >= required || required == 0 ? 1.0
    : clamp(current.tofloat() / required * 0.97, 0.0, 0.97)

  return @() {
    watch = [columnsCfg, playerLevelInfo, sizePlatoon, unitsMaxRank, unitsMaxStarRank]
    pos = [blockSize[0] * (columnsCfg.value[idx + 1] + 0.5) - levelMarkSize * 0.5, 0]
    children = [
      {
        size = [SIZE_TO_CONTENT, levelMarkSize]
        valign = ALIGN_CENTER
        children = unitsMaxRank.value == idx + 1 ? null
          : mkProgressBar(levelCompletion, barWidth, slots, hasLevelGap, hasNextLevel,
              { pos = [levelMarkSize - progressBarHeight * 0.5, hdpx(1)] })
      }
      levelMark(
        idx + 1,
        max(0, idx + 1 - unitsMaxRank.value + unitsMaxStarRank.value),
        level >= idx + 1
      )
    ]
  }
}

local listWatches = [unitsMapped, columnsCfg, unitsMaxRank, curUnitName, curSelectedUnit]
foreach (f in filters)
  listWatches.append(f?.value, f?.allValues)
listWatches = listWatches.filter(@(w) w != null)

let unitsTree = @() {
  watch = listWatches
  size = [
    columnsCfg.value["0"] * blockSize[0] + (!curSelectedUnit.get() ? 0 : (statsWidth + platesGap[0])),
    countriesRows * blockSize[1]]
  onAttach = @() defer(@() unitsTreeOpenRank.get() != null
      ? scrollToRank(unitsTreeOpenRank.get())
    : scrollToUnit(curSelectedUnit.value ?? curUnitName.value))
  children = [unselectBtn.__merge({ size = flex(), pos = [0, levelMarkSize]})]
    .extend(
      array(unitsMaxRank.value).map(mkLevelProgress),
      unitsMapped.get().units.len() == 0 ? [noUnitsMsg] : unitsMapped.get().units.values().map(mkUnitsBlock))
}

let unseenArrowsBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  pos = [0, hdpx(25)]
  children = [
    @() {
      watch = needShowArrowL
      size = [flex(), SIZE_TO_CONTENT]
      pos = [-flagTreeOffset, 0]
      children = !needShowArrowL.value ? null : [
        {
          hplace = ALIGN_LEFT
          pos = [0, -hdpx(20)]
          children = priorityUnseenMark
        }
        mkScrollArrow(scrollHandler, MR_L, scrollArrowImageSmall)
      ]
    }
    @() {
      watch = needShowArrowR
      size = [flex(), SIZE_TO_CONTENT]
      pos = [saBorders[0] * 0.5, 0]
      children = !needShowArrowR.value ? null : [
        {
          hplace = ALIGN_RIGHT
          pos = [0, -hdpx(20)]
          children = priorityUnseenMark
        }
        mkScrollArrow(scrollHandler, MR_R, scrollArrowImageSmall)
      ]
    }
  ]
}

let pannableArea = horizontalPannableAreaCtor(sw(100) - flagsWidth - saBorders[0], [flagTreeOffset, saBorders[0]])(
  unitsTree,
  {},
  {
    behavior = [Behaviors.Pannable, Behaviors.ScrollEvent],
    scrollHandler
    xmbNode = {
      canFocus = @() false
      scrollSpeed = 2.5
      isViewport = true
      scrollToEdge = false
      screenSpaceNav = true
    }
  })

let unitsTreeContent = @() {
  pos = [0, gamercardHeight + saBorders[1] - gamercardOverlap]
  children = [
    {
      pos = [0, levelMarkSize]
      flow = FLOW_VERTICAL
      children = array(countriesRows).map(@(_, rowIdx)
        { size = [sw(100), blockSize[1]] }.__merge(unselectBtn, rowIdx % 2 == 1 ? {} : bgLight))
    }
    {
      pos = [saBorders[0] + flagsWidth + flagTreeOffset, 0]
      size = [sw(100) - flagsWidth - 2* saBorders[0] - flagTreeOffset, blockSize[1] * countriesRows + levelMarkSize]
      children = [
        pannableArea
        unseenArrowsBlock
      ]
    }
    @() {
      watch = unitsMapped
      pos = [saBorders[0], levelMarkSize]
      flow = FLOW_VERTICAL
      children = unitsMapped.get().units.keys()
        .map(@(idx) mkFlags(countriesCfg?[idx].filter(@(country) unitsMapped.get().visibleCountries?[country]), blockSize[1]))
    }
  ]
}

let unitsTreeGamercard = {
  size = [flex(), gamercardHeight]
  valign = ALIGN_TOP
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    backButton(onBackButtonClick, { vplace = ALIGN_CENTER })

    {
      pos = [0, hdpx(5)]
      rendObj = ROBJ_TEXT
      text = loc("unitsTree/campaignLevel")
    }.__update(isWidescreen ? fontMedium : fontSmall)

    @() {
      watch = [playerLevelInfo, lvlUpCost, isLvlUpAnimated]
      children = playerLevelInfo.get().isReadyForLevelUp
          ? levelUpBtn(isLvlUpAnimated.get() ? null : openLvlUpWndIfCan)
        : playerLevelInfo.get()?.nextLevelExp != 0
          ? speedUpBtn(isLvlUpAnimated.get() ? null : openExpWnd,
              lvlUpCost.get(),
              playerLevelInfo.get().level,
              playerLevelInfo.get().starLevel,
              playerLevelInfo.get()?.isStarProgress ?? false)
        : null
    }

    unitFilterButton

    @() {
      watch = [activeFilters, isFiltersVisible]
      children = activeFilters.get() > 0 && !isFiltersVisible.get() ? clearFiltersButton : null
    }

    { size = flex() }

    mkCurrenciesBtns([WP, GOLD], null, { pos = [0, hdpx(5)] })
  ]
}

let infoPanel = @() {
  watch = curSelectedUnit
  key = {}
  size = flex()
  padding = saBordersRv
  children = !curSelectedUnit.value ? null : [
    unitInfoPanel({
      pos = [saBorders[0] + infoPanelPadding, gamercardHeight + levelMarkSize - gamercardOverlap]
      hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
      color = infoPanelBgColor
      padding = [infoPanelPadding, saBorders[0] + infoPanelPadding]
      animations = wndSwitchAnim
    }, mkUnitTitle)
    unitActions
  ]
}

let unitsTreeWnd = {
  key = {}
  size = [sw(100), sh(100)]
  children = [
    mkTreeBg(isUnitsTreeOpen)
    {
      size = [sw(100), SIZE_TO_CONTENT]
      padding = [saBorders[1], saBorders[0], 0, saBorders[0]]
      children = unitsTreeGamercard
    }

    unitsTreeContent
    infoPanel
  ]
  onAttach = @() isUnitsTreeAttached.set(true)
  function onDetach() {
    isUnitsTreeAttached.set(false)
    unitsTreeOpenRank.set(null)
  }
  animations = wndSwitchAnim
}

registerScene("unitsTreeWnd", unitsTreeWnd, closeUnitsTreeWnd, isUnitsTreeOpen)
