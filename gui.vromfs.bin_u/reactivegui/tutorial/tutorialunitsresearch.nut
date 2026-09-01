from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.workcycle" import deferOnce, resetTimeout, clearTimer
from "%appGlobals/currenciesState.nut" import balance
from "%appGlobals/pServer/campaign.nut" import curCampaign, campConfigs
from "%appGlobals/pServer/pServerApi.nut" import buy_unit, add_player_exp, unitInProgress, buy_unit_research
from "%appGlobals/pServer/profile.nut" import campUnitsCfg, campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/pServer/slots.nut" import curSlots, isCampaignWithSlots, curCampaignSlotUnits
import "%appGlobals/pServer/unreleasedUnits.nut" as unreleasedUnits
from "%appGlobals/squadState.nut" import isInSquad
from "%appGlobals/unitsState.nut" import canBuyUnits
from "%rGui/components/modalWindows.nut" import hasModalWindows, moveModalToTop
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEsc, btnAUp
from "%rGui/event/eventLootboxes.nut" import eventLootboxes
import "%rGui/event/shouldShowEventMechanics.nut" as shouldShowEventMechanics
from "%rGui/gameModes/newbieOfflineMissions.nut" import curProfileRewardId, isFirstBattleRewardPart
from "%rGui/mainMenu/mainMenuState.nut" import isMainMenuAttached
from "%rGui/options/options/gameOptions.nut" import isAllowAutoOfferToBuyUnitEnabled
from "%rGui/shop/msgBoxPurchase.nut" import closePurchaseAndBalanceBoxes
from "%rGui/shop/personalGoodsState.nut" import personalGoodsByShopCategory
from "%rGui/shop/shopState.nut" import goodsByCategory
from "%rGui/slotBar/slotBarState.nut" import setUnitToSlot, canOpenSelectUnitWithModal, slotBarSelectWndAttached,
  selectedUnitToSlot, closeSelectUnitToSlotWnd
from "%rGui/tutorial/completedTutorials.nut" import markTutorialCompleted, isFinishedUnitsResearch
from "%rGui/tutorial/tutorialConst.nut" import TUTORIAL_UNITS_RESEARCH_ID
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import setTutorialConfig, isTutorialActive, finishTutorial,
  WND_UID, goToStep, activeTutorialId
from "%rGui/unit/delayedPurchaseUnit.nut" import delayedPurchaseUnitData, needSaveUnitDataForTutorial
from "%rGui/unit/unitsWndActions.nut" import setResearchUnit
from "%rGui/unit/unitsWndState.nut" import curSelectedUnit
from "%rGui/unitsTree/animState.nut" import needDelayAnimation, isBuyUnitWndOpened, animExpPart, animUnitAfterResearch
import "%rGui/unitsTree/buyUnitResearchWnd.nut" as openBuyUnitResearchWnd
from "%rGui/unitsTree/mkUnitPlate.nut" import triggerAnim
from "%rGui/unitsTree/unitNodesReceiveInfo.nut" import getNodesReceiveInfo
from "%rGui/unitsTree/unitsTreeNodesContent.nut" import scrollToUnitGroupBottom, calcAreaSize
from "%rGui/unitsTree/unitsTreeNodesState.nut" import visibleNodes, unitsResearchStatus, currentResearch,
  selectedCountry, remapNodesPositionsShiftX
from "%rGui/unitsTree/unitsTreeState.nut" import isUnitsTreeAttached, openUnitsTreeAtUnit, isUnitsTreeOpen


let logFB = log_with_prefix("[TUTOR_UNITS_RESEARCH] ")



const STEP_SELECT_NEXT_RESEARCH_DESCRIPTION = "s6_select_next_research_description"
const STEP_PARTING_WORDS = "s9_tutorial_parting_words_research_unit"

const FORCED_UNIT_PURCHASE_SKIP_DELAY_SEC = 10.0

let isDebugMode = mkWatched(persist, "isDebugMode", false)
let savedAutoOfferOption = mkWatched(persist, "savedAutoOfferOption", null)

let lastResearchedUnit = Computed(@() servProfile.get()?.levelInfo[curCampaign.get()].lastResearchedUnit ?? "")
let hasGotFirstPredifinedReward = Computed(@() curProfileRewardId.get() >= 0)
let curResearchUnitStatus = Computed(@() unitsResearchStatus.get()?[lastResearchedUnit.get()])

let canBuyCurResearchUnit = Computed(function() {
  let unitFromCanBuyUnits = canBuyUnits.get()?[lastResearchedUnit.get()]
  let canBuyUnit = unitFromCanBuyUnits != null
  let { isResearched = false, canBuy = false } = curResearchUnitStatus.get()
  return canBuyUnit || (isResearched && !canBuy)
})

