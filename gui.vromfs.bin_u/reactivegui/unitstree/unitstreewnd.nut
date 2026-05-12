from "%globalsDarg/darg_library.nut" import *
let { canBuyUnitsStatus, US_CAN_BUY } = require("%appGlobals/unitsState.nut")
let { registerScene } = require("%rGui/navState.nut")
let { isUnitsTreeOpen, closeUnitsTreeWnd, unitsTreeBg, unitsTreeOpenRank, isUnitsTreeAttached
} = require("%rGui/unitsTree/unitsTreeState.nut")
let { mkNodesReceiveInfo } = require("%rGui/unitsTree/unitNodesReceiveInfo.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton, backButtonHeight } = require("%rGui/components/backButton.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { btnSize, gamercardOverlap, infoPanelWidth
} = require("%rGui/unitsTree/unitsTreeComps.nut")
let { animBuyRequirementsUnitId, animResearchRequirementsUnitId } = require("%rGui/unitsTree/animState.nut")
let { unitInfoPanel, mkUnitTitle, statsWidth, scrollHandlerInfoPanel } = require("%rGui/unit/components/unitInfoPanel.nut")
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")
let { unitActions, discountBlock } = require("%rGui/unit/unitsWndActions.nut")
let { mkFilters, resetFilters } = require("%rGui/unit/unitsFilterState.nut")
let { isFiltersVisible, filterStateFlags, openFilters } = require("%rGui/unit/unitsFilterPkg.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { mkUnitsTreeNodesContent, mkHasDarkScreen } = require("%rGui/unitsTree/unitsTreeNodesContent.nut")
let { unitsResearchStatus, visibleNodes } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { rankBlockOffset } = require("%rGui/unitsTree/unitsTreeConsts.nut")
let { isCampaignWithSlots } = require("%appGlobals/pServer/slots.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { slotBarTreeHeight } = require("%rGui/slotBar/slotBarConsts.nut")
let { selectedTreeSlotIdx } = require("%rGui/slotBar/slotBarState.nut")
let { researchBlock, mkBarText } = require("%rGui/unitsTree/components/researchBars.nut")
let panelBg = require("%rGui/components/panelBg.nut")
let { unitsBlockedByBattleMode } = require("%rGui/unit/unitAccess.nut")


let TREE_FILTERS = "tree"
let infoPannelPadding = hdpx(30)
let infoPanelFooterGap = hdpx(20)
let filterIconSize = hdpxi(36)
let clearIconSize = hdpxi(45)
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
    size = [clearIconSize, clearIconSize]
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"ui/gameuiskin#btn_trash.svg:{clearIconSize}:{clearIconSize}:P")
  }
}

let mkTreeBg = @(isVisible) @() !isVisible.get() ? { watch = isVisible } : {
  watch = [unitsTreeBg, isVisible]
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/images/{unitsTreeBg.get()}:0:P")
}.__merge(unselectBtn)

let unitsTreeGamercard = @(filters, activeFilters, allUnits) {
  size = [flex(), backButtonHeight]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    backButton(onBackButtonClick)

    {
      rendObj = ROBJ_TEXT
      text = loc("unitsTree/researches")
    }.__update(isWidescreen ? fontMedium : fontSmall)

    unitFilterButton(filters, allUnits)

    @() {
      watch = [activeFilters, isFiltersVisible]
      children = activeFilters.get() > 0 && !isFiltersVisible.get() ? clearFiltersButton : null
    }

    { size = flex() }

    mkCurrenciesBtns([WP, GOLD]).__update({ pos = [0, hdpx(5)] })
  ]
}

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
    size = flex()
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
                size = flex()
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

let unitsTreeWndKey = {}
function unitsTreeWnd() {
  let nodesReceiveInfo = mkNodesReceiveInfo()
  let { filters, activeFilters, filteredNodes, allUnits
  } = mkFilters(TREE_FILTERS, Computed(@() visibleNodes.get().__merge(nodesReceiveInfo.get())))
  return {
    key = unitsTreeWndKey
    size = const [sw(100), sh(100)]
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
    function onAttach() {
      isUnitsTreeAttached.set(true)
    }
    function onDetach() {
      isUnitsTreeAttached.set(false)
      unitsTreeOpenRank.set(null)
    }
    animations = wndSwitchAnim
  }
}

registerScene("unitsTreeWnd", unitsTreeWnd, closeUnitsTreeWnd, isUnitsTreeOpen)
