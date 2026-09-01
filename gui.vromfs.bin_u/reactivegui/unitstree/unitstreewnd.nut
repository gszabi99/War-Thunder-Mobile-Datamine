from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/activeControls.nut" import isGamepad
from "%appGlobals/currenciesState.nut" import WP, GOLD
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/slots.nut" import isCampaignWithSlots
from "%appGlobals/unitsState.nut" import canBuyUnitsStatus, US_CAN_BUY
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientWithRightBlock
import "%rGui/components/panelBg.nut" as panelBg
from "%rGui/mainMenu/gamercard.nut" import mkCurrenciesBtns
from "%rGui/navState.nut" import registerScene
from "%rGui/slotBar/slotBarConsts.nut" import slotBarTreeHeight
from "%rGui/slotBar/slotBarState.nut" import selectedTreeSlotIdx
from "%rGui/style/gamercardStyle.nut" import gamercardHeight
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/unit/components/unitInfoPanel.nut" import unitInfoPanel, mkUnitTitle, statsWidth, scrollHandlerInfoPanel
from "%rGui/unit/hangarUnit.nut" import hangarUnit
from "%rGui/unit/unitAccess.nut" import unitsBlockedByBattleMode
from "%rGui/unit/unitsFilterPkg.nut" import isFiltersVisible, filterStateFlags, openFilters
from "%rGui/unit/unitsFilterState.nut" import mkFilters, resetFilters
from "%rGui/unit/unitsWndActions.nut" import unitActions, discountBlock
from "%rGui/unit/unitsWndState.nut" import curSelectedUnit
from "%rGui/unitsTree/animState.nut" import animBuyRequirementsUnitId, animResearchRequirementsUnitId
from "%rGui/unitsTree/components/researchBars.nut" import researchBlock, mkBarText
from "%rGui/unitsTree/unitNodesReceiveInfo.nut" import mkNodesReceiveInfo
from "%rGui/unitsTree/unitsTreeComps.nut" import btnSize, gamercardOverlap, infoPanelWidth
from "%rGui/unitsTree/unitsTreeConsts.nut" import rankBlockOffset
from "%rGui/unitsTree/unitsTreeNodesContent.nut" import mkUnitsTreeNodesContent, mkHasDarkScreen
from "%rGui/unitsTree/unitsTreeNodesState.nut" import unitsResearchStatus, visibleNodes
from "%rGui/unitsTree/unitsTreeState.nut" import isUnitsTreeOpen, closeUnitsTreeWnd, unitsTreeBg, unitsTreeOpenRank,
  isUnitsTreeAttached, isUnitPlateLevelVisible


const TREE_FILTERS = "tree"
const infoPannelPadding = hdpx(30)
const infoPanelFooterGap = hdpx(20)
const filterIconSize = hdpxi(36)
const clearIconSize = hdpxi(45)
const checkIconSize = hdpxi(60)
let maxInfoPanelHeight = saSize[1] - hdpx(427)

let hasSelectedUnit = Computed(@() curSelectedUnit.get() != null)

isUnitsTreeOpen.subscribe(@(_) resetFilters(TREE_FILTERS))

let openFiltersPopup = @(e, filters, allUnits)
  openFilters(e, filters, @() resetFilters(TREE_FILTERS), allUnits,
    {
      popupValign = ALIGN_TOP
      popupHalign = ALIGN_CENTER
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
  onClick = @() curSelectedUnit.set(null)
}

let unitFilterButton = @(filters, allUnits) @() {
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
          @(e) openFiltersPopup(e, filters, allUnits)
        ]] }
      }
  : {
      padding = const [hdpx(10), hdpx(25)]
      behavior = Behaviors.Button
      onElemState = @(s) filterStateFlags.set(s)
      onClick = @(e) openFiltersPopup(e, filters, allUnits)
      flow = FLOW_HORIZONTAL
      gap = hdpx(20)
      children = [
        {
          size = const [filterIconSize, filterIconSize]
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

let clearFiltersButton = {
  key = {}
  size = [btnSize[1], btnSize[1]]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_BOX
  borderWidth = hdpxi(1)
  fillColor = 0x50000000
  borderColor = 0xFFFFFFFF
  behavior = Behaviors.Button
  onClick = @() resetFilters(TREE_FILTERS)
  animations = wndSwitchAnim
  children = {
    size = const [clearIconSize, clearIconSize]
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"ui/gameuiskin#btn_trash.svg:{clearIconSize}:{clearIconSize}:P")
  }
}

let mkTreeBg = @(isVisible) @() !isVisible.get() ? { watch = isVisible } : {
  watch = [unitsTreeBg, isVisible]
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/images/{unitsTreeBg.get()}:0:P")
}.__merge(unselectBtn)

function mkLevelCheckbox(text, isActive, onClick) {
  let stateFlags = Watched(0)
  return @() {
    watch = [stateFlags, isActive]
    behavior = Behaviors.Button
    onClick
    onElemState = @(s) stateFlags.set(s)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(18)
    children = [
      {
        size = hdpx(70)
        rendObj = ROBJ_BOX
        opacity = isActive.get() ? 1.0 : 0.5
        borderColor = 0xFFFFFFFF
        borderWidth = hdpxi(1)
        fillColor = isActive.get() ? 0x50000000 : 0x20000000
        children = {
          size = checkIconSize
          vplace = ALIGN_CENTER
          hplace = ALIGN_CENTER
          rendObj = ROBJ_IMAGE
          image = isActive.get() ? Picture($"ui/gameuiskin#check.svg:{checkIconSize}:{checkIconSize}") : null
          keepAspect = KEEP_ASPECT_FIT
          opacity = stateFlags.get() & S_ACTIVE ? 0.5 : 1.0
        }
      }
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        maxWidth = hdpx(140)
        halign = ALIGN_LEFT
        text
      }.__update(fontTinyAccented)
    ]
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
  }
}

let unitsTreeGamercard = @(filters, activeFilters, allUnits) headerGradientWithRightBlock(
  [
    backButton(onBackButtonClick)
    {
      rendObj = ROBJ_TEXT
      text = loc("unitsTree/researches")
    }.__update(isWidescreen ? fontMedium : fontSmall)
    unitFilterButton(filters, allUnits)
    mkLevelCheckbox(loc("unitsTree/showLevel"), isUnitPlateLevelVisible,
      @() isUnitPlateLevelVisible.set(!isUnitPlateLevelVisible.get()))
    @() {
      watch = [activeFilters, isFiltersVisible]
      children = activeFilters.get() > 0 && !isFiltersVisible.get() ? clearFiltersButton : null
    }
  ],
  mkCurrenciesBtns([WP, GOLD]))

let infoPanelHeight = saSize[1] - gamercardHeight + gamercardOverlap + saBorders[1] - rankBlockOffset

function mkHasUnitActions() {
  let hasDarkScreen = mkHasDarkScreen()
  return Computed(@() curSelectedUnit.get() != null || selectedTreeSlotIdx.get() == null || hasDarkScreen.get())
}

let mkBottomInfoPanel = @(unitW, unitReceiveInfoW) {
  size = FLEX_H
  rendObj = ROBJ_BOX
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    discountBlock(unitW)
    unitActions(unitW, unitReceiveInfoW)
  ]
}