let needShowTutorialByAbTest = Computed(@() isFirstBattleRewardPart.get()
  ? curProfileRewardId.get() == 0 && currentResearch.get() != null
  : curResearchUnitStatus.get()
      && canBuyCurResearchUnit.get()
      && currentResearch.get() == null)
let needShowTutorial = Computed(@() !isInSquad.get()
  && !isFinishedUnitsResearch.get()
  && hasGotFirstPredifinedReward.get()
  && needShowTutorialByAbTest.get())
let canStartTutorial = Computed(@() !hasModalWindows.get()
  && isUnitsTreeAttached.get()
  && !isTutorialActive.get())
let showTutorial = keepref(Computed(@() canStartTutorial.get()
  && (needShowTutorial.get() || isDebugMode.get())))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.get() == TUTORIAL_UNITS_RESEARCH_ID
  && !isMainMenuAttached.get()
  && !isUnitsTreeAttached.get()))
let finishEarly = @() shouldEarlyCloseTutorial.get() ? finishTutorial() : null
shouldEarlyCloseTutorial.subscribe(@(v) v ? deferOnce(finishEarly) : null)

function forcedUnitPurchaseSkip() {
  if (!isBuyUnitWndOpened.get() || animUnitAfterResearch.get() == null || !animExpPart.get()) {
    logFB($"Skipping unit purchase by timer ({!isBuyUnitWndOpened.get()} || {animUnitAfterResearch.get() == null} || {!animExpPart.get()})")
    closeSelectUnitToSlotWnd()
    goToStep(STEP_SELECT_NEXT_RESEARCH_DESCRIPTION)
  }
  else
    clearTimer(forcedUnitPurchaseSkip)
}

