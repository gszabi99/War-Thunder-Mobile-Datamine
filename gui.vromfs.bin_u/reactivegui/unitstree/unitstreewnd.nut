from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { isUnitsTreeOpen, closeUnitsTreeWnd, unitsMapped, countriesCfg, countriesRows, columnsCfg,
  unitsMaxRank, unitsMaxStarRank, unitsTreeBg, unitsTreeOpenRank, isUnitsTreeAttached
} = require("%rGui/unitsTree/unitsTreeState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { gamercardHeight, mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { platoonPlatesGap } = require("%rGui/unit/components/unitPlateComp.nut")
let { mkFlags, flagsWidth, levelMarkSize, levelMark, speedUpBtn, levelUpBtn, mkProgressBar,
  progressBarHeight, bgLight, noUnitsMsg, btnSize, platesGap,
  blockSize, flagTreeOffset, gamercardOverlap
} = require("unitsTreeComps.nut")
let { unitInfoPanel, mkUnitTitle, statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { curSelectedUnit, sizePlatoon, curUnitName } = require("%rGui/unit/unitsWndState.nut")
let { unitActions } = require("%rGui/unit/unitsWndActions.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { openExpWnd } = require("%rGui/mainMenu/expWndState.nut")
let { levelBorder } = require("%rGui/components/levelBlockPkg.nut")
let { defer } = require("dagor.workcycle")
let { lvlUpCost, openLvlUpWndIfCan, isLvlUpAnimated } = require("%rGui/levelUp/levelUpState.nut")
let { isFiltersVisible, filterStateFlags, openFilters, filters, activeFilters
} = require("%rGui/unit/unitsFilterPkg.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { clearFilters } = require("%rGui/unit/unitsFilterState.nut")
let unitsTreeNodesContent = require("unitsTreeNodesContent.nut")
let { mkUnitPlate, framesGapMul } = require("mkUnitPlate.nut")
let { unseenArrowsBlock, scrollToUnit, scrollToRank, scrollHandler
} = require("unitsTreeScroll.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { simpleVerGrad } = require("%rGui/style/gradients.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")


let infoPanelPadding = hdpx(45)
let filterIconSize = hdpxi(36)
let clearIconSize = hdpxi(45)
let infoPanelBgColor = 0xE0000000
let infoPanelNodesBgColor = 0xA0000000

let openFiltersPopup = @(e, isTreeNodes = false) openFilters(e, isTreeNodes, {
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
        children = { hotkeys = [[
          "^J:LT",
          loc("filter"),
          @(e) openFiltersPopup(e, curCampaign.get() in serverConfigs.get()?.unitTreeNodes)
        ]] }
      }
  : {
      padding = [hdpx(10), hdpx(25)]
      behavior = Behaviors.Button
      onElemState = @(s) filterStateFlags(s)
      onClick = @(e) openFiltersPopup(e, curCampaign.get() in serverConfigs.get()?.unitTreeNodes)
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

    mkCurrenciesBtns([WP, GOLD], null, { pos = [0, hdpx(5)] })
  ]
}

let infoPanel = @() {
  watch = [curSelectedUnit, curCampaign, serverConfigs]
  key = {}
  size = flex()
  padding = saBordersRv
  children = !curSelectedUnit.value ? null : [
    curCampaign.get() in serverConfigs.get()?.unitTreeNodes
        ? unitInfoPanel({
            size = [SIZE_TO_CONTENT, saSize[1] + saBorders[1] - gamercardHeight + gamercardOverlap]
            rendObj = ROBJ_SOLID
            pos = [saBorders[0], gamercardHeight - gamercardOverlap]
            hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
            color = infoPanelNodesBgColor
            padding = [infoPanelPadding, saBorders[0] + infoPanelPadding]
            animations = wndSwitchAnim
          }, mkUnitTitle)
      : unitInfoPanel({
        size = [SIZE_TO_CONTENT, flex()]
        pos = [saBorders[0] + infoPanelPadding, gamercardHeight + levelMarkSize - gamercardOverlap]
        hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
        color = infoPanelBgColor
        image = simpleVerGrad
        padding = [infoPanelPadding, infoPanelPadding + saBorders[0], infoPanelPadding, infoPanelPadding]
        animations = wndSwitchAnim
        halign = ALIGN_CENTER
      }, mkUnitTitle, hangarUnit, {size = flex()})
    unitActions
  ]
}

let unitsTreeWnd = {
  key = {}
  size = [sw(100), sh(100)]
  children = [
    mkTreeBg(isUnitsTreeOpen)

    @() {
      watch = [curCampaign, serverConfigs]
      children = curCampaign.get() in serverConfigs.get()?.unitTreeNodes ? unitsTreeNodesContent() : unitsTreeContent
    }

    {
      size = [sw(100), SIZE_TO_CONTENT]
      padding = [saBorders[1], saBorders[0], 0, saBorders[0]]
      children = unitsTreeGamercard
    }

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
