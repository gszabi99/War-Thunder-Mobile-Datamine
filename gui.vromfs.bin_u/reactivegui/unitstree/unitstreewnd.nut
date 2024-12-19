from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { abs } = require("math")
let { registerScene } = require("%rGui/navState.nut")
let { isUnitsTreeOpen, closeUnitsTreeWnd, unitsMapped, countriesCfg, countriesRows, columnsCfg,
  unitsMaxRank, unitsMaxStarRank, unitsTreeBg, unitsTreeOpenRank, isUnitsTreeAttached
} = require("%rGui/unitsTree/unitsTreeState.nut")
let { levelInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton, backButtonHeight } = require("%rGui/components/backButton.nut")
let { gamercardHeight, mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { playerLevelInfo, myUnits, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { platoonPlatesGap } = require("%rGui/unit/components/unitPlateComp.nut")
let { mkFlags, flagsWidth, levelMarkSize, levelMark, speedUpBtn, levelUpBtn, mkProgressBar,
  progressBarHeight, bgLight, noUnitsMsg, btnSize, platesGap,
  blockSize, flagTreeOffset, gamercardOverlap, infoPanelWidth
} = require("unitsTreeComps.nut")
let { animBuyRequirementsUnitId, animResearchRequirementsUnitId } = require("animState.nut")
let { unitInfoPanel, mkUnitTitle, statsWidth, scrollHandlerInfoPanel } = require("%rGui/unit/components/unitInfoPanel.nut")
let { curSelectedUnit, sizePlatoon, curUnitName } = require("%rGui/unit/unitsWndState.nut")
let { unitActions, discountBlock } = require("%rGui/unit/unitsWndActions.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { openExpWnd } = require("%rGui/mainMenu/expWndState.nut")
let { levelBorder } = require("%rGui/components/levelBlockPkg.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { lvlUpCost, openLvlUpWndIfCan, isLvlUpAnimated } = require("%rGui/levelUp/levelUpState.nut")
let { isFiltersVisible, filterStateFlags, openFilters, filters, activeFilters
} = require("%rGui/unit/unitsFilterPkg.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { clearFilters } = require("%rGui/unit/unitsFilterState.nut")
let { mkUnitsTreeNodesContent, mkHasDarkScreen } = require("unitsTreeNodesContent.nut")
let { rankBlockOffset } = require("unitsTreeConsts.nut")
let { mkUnitPlate, framesGapMul } = require("mkUnitPlate.nut")
let { unseenArrowsBlock, scrollToRank, scrollHandler, startAnimScroll, interruptAnimScroll
} = require("unitsTreeScroll.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { slotBarTreeHeight } = require("%rGui/slotBar/slotBarConsts.nut")
let { selectedSlotIdx } = require("%rGui/slotBar/slotBarState.nut")
let { researchBlock, mkBlueprintBarText } = require("%rGui/unitsTree/components/researchBars.nut")
let panelBg = require("%rGui/components/panelBg.nut")

let infoPannelPadding = hdpx(30)
let infoPanelFooterGap = hdpx(20)
let filterIconSize = hdpxi(36)
let clearIconSize = hdpxi(45)

let isTreeAttached = Watched(false)
let isTreeNodes = Computed(@() curCampaign.get() in serverConfigs.get()?.unitTreeNodes)
let hasSelectedUnit = Computed(@() curSelectedUnit.get() != null)

let openFiltersPopup = @(e) openFilters(e, isTreeNodes.get(), {
  popupOffset = levelMarkSize + hdpx(10)
  popupValign = ALIGN_TOP
  popupHalign = ALIGN_CENTER
})

function getTreeScrollPosX(name) {
  let { rank = 0 } = allUnitsCfg.get()?[name]
  if (rank <= 0)
    return null
  let scrollPosX = blockSize[0] * ((columnsCfg.get()?[rank] ?? 0) + 1) - (0.4 * (saSize[0] - flagsWidth))
  return (abs(scrollPosX - (scrollHandler.elem?.getScrollOffsX() ?? 0)) > saSize[0] * 0.1) ? scrollPosX : null
}

function scrollToUnit(name) {
  interruptAnimScroll()
  let scrollPosX = getTreeScrollPosX(name)
  if (scrollPosX == null)
    return
  scrollHandler.scrollToX(scrollPosX)
}

function animScrollToUnit(name) {
  let scrollPosX = getTreeScrollPosX(name)
  if (scrollPosX != null)
    startAnimScroll([scrollPosX, scrollHandler.elem?.getScrollOffsY() ?? 0])
}

curSelectedUnit.subscribe(function(v) {
  if (!v || !isTreeAttached.get())
    return
  scrollHandlerInfoPanel.scrollToY(0)
  animScrollToUnit(v)
})

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
      children = units.map(function(u, slot) {
        let xmbNode = XmbNode()
        return mkUnitPlate(u, xmbNode, { pos = mkPos(idx, slot) })
      })
    })
  }
}

let mkLevelProgress = @(_, idx) function() {
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

  return {
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
  key = listWatches
  size = [
    columnsCfg.value["0"] * blockSize[0] + (!curSelectedUnit.get() ? 0 : (statsWidth + platesGap[0])),
    countriesRows * blockSize[1]]
  function onAttach() {
    isTreeAttached.set(true)
    defer(@() unitsTreeOpenRank.get() != null
      ? scrollToRank(unitsTreeOpenRank.get())
      : scrollToUnit(curSelectedUnit.value ?? curUnitName.value))
  }
  onDetach = @() isTreeAttached.set(false)
  children = [unselectBtn.__merge({ size = flex(), pos = [0, levelMarkSize]})]
    .extend(
      array(unitsMaxRank.value).map(mkLevelProgress),
      unitsMapped.get().units.len() == 0 ? [noUnitsMsg] : unitsMapped.get().units.values().map(mkUnitsBlock))
}

let pannableArea = horizontalPannableAreaCtor(sw(100) - flagsWidth - saBorders[0], [flagTreeOffset, saBorders[0]])

let unitsTreeContent = {
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
          unitsTree,
          {},
          {
            behavior = [Behaviors.Pannable, Behaviors.ScrollEvent],
            scrollHandler
            xmbNode = {
              canFocus = false
              scrollSpeed = 2.5
              isViewport = true
              scrollToEdge = false
              screenSpaceNav = true
            }
          })
        unseenArrowsBlock
      ]
    }
    @() {
      watch = unitsMapped
      pos = [saBorders[0], levelMarkSize]
      flow = FLOW_VERTICAL
      children = unitsMapped.get().units.keys()
        .map(@(idx) mkFlags(countriesCfg?[idx].filter(@(country) unitsMapped.get().visibleCountries?[country])))
    }
  ]
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
      watch = [playerLevelInfo, lvlUpCost, isLvlUpAnimated, isTreeNodes, levelInProgress]
      children = isTreeNodes.get() ? null
        : levelInProgress.get() ? spinner
        : playerLevelInfo.get().isReadyForLevelUp
          ? levelUpBtn(isLvlUpAnimated.get() ? null : openLvlUpWndIfCan)
        : playerLevelInfo.get()?.nextLevelExp != 0 && !playerLevelInfo.get()?.isMaxLevel
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
    && hangarUnit.get()?.name not in myUnits.get())
  return {
    watch = [hasSelectedUnit, isTreeNodes]
    key = {}
    size = flex()
    children = !hasSelectedUnit.get() && !isTreeNodes.get() ? null
      : [
          !hasSelectedUnit.get()
            ? @() {
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
            : panelBg.__merge({
                size = [infoPanelWidth, infoPanelHeight]
                padding = [infoPannelPadding, saBorders[0], saBorders[1], infoPannelPadding]
                hplace = ALIGN_RIGHT
                vplace = ALIGN_BOTTOM
                valign = ALIGN_BOTTOM
                clipChildren = isTreeNodes.get()
                flow = FLOW_VERTICAL
                children = [
                  unitInfoPanel(
                    {
                      size = [flex(), SIZE_TO_CONTENT]
                      halign = ALIGN_RIGHT
                      hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
                      animations = wndSwitchAnim
                    }, mkUnitTitle, hangarUnit)
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
        ]
  }
}

let unitsTreeWnd = {
  key = {}
  size = [sw(100), sh(100)]
  children = [
    mkTreeBg(isUnitsTreeOpen)

    @() {
      watch = isTreeNodes
      children = isTreeNodes.get() ? mkUnitsTreeNodesContent() : unitsTreeContent
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