function startTutorial() {
  if (lastResearchedUnit.get() != "" && curSelectedUnit.get() != lastResearchedUnit.get())
    curSelectedUnit.set(lastResearchedUnit.get())

  let addSteps = []
  if (isFirstBattleRewardPart.get()) {
    if (curSelectedUnit.get() != "")
      curSelectedUnit.set(visibleNodes.get().findvalue(@(v) v.reqUnits.contains(curSelectedUnit.get()))?.name ?? "")
    addSteps.append(
      {
        id = "s1.2_open_unit_research_wnd"
        text = loc("tutorial/unitsResearch/openUnitResearch")
        objects = [{
          keys = "open_unit_research_btn"
          onClick = @() openBuyUnitResearchWnd(curSelectedUnit.get())
        }]
      },
      {
        id = "s1.3_buy_unit_research"
        text = loc("tutorial/unitsResearch/buyUnitResearch")
        objects = [{
          keys = "buy_unit_research_btn",
          function onClick() {
            let unitName = curSelectedUnit.get()
            let { exp = 0 } = unitsResearchStatus.get()?[unitName]
            let { campaign = "", rank = 0 } = serverConfigs.get()?.allUnits[unitName]
            let { nextLevelExp = 0 } = campConfigs.get()?.unitResearchLevels[campaign][rank - 1]
            buy_unit_research(unitName, curCampaign.get(), 0, nextLevelExp - exp,
              { id = "buyUnitResearch", unitName })
          }
        }]
      })
  }

  let availableResearchNodesObjects = []
  let availableSelectSlotsObjects = []
  let purchaseBtnObjects = [{
    keys = "purchase_tutor_btn"
    needArrow = true
    function onClick() {
      if (!unitInProgress.get()) {
        let { unitId = "", currencyId = "", price = "" } = delayedPurchaseUnitData.get()
        if (unitId != "" && currencyId != "" && price != "" && unitId not in servProfile.get()?.units)
          buy_unit(unitId, currencyId, price, { id = "onUnitPurchaseResult", unitId })
      }
      return true
    }
    hotkeys = [btnAUp]
  }]
  if ((curCampaignSlotUnits.get()?.len() ?? 0) > 1 || (campUnitsCfg.get()?[curSelectedUnit.get()].mRank ?? 0) > 2)
    purchaseBtnObjects.append({
      keys = "purchase_cancel_btn"
      needArrow = true
      onClick = @() deferOnce(@() goToStep(STEP_SELECT_NEXT_RESEARCH_DESCRIPTION))
      hotkeys = [btnBEsc]
    })

  let hasScrollAnimDone = Watched(false)

  needSaveUnitDataForTutorial.set(false)
  canOpenSelectUnitWithModal.set(false)
  needDelayAnimation.set(true)

  let steps = [
      {
        id = "s1_welcome_to_research_menu"
        hasNextKey = true
        text = loc("tutorial_welcome_to_research_menu")
      }
      {
        id = "s2_units_wnd_animation"
        function beforeStart() {
          if (!isAllowAutoOfferToBuyUnitEnabled.get()) {
            savedAutoOfferOption.set(isAllowAutoOfferToBuyUnitEnabled.get())
            isAllowAutoOfferToBuyUnitEnabled.set(true)
          }
          needSaveUnitDataForTutorial.set(true)
          needDelayAnimation.set(false)
          resetTimeout(FORCED_UNIT_PURCHASE_SKIP_DELAY_SEC, forcedUnitPurchaseSkip)
        }
        nextStepAfter = isBuyUnitWndOpened
        objects = [{ keys = "sceneRoot", onClick = @() true }]
      }
      {
        id = "s3_purchase_researched_unit"
        function beforeStart() {
          clearTimer(forcedUnitPurchaseSkip)
          moveModalToTop(WND_UID)
          let { currencyId = "", price = 0 } = delayedPurchaseUnitData.get()
          if ((balance.get()?[currencyId] ?? 0) < price) {
            logFB($"Skipping unit purchase, balance {balance.get()?[currencyId]} < {price} {currencyId}")
            closePurchaseAndBalanceBoxes()
            deferOnce(@() goToStep(STEP_SELECT_NEXT_RESEARCH_DESCRIPTION))
          }
        }
        text = loc("tutorial_purchase_researched_unit")
        charId = "mary_points"
        nextStepAfter = Computed(@() !isBuyUnitWndOpened.get()
          && (selectedUnitToSlot.get() != null || !isCampaignWithSlots.get()))
        objects = purchaseBtnObjects
      }
      {
        id = "s4_units_wnd_animation"
        isOnlyWithSlots = true
        nextStepAfter = slotBarSelectWndAttached
        function beforeStart() {
          needSaveUnitDataForTutorial.set(false)
          closePurchaseAndBalanceBoxes()
          triggerAnim()
          availableSelectSlotsObjects.extend(curSlots.get()
            .map(@(slot, idx) slot.name != "" ? null : {
              keys = $"select_slot_{idx}"
              onClick = @() setUnitToSlot(idx)
            })
            .filter(@(s) s != null))
          if (availableSelectSlotsObjects.len() == 0)
            deferOnce(@() goToStep(STEP_SELECT_NEXT_RESEARCH_DESCRIPTION))
          else
            canOpenSelectUnitWithModal.set(true)
        }
        objects = [{ keys = "sceneRoot", onClick = @() true }]
      }
      {
        id = "s5_set_purchased_unit_to_slot"
        isOnlyWithSlots = true
        function beforeStart() {
          if (availableSelectSlotsObjects.len() == 0 || !slotBarSelectWndAttached.get())
            deferOnce(@() goToStep(STEP_SELECT_NEXT_RESEARCH_DESCRIPTION))
          moveModalToTop(WND_UID)
        }
        text = loc("tutorial_set_purchased_unit_to_slot")
        objects = availableSelectSlotsObjects
      }
      {
        id = STEP_SELECT_NEXT_RESEARCH_DESCRIPTION
        function beforeStart() {
          canOpenSelectUnitWithModal.set(false)
          closePurchaseAndBalanceBoxes()
          let nodeReceiveInfo = getNodesReceiveInfo({
            campConfigsV = campConfigs.get(),
            campMyUnitsV = campMyUnits.get(),
            unreleasedUnitsV = unreleasedUnits.get(),
            goodsByCategoryV = goodsByCategory.get(),
            personalGoodsByShopCategoryV = personalGoodsByShopCategory.get(),
            eventLootboxesV = eventLootboxes.get(),
            shouldShowEventMechanicsV = shouldShowEventMechanics.get()
          })
          let filteredNodes = visibleNodes.get().__merge(nodeReceiveInfo)
            .filter(@(n) campUnitsCfg.get()?[n.name] != null && n.country == selectedCountry.get())
          let remapedNodes = remapNodesPositionsShiftX(filteredNodes, campConfigs.get(), true).nodes
          local nodesToHighlight = remapedNodes.filter(@(node) unitsResearchStatus.get()?[node.name].canResearch
            && !unitsResearchStatus.get()?[node.name].isResearched)

          let availableNodesByPrevReserched = nodesToHighlight
            .filter(@(node) null != node.reqUnits.findindex(@(v) v == curSelectedUnit.get()))
          if (availableNodesByPrevReserched.len() != 0)
            nodesToHighlight = availableNodesByPrevReserched 

          let availableNodesByConfig = nodesToHighlight
            .filter(@(node) serverConfigs.get()?.tutorialResearchPriorityCfg[node.name])
          if (availableNodesByConfig.len() != 0)
            nodesToHighlight = availableNodesByConfig

          availableResearchNodesObjects.extend(nodesToHighlight.keys().map(@(name) {
            keys = $"treeNodeUnitPlate:{name}"
            onClick = @() curSelectedUnit.set(name)
          }))
          curSelectedUnit.set(null)
          if (nodesToHighlight.len() == 0)
            deferOnce(@() goToStep(STEP_PARTING_WORDS))
          else {
            scrollToUnitGroupBottom(
              nodesToHighlight.keys(),
              nodesToHighlight,
              Computed(@() calcAreaSize(isCampaignWithSlots.get())),
              true)
            resetTimeout(0.5, @() hasScrollAnimDone.set(true))
          }
        }
        text = loc("tutorial_select_next_research_description")
        nextStepAfter = hasScrollAnimDone
        objects = [{ keys = "sceneRoot", onClick = @() true }]
      }
      {
        id = "s7_select_next_research_unit"
        function beforeStart() {
          if (availableResearchNodesObjects.len() == 0)
            deferOnce(@() goToStep(STEP_PARTING_WORDS))
        }
        text = loc("tutorial_select_next_research_unit")
        objects = availableResearchNodesObjects
      }
      {
        id = "s8_confirm_research_unit"
        function beforeStart() {
          if (curSelectedUnit.get() == null || currentResearch.get() != null)
            deferOnce(@() goToStep(STEP_PARTING_WORDS))
          moveModalToTop(WND_UID)
        }
        text = loc("tutorial_confirm_research_unit")
        objects = [{
          keys = "startResearchButton"
          needArrow = true
          onClick = @() setResearchUnit(curSelectedUnit.get())
          hotkeys = ["^J:X"]
        }]
      }
      {
        id = STEP_PARTING_WORDS
        hasNextKey = true
        charId = "mary_like"
        text = loc("tutorial_parting_words_research_unit")
      }
      {
        id = "s10_units_wnd_press_back"
        text = loc("tutorial/pressBackToReturnToMainScreen")
        objects = [{
          keys = "backButton"
          sizeIncAdd = hdpx(20)
          needArrow = true
          onClick = @() isUnitsTreeOpen.set(false)
          hotkeys = [btnBEsc]
        }]
      }
      {
        id = "s11_finish_research_unit_tutorial"
        hasNextKey = true
        charId = "mary_like"
        text = loc("tutorial_finish_research_unit")
      }
    ].filter(@(v) !v?.isOnlyWithSlots || isCampaignWithSlots.get())

  foreach (idx, _ in addSteps)
    steps.insert(1, addSteps[addSteps.len() - 1 - idx])

  setTutorialConfig({
    id = TUTORIAL_UNITS_RESEARCH_ID
    function onStepStatus(stepId, status) {
      logFB($"{stepId}: {status}")
      if (status == "tutorial_finished") {
        markTutorialCompleted(TUTORIAL_UNITS_RESEARCH_ID)
        if (savedAutoOfferOption.get() != null) {
          isAllowAutoOfferToBuyUnitEnabled.set(savedAutoOfferOption.get())
          savedAutoOfferOption.set(null)
        }
      }
    }
    steps
  })
}