let infoPanel = @(nodesReceiveInfo) function() {
  let hasUnitActions = mkHasUnitActions()
  let isBlockedUnit = Computed(function() {
    let { name = "" } = hangarUnit.get()
    return name not in campMyUnits.get()
      && name in unitsBlockedByBattleMode.get()
      && (unitsResearchStatus.get()?[name].hasAccessLock ?? true)
      && (name not in serverConfigs.get()?.allBlueprints || canBuyUnitsStatus.get()?[name] != US_CAN_BUY)
  })
  let needShowBlueprintDescr = Computed(@() hangarUnit.get()?.name in serverConfigs.get()?.allBlueprints
    && hangarUnit.get()?.name not in campMyUnits.get()
    && !isBlockedUnit.get())
  let hasDarkScreen = mkHasDarkScreen()
  let unitReceiveInfo = Computed(@() nodesReceiveInfo.get()?[curSelectedUnit.get()])
  return {
    watch = [hasSelectedUnit, isCampaignWithSlots, hasDarkScreen, isBlockedUnit]
    key = {}
    size = FLEX
    children = hasSelectedUnit.get()
        ? panelBg.__merge({
            size = [infoPanelWidth, infoPanelHeight]
            padding = [infoPannelPadding, saBorders[0], saBorders[1], infoPannelPadding * 2]
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            valign = ALIGN_BOTTOM
            flow = FLOW_VERTICAL
            children = [
              unitInfoPanel(
                {
                  maxHeight = maxInfoPanelHeight
                  halign = ALIGN_RIGHT
                  hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
                  animations = wndSwitchAnim
                },
                mkUnitTitle, hangarUnit, {})
              {
                size = FLEX
              }
              @() {
                watch = [hangarUnit, unitReceiveInfo]
                flow = FLOW_VERTICAL
                gap = infoPanelFooterGap
                children = [
                  needShowBlueprintDescr.get() ? mkBarText(loc("blueprints/fullDescription")) : null
                  isBlockedUnit.get() && unitReceiveInfo.get() == null ? mkBarText(loc("unitsTree/needAccessHint")) : null
                  researchBlock(hangarUnit.get(), unitReceiveInfo.get())
                  @() {
                    watch = hasUnitActions
                    size = FLEX_H
                    stopMouse = true
                    children = !hasUnitActions.get() ? null
                      : mkBottomInfoPanel(curSelectedUnit, unitReceiveInfo)
                  }
                ]
              }
            ]
          })
      : !isCampaignWithSlots.get() || hasDarkScreen.get() ? null
      : @() {
          watch = selectedTreeSlotIdx
          rendObj = ROBJ_SOLID
          size = [infoPanelWidth, slotBarTreeHeight + saBorders[1]]
          padding = [0, saBorders[0]]
          color = 0x40000000
          hplace = ALIGN_RIGHT
          vplace = ALIGN_BOTTOM
          children = selectedTreeSlotIdx.get() == null ? null
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

function unitsTreeWnd() {
  let nodesReceiveInfo = mkNodesReceiveInfo()
  let { filters, activeFilters, filteredNodes, allUnits, onFiltersDestroy
  } = mkFilters(TREE_FILTERS, Computed(@() visibleNodes.get().__merge(nodesReceiveInfo.get())))
  return {
    key = onFiltersDestroy
    size = const [sw(100), sh(100)]
    function onAttach() {
      isUnitsTreeAttached.set(true)
    }
    function onDetach() {
      isUnitsTreeAttached.set(false)
      unitsTreeOpenRank.set(null)
      onFiltersDestroy()
    }
    children = [
      mkTreeBg(isUnitsTreeOpen)

      {
        children = mkUnitsTreeNodesContent(filteredNodes)
      }

      {
        size = const [sw(100), SIZE_TO_CONTENT]
        padding = [saBorders[1], saBorders[0], 0, saBorders[0]]
        children = unitsTreeGamercard(filters, activeFilters, allUnits)
      }

      infoPanel(nodesReceiveInfo)
    ]
    animations = wndSwitchAnim
  }
}

registerScene("unitsTreeWnd", unitsTreeWnd, closeUnitsTreeWnd, isUnitsTreeOpen)
