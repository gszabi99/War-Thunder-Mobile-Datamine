from "%globalsDarg/darg_library.nut" import *
let { deferOnce, resetTimeout, clearTimer } = require("dagor.workcycle")
let logFB = log_with_prefix("[TUTOR_UNITS_RESEARCH] ")
let { register_command } = require("console")

let { balance } = require("%appGlobals/currenciesState.nut")
let { buy_unit, add_player_exp, unitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { isCampaignWithUnitsResearch, curCampaign, campProfile } = require("%appGlobals/pServer/campaign.nut")
let { curSlots, isCampaignWithSlots, curCampaignSlotUnits } = require("%appGlobals/pServer/slots.nut")
let { campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { canBuyUnits } = require("%appGlobals/unitsState.nut")
let { isInSquad } = require("%appGlobals/squadState.nut")

let { delayedPurchaseUnitData, needSaveUnitDataForTutorial } = require("%rGui/unit/delayedPurchaseUnit.nut")
let { isUnitsTreeAttached, openUnitsTreeAtUnit, isUnitsTreeOpen } = require("%rGui/unitsTree/unitsTreeState.nut")
let { needDelayAnimation, isBuyUnitWndOpened, animExpPart,
  animUnitAfterResearch } = require("%rGui/unitsTree/animState.nut")
let { markTutorialCompleted, isFinishedUnitsResearch } = require("%rGui/tutorial/completedTutorials.nut")
let { scrollToUnitGroupBottom, calcAreaSize } = require("%rGui/unitsTree/unitsTreeNodesContent.nut")
let { visibleNodes, unitsResearchStatus, currentResearch } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { hasModalWindows, moveModalToTop } = require("%rGui/components/modalWindows.nut")
let { setTutorialConfig, isTutorialActive, finishTutorial, WND_UID, goToStep,
  activeTutorialId } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { setResearchUnit } = require("%rGui/unit/unitsWndActions.nut")
let { closePurchaseAndBalanceBoxes } = require("%rGui/shop/msgBoxPurchase.nut")
let { setUnitToSlot, canOpenSelectUnitWithModal, slotBarSelectWndAttached
  selectedUnitToSlot, closeSelectUnitToSlotWnd } = require("%rGui/slotBar/slotBarState.nut")
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")
let { triggerAnim } = require("%rGui/unitsTree/mkUnitPlate.nut")
let { TUTORIAL_UNITS_RESEARCH_ID } = require("%rGui/tutorial/tutorialConst.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { btnBEsc, btnAUp } = require("%rGui/controlsMenu/gpActBtn.nut")


let STEP_SELECT_NEXT_RESEARCH_DESCRIPTION = "s6_select_next_research_description"
let STEP_PARTING_WORDS = "s9_tutorial_parting_words_research_unit"

let isDebugMode = mkWatched(persist, "isDebugMode", false)

let lastResearchedUnit = Computed(@() servProfile.get()?.levelInfo[curCampaign.get()].lastResearchedUnit ?? "")
let hasGotFirstPredifinedReward = Computed(@()
  (campProfile.get()?.lastReceivedFirstBattlesRewardIds[curCampaign.get()] ?? -1) >= 0)
let curResearchUnitStatus = Computed(@() unitsResearchStatus.get()?[lastResearchedUnit.get()])

let canBuyCurResearchUnit = Computed(function() {
  let unitFromCanBuyUnits = canBuyUnits.get()?[lastResearchedUnit.get()]
  let canBuyUnit = unitFromCanBuyUnits != null
  let { isResearched = false, canBuy = false } = curResearchUnitStatus.get()
  return canBuyUnit || (isResearched && !canBuy)
})

let needShowTutorial = Computed(@() !isInSquad.get()
  && !isFinishedUnitsResearch.get()
  && isCampaignWithUnitsResearch.get()
  && hasGotFirstPredifinedReward.get()
  && curResearchUnitStatus.get()
  && canBuyCurResearchUnit.get()
  && currentResearch.get() == null)
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
    closeSelectUnitToSlotWnd()
    goToStep(STEP_SELECT_NEXT_RESEARCH_DESCRIPTION)
  }
  else
    clearTimer(forcedUnitPurchaseSkip)
}

function startTutorial() {
  if (lastResearchedUnit.get() != "" && curSelectedUnit.get() != lastResearchedUnit.get())
    curSelectedUnit.set(lastResearchedUnit.get())

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

  setTutorialConfig({
    id = TUTORIAL_UNITS_RESEARCH_ID
    function onStepStatus(stepId, status) {
      logFB($"{stepId}: {status}")
      if (status == "tutorial_finished")
        markTutorialCompleted(TUTORIAL_UNITS_RESEARCH_ID)
    }
    steps = [
      {
        id = "s1_welcome_to_research_menu"
        hasNextKey = true
        text = loc("tutorial_welcome_to_research_menu")
      }
      {
        id = "s2_units_wnd_animation"
        function beforeStart() {
          needSaveUnitDataForTutorial.set(true)
          needDelayAnimation.set(false)
          resetTimeout(5.0, forcedUnitPurchaseSkip)
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
          let availableResearchNodes = visibleNodes.get().filter(@(node) unitsResearchStatus.get()?[node.name].canResearch
            && !unitsResearchStatus.get()?[node.name].isResearched
            && null != node.reqUnits.findindex(@(v) v == curSelectedUnit.get()))
          availableResearchNodesObjects.extend(availableResearchNodes.keys().map(@(name) {
            keys = $"treeNodeUnitPlate:{name}"
            onClick = @() curSelectedUnit.set(name)
          }))
          curSelectedUnit.set(null)
          if (availableResearchNodes.len() == 0)
            deferOnce(@() goToStep(STEP_PARTING_WORDS))
          else {
            scrollToUnitGroupBottom(
              availableResearchNodes.keys(),
              availableResearchNodes,
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
  if (isCampaignWithUnitsResearch.get() && activeTutorialId.get() != TUTORIAL_UNITS_RESEARCH_ID) {
    let { unitsResearch = {} } = servProfile.get()
    let researchingUnitId = unitsResearch?.findindex(@(v) v?.isCurrent) ?? ""

    if (isUnitsTreeAttached.get())
      return dlog("Can't start tutorial after first battle: need to get out of the units tree")  
    if (researchingUnitId == "")
      return dlog("Can't start tutorial after first battle: need researchingUnitId")  

    let { reqExp = 0, exp = 0 } = unitsResearchStatus.get()?[researchingUnitId] ?? {}
    add_player_exp(curCampaign.get(), reqExp - exp, "consolePrintResult")
    needDelayAnimation.set(true)
    curSelectedUnit.set(researchingUnitId)
    openUnitsTreeAtUnit(researchingUnitId)
    isDebugMode.set(true)
  }
  else
    finishTutorial()
}, "debug.tutorial_after_first_ballte")