let startTutorialDelayed = @() deferOnce(function() {
  if (!showTutorial.get())
    return
  startTutorial()
  isDebugMode.set(false)
})

startTutorialDelayed()
showTutorial.subscribe(@(v) v ? startTutorialDelayed() : null)

register_command(function() {
  if (activeTutorialId.get() != TUTORIAL_UNITS_RESEARCH_ID) {
    let { unitsResearch = {} } = servProfile.get()
    let researchingUnitId = unitsResearch?.findindex(@(v) v?.isCurrent) ?? ""

    if (isUnitsTreeAttached.get())
      return dlog("Can't start tutorial after first battle: need to get out of the units tree")  
    if (researchingUnitId == "")
      return dlog("Can't start tutorial after first battle: need researchingUnitId")  

    if (!isFirstBattleRewardPart.get()) {
      let { reqExp = 0, exp = 0 } = unitsResearchStatus.get()?[researchingUnitId] ?? {}
      add_player_exp(curCampaign.get(), reqExp - exp, "consolePrintResult")
    }
    needDelayAnimation.set(true)
    curSelectedUnit.set(researchingUnitId)
    openUnitsTreeAtUnit(researchingUnitId)
    isDebugMode.set(true)
  }
  else
    finishTutorial()
}, "debug.tutorial_units_research")
