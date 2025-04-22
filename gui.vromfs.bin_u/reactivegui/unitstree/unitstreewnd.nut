from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { abs } = require("math")
let { buyUnitsData } = require("%appGlobals/unitsState.nut")
let { registerScene } = require("%rGui/navState.nut")
let { isUnitsTreeOpen, closeUnitsTreeWnd, mkAllTreeUnits, countriesCfg, countriesRows,
  unitsMaxRank, unitsMaxStarRank, unitsTreeBg, unitsTreeOpenRank, isUnitsTreeAttached,
  mapUnitsByCountryGroup, getColumnsCfg
} = require("%rGui/unitsTree/unitsTreeState.nut")
let { levelInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton, backButtonHeight } = require("%rGui/components/backButton.nut")
let { gamercardHeight, mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { playerLevelInfo, campMyUnits, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { platoonPlatesGap } = require("%rGui/unit/components/unitPlateComp.nut")
let { releasedUnits } = require("%rGui/unit/unitState.nut")
let { mkFlags, flagsWidth, levelMarkSize, levelMark, speedUpBtn, levelUpBtn, mkTreeRankProgressBar,
  progressBarHeight, bgLight, noUnitsMsg, btnSize, platesGap,
  blockSize, flagTreeOffset, gamercardOverlap, infoPanelWidth,
  RGAP_HAS_GAP, RGAP_HAS_NEXT_LEVEL, RGAP_RECEIVED_NEXT_LEVEL
} = require("unitsTreeComps.nut")
let { animBuyRequirementsUnitId, animResearchRequirementsUnitId } = require("animState.nut")
let { unitInfoPanel, mkUnitTitle, statsWidth, scrollHandlerInfoPanel } = require("%rGui/unit/components/unitInfoPanel.nut")
let { curSelectedUnit, sizePlatoon, curUnitName,availableUnitsList } = require("%rGui/unit/unitsWndState.nut")
let { unitActions, discountBlock } = require("%rGui/unit/unitsWndActions.nut")
let { clearFilters } = require("%rGui/unit/unitsFilterState.nut")
let { unseenUnits } = require("%rGui/unit/unseenUnits.nut")
let { unseenSkins } = require("%rGui/unitSkins/unseenSkins.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { openExpWnd, canPurchaseLevelUp } = require("%rGui/mainMenu/expWndState.nut")
let { levelBorder } = require("%rGui/components/levelBlockPkg.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { lvlUpCost, openLvlUpWndIfCan, isLvlUpAnimated } = require("%rGui/levelUp/levelUpState.nut")
let { isFiltersVisible, filterStateFlags, openFilters, activeFilters, mkFilteredUnits
} = require("%rGui/unit/unitsFilterPkg.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { mkUnitsTreeNodesContent, mkHasDarkScreen } = require("unitsTreeNodesContent.nut")
let { rankBlockOffset } = require("unitsTreeConsts.nut")
let { mkUnitPlate, framesGapMul } = require("mkUnitPlate.nut")
let { scrollHandler, startAnimScroll, interruptAnimScroll, scrollPos, unseenArrowsBlockCtor
} = require("unitsTreeScroll.nut")
let { curCampaign, isCampaignWithSlots } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { slotBarTreeHeight } = require("%rGui/slotBar/slotBarConsts.nut")
let { selectedSlotIdx } = require("%rGui/slotBar/slotBarState.nut")
let { researchBlock, mkBlueprintBarText } = require("%rGui/unitsTree/components/researchBars.nut")
let panelBg = require("%rGui/components/panelBg.nut")
let { unseenUnitLvlRewardsList } = require("%rGui/levelUp/unitLevelUpState.nut")

let infoPannelPadding = hdpx(30)
let infoPanelFooterGap = hdpx(20)
let filterIconSize = hdpxi(36)
let clearIconSize = hdpxi(45)
let maxInfoPanelHeight = saSize[1] - hdpx(427)

let isTreeAttached = Watched(false)
let isTreeNodes = Computed(@() curCampaign.get() in serverConfigs.get()?.unitTreeNodes)
let hasSelectedUnit = Computed(@() curSelectedUnit.get() != null)

let openFiltersPopup = @(e) openFilters(e, isTreeNodes.get(), {
  popupOffset = levelMarkSize + hdpx(10)
  popupValign = ALIGN_TOP
  popupHalign = ALIGN_CENTER
})

function getTreeScrollPosX(columnsCfgV, name) {
  let { rank = 0 } = campUnitsCfg.get()?[name]
  if (rank <= 0)
    return null
  let scrollPosX = blockSize[0] * ((columnsCfgV?[rank] ?? 0) + 1) - (0.4 * (saSize[0] - flagsWidth))
  return (abs(scrollPosX - (scrollHandler.elem?.getScrollOffsX() ?? 0)) > saSize[0] * 0.1) ? scrollPosX : null
}

function scrollToUnit(columnsCfgV, name) {
  interruptAnimScroll()
  let scrollPosX = getTreeScrollPosX(columnsCfgV, name)
  if (scrollPosX == null)
    return
  scrollHandler.scrollToX(scrollPosX)
}

function animScrollToUnit(columnsCfgV, name) {
  let scrollPosX = getTreeScrollPosX(columnsCfgV, name)
  if (scrollPosX != null)
    startAnimScroll([scrollPosX, scrollHandler.elem?.getScrollOffsY() ?? 0])
}

function scrollToRank(columnsCfgV, rank) {
  interruptAnimScroll()
  let scrollPosX = blockSize[0] * ((columnsCfgV?[rank] ?? 0) + 1) - 0.5 * (saSize[0] - flagsWidth)
  scrollHandler.scrollToX(scrollPosX)
}

function mkNeedArrows(columnsCfg) {
  let unseenUnitsIndex = Computed(function() {
    let res = {}
    if (!isUnitsTreeOpen.get() || (unseenUnits.get().len() == 0 && unseenSkins.get().len() == 0))
      return res
    foreach(unit in availableUnitsList.get()) {
      if ((unit.name in unseenUnitLvlRewardsList.get() || unit.name in unseenUnits.get() || unit.name in unseenSkins.get())
        && unit.rank in columnsCfg.get())
          res[unit.name] <- columnsCfg.get()[unit.rank]
    }
    return res
  })
  return {
    needShowArrowL = Computed(function() {
      let offsetIdx = (scrollPos.get() - flagTreeOffset).tofloat() / blockSize[0] - 1
      return null != unseenUnitsIndex.get().findvalue(@(index) offsetIdx > index)
    })
    needShowArrowR = Computed(function() {
      let offsetIdx = (scrollPos.get() + sw(100) - 2 * saBorders[0] - flagsWidth - flagTreeOffset).tofloat()
        / blockSize[0] - 1
      return null != unseenUnitsIndex.get().findvalue(@(index) offsetIdx < index)
    })
  }
}

function tryAnimUnitInfoActionHint(unitId) {
  if (!unitId)
    return
  scrollHandlerInfoPanel.scrollToY(scrollHandlerInfoPanel.elem?.getWidth() ?? 1000000)
  anim_start("unitInfoActionHint")
}
animBuyRequirementsUnitId.subscribe(tryAnimUnitInfoActionHint)
animResearchRequirementsUnitId.subscribe(tryAnimUnitInfoActionHint)

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
        children = { hotkeys = [[
          "^J:LT",
          loc("filter"),
          @(e) openFiltersPopup(e)
        ]] }
      }
  : {
      padding = [hdpx(10), hdpx(25)]
      behavior = Behaviors.Button
      onElemState = @(s) filterStateFlags(s)
      onClick = @(e) openFiltersPopup(e)
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

let mkUnitsBlock = @(columnsCfgV, listByCountry, rowIdx) function() {
  let children = []
  foreach (rank, units in listByCountry)
    foreach (slot, unit in units)
      children.append(mkUnitPlate(unit, XmbNode(),
        {
          pos = [
            blockSize[0] * (columnsCfgV[rank] + slot)
              + platoonPlatesGap * framesGapMul * sizePlatoon.get()
              + platesGap[0] * 0.5,
            blockSize[1] * rowIdx
              + platoonPlatesGap * framesGapMul * sizePlatoon.get() * 0.5
              + platesGap[1] * 0.5
              + levelMarkSize
          ]
        }))

  return {
    watch = sizePlatoon
    valign = ALIGN_CENTER
    children
  }
}

let mkLevelProgress = @(columnsCfgV, idx) function() {
  let slots = (columnsCfgV?[idx + 2] ?? 0) - (columnsCfgV?[idx + 1] ?? 0)
  if (slots <= 0) {
    let pos = columnsCfgV?[idx + 1] ?? -1
    let prevPos = columnsCfgV?[idx] ?? -1
    if (pos >= columnsCfgV.total || pos < 0 || pos == prevPos)
      return null

    let { level } = playerLevelInfo.get()
    return {
      watch = [playerLevelInfo, unitsMaxRank, unitsMaxStarRank]
      pos = [blockSize[0] * (pos + 0.5) - levelMarkSize * 0.5, 0]
      children = levelMark(
          idx + 1,
          max(0, idx + 1 - unitsMaxRank.get() + unitsMaxStarRank.get()),
          level >= idx + 1)
    }
  }

  let { level, exp, nextLevelExp } = playerLevelInfo.value

  local rGap = (columnsCfgV?[idx + 3] ?? 0) == columnsCfgV[idx + 2] ? RGAP_HAS_GAP : 0
  if (rGap == RGAP_HAS_GAP) {
    if (columnsCfgV?[idx + 3] != columnsCfgV.total)
      rGap = rGap | RGAP_HAS_NEXT_LEVEL
    if (level >=
        (columnsCfgV.findindex(@(v, key) type(key) == "integer" && v > columnsCfgV[idx + 1] && columnsCfgV?[key + 1] != v) ?? 0))
      rGap = rGap | RGAP_RECEIVED_NEXT_LEVEL
  }

  let barWidth = slots * blockSize[0] - levelMarkSize + progressBarHeight + levelBorder
  let levelCompleted = level >= idx + 2
  let current = levelCompleted ? 1
    : level == idx + 1 ? exp
    : 0
  let required = levelCompleted ? 1 : nextLevelExp
  let levelCompletion = current >= required || required == 0 ? 1.0
    : clamp(current.tofloat() / required * 0.97, 0.0, 0.97)

  return {
    watch = [playerLevelInfo, sizePlatoon, unitsMaxRank, unitsMaxStarRank]
    pos = [blockSize[0] * (columnsCfgV[idx + 1] + 0.5) - levelMarkSize * 0.5, 0]
    children = [
      {
        size = [SIZE_TO_CONTENT, levelMarkSize]
        valign = ALIGN_CENTER
        children = unitsMaxRank.value == idx + 1 ? null
          : mkTreeRankProgressBar(levelCompletion, barWidth, slots, rGap,
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

function unitsTree(unitsByGroup, columnsCfg) {
  function onChangeSelectedUnit(unitName) {
    if (!unitName)
      return
    scrollHandlerInfoPanel.scrollToY(0)
    animScrollToUnit(columnsCfg.get(), unitName)
  }

  return @() {
    watch = [unitsByGroup, columnsCfg, unitsMaxRank, hasSelectedUnit]
    key = unitsByGroup
    size = [
      columnsCfg.get().total * blockSize[0] + (!hasSelectedUnit.get() ? 0 : (statsWidth + platesGap[0])),
      countriesRows * blockSize[1]
    ]
    function onAttach() {
      isTreeAttached.set(true)
      curSelectedUnit.subscribe(onChangeSelectedUnit)
      defer(@() unitsTreeOpenRank.get() != null
        ? scrollToRank(columnsCfg.get(), unitsTreeOpenRank.get())
        : scrollToUnit(columnsCfg.get(), curSelectedUnit.value ?? curUnitName.value))
    }
    function onDetach() {
      isTreeAttached.set(false)
      curSelectedUnit.unsubscribe(onChangeSelectedUnit)
    }
    children = [unselectBtn.__merge({ size = flex(), pos = [0, levelMarkSize]})]
      .extend(
        array(unitsMaxRank.get() + 1).map(@(_, idx) mkLevelProgress(columnsCfg.get(), idx)),
        unitsByGroup.get().len() == 0 ? [noUnitsMsg]
          : unitsByGroup.get()
              .map(@(list, group) { group, list })
              .values()
              .sort(@(a, b) a.group <=> b.group)
              .map(@(v, rowIdx) mkUnitsBlock(columnsCfg.get(), v.list, rowIdx)))
  }
}

let pannableArea = horizontalPannableAreaCtor(sw(100) - flagsWidth - saBorders[0], [flagTreeOffset, saBorders[0]])

function mkUnitsTreeContent() {
  let allUnits = mkAllTreeUnits()
  let visibleUnits = mkFilteredUnits(allUnits)
  let visibleCountries = Computed(@() visibleUnits.get().reduce(@(res, unit) res.$rawset(unit.country, true), {}))
  let unitsByGroup = Computed(@() mapUnitsByCountryGroup(visibleUnits.get()))
  let columnsCfg = Computed(@() getColumnsCfg(unitsByGroup.get(), unitsMaxRank.get()))
  let { needShowArrowL, needShowArrowR } = mkNeedArrows(columnsCfg)
  return {
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
        size = [sw(100) - flagsWidth - 2 * saBorders[0] - flagTreeOffset, blockSize[1] * countriesRows + levelMarkSize]
        children = [
          pannableArea(
            unitsTree(unitsByGroup, columnsCfg),
            {},
            {
              behavior = [Behaviors.Pannable, Behaviors.ScrollEvent],
              touchMarginPriority = TOUCH_BACKGROUND
              scrollHandler
              xmbNode = XmbContainer()
            })
          @() unseenArrowsBlockCtor(needShowArrowL, needShowArrowR)
        ]
      }
      @() {
        watch = visibleCountries
        pos = [saBorders[0], levelMarkSize]
        flow = FLOW_VERTICAL
        children = countriesCfg
          .map(function(list) {
            let vis = list.filter(@(country) visibleCountries.get()?[country] ?? false)
            return vis.len() == 0 ? null : mkFlags(vis)
          })
          .filter(@(c) c != null)
      }
    ]
  }
}

let unitsTreeGamercard = {
  size = [flex(), backButtonHeight]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    backButton(onBackButtonClick)

    @() {
      watch = isTreeNodes
      rendObj = ROBJ_TEXT
      text = loc(isTreeNodes.get() ? "unitsTree/researches" : "unitsTree/campaignLevel")
    }.__update(isWidescreen ? fontMedium : fontSmall)

    @() {
      watch = [playerLevelInfo, lvlUpCost, isLvlUpAnimated, isTreeNodes, levelInProgress, releasedUnits, buyUnitsData]
      children = isTreeNodes.get() ? null
        : levelInProgress.get() ? spinner
        : playerLevelInfo.get().isReadyForLevelUp
          ? levelUpBtn(isLvlUpAnimated.get() ? null : openLvlUpWndIfCan)
        : canPurchaseLevelUp(playerLevelInfo.get(), buyUnitsData.get(), releasedUnits.get())
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

    mkCurrenciesBtns([WP, GOLD]).__update({ pos = [0, hdpx(5)] })
  ]
}

let infoPanelHeight = saSize[1] - gamercardHeight + gamercardOverlap + saBorders[1] - rankBlockOffset

function mkHasUnitActions(withTreeNodes) {
  if (!withTreeNodes)
    return Computed(@() curSelectedUnit.get() != null || selectedSlotIdx.get() == null)
  let hasDarkScreen = mkHasDarkScreen()
  return Computed(@() curSelectedUnit.get() != null || selectedSlotIdx.get() == null || hasDarkScreen.get())
}

let mkBottomInfoPanel = {
  rendObj = ROBJ_BOX
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    discountBlock
    unitActions
  ]
}

function infoPanel() {
  let hasUnitActions = mkHasUnitActions(isTreeNodes.get())
  let needShowBlueprintDescr = Computed(@() hangarUnit.get()?.name in serverConfigs.get()?.allBlueprints
    && hangarUnit.get()?.name not in campMyUnits.get())
  let hasDarkScreen = mkHasDarkScreen()
  return {
    watch = [hasSelectedUnit, isTreeNodes, isCampaignWithSlots, hasDarkScreen]
    key = {}
    size = flex()
    children = hasSelectedUnit.get()
        ? panelBg.__merge({
            size = [infoPanelWidth, infoPanelHeight]
            padding = [infoPannelPadding, saBorders[0], saBorders[1], infoPannelPadding]
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            valign = ALIGN_BOTTOM
            flow = FLOW_VERTICAL
            children = [
              unitInfoPanel(
                {
                  size = [flex(), SIZE_TO_CONTENT]
                  maxHeight = maxInfoPanelHeight
                  halign = ALIGN_RIGHT
                  hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
                  animations = wndSwitchAnim
                },
                mkUnitTitle, hangarUnit, {})
              {
                size = flex()
              }
              @() {
                watch = hangarUnit
                flow = FLOW_VERTICAL
                gap = infoPanelFooterGap
                hplace = ALIGN_RIGHT
                halign = ALIGN_RIGHT
                children = [
                  !needShowBlueprintDescr.get() ? null
                    : mkBlueprintBarText(loc("blueprints/fullDescription"))
                  researchBlock(hangarUnit.get())
                  @() {
                    watch = hasUnitActions
                    children = hasUnitActions.get() ? mkBottomInfoPanel : null
                  }
                ]
              }
            ]
          })
      : !isCampaignWithSlots.get() || hasDarkScreen.get() ? null
      : @() {
          watch = selectedSlotIdx
          rendObj = ROBJ_SOLID
          size = [infoPanelWidth, slotBarTreeHeight + saBorders[1]]
          padding = [0, saBorders[0]]
          color = 0x40000000
          hplace = ALIGN_RIGHT
          vplace = ALIGN_BOTTOM
          children = selectedSlotIdx.get() == null ? null
            : {
                hplace = ALIGN_RIGHT
                halign = ALIGN_RIGHT
                valign = ALIGN_CENTER
                size = [statsWidth, slotBarTreeHeight]
                rendObj = ROBJ_TEXTAREA
                behavior = Behaviors.TextArea
                text = loc("unitsTree/selectUnitHint")
              }.__update(fontMedium)
        }
  }
}

let unitsTreeWnd = {
  key = {}
  size = [sw(100), sh(100)]
  children = [
    mkTreeBg(isUnitsTreeOpen)

    @() {
      watch = isTreeNodes
      children = isTreeNodes.get() ? mkUnitsTreeNodesContent() : mkUnitsTreeContent()
    }

    {
      size = [sw(100), SIZE_TO_CONTENT]
      padding = [saBorders[1], saBorders[0], 0, saBorders[0]]
      children = unitsTreeGamercard
    }

    infoPanel
  ]
  function onAttach() {
    isUnitsTreeAttached.set(true)
  }
  function onDetach() {
    isUnitsTreeAttached.set(false)
    unitsTreeOpenRank.set(null)
  }
  animations = wndSwitchAnim
}

registerScene("unitsTreeWnd", unitsTreeWnd, closeUnitsTreeWnd, isUnitsTreeOpen)
