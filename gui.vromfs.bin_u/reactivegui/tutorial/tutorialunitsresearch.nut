from "%globalsDarg/darg_library.nut" import *
let { deferOnce, resetTimeout, clearTimer } = require("dagor.workcycle")
let logFB = log_with_prefix("[TUTOR_UNITS_RESEARCH] ")
let { register_command } = require("console")

let { buy_unit, add_player_exp, unitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { isCampaignWithUnitsResearch, curCampaign, campProfile } = require("%appGlobals/pServer/campaign.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { canBuyUnits } = require("%appGlobals/unitsState.nut")
let { isInSquad } = require("%appGlobals/squadState.nut")

let { delayedPurchaseUnitData, needSaveUnitDataForTutorial } = require("%rGui/unit/delayedPurchaseUnit.nut")
let { isUnitsTreeAttached, openUnitsTreeAtUnit, isUnitsTreeOpen } = require("%rGui/unitsTree/unitsTreeState.nut")
let { needDelayAnimation, isBuyUnitWndOpened, animExpPart,
  animUnitAfterResearch } = require("%rGui/unitsTree/animState.nut")
let { markTutorialCompleted, isFinishedUnitsResearch } = require("completedTutorials.nut")
let { nodes, unitsResearchStatus, currentResearch } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { hasModalWindows, moveModalToTop } = require("%rGui/components/modalWindows.nut")
let { setTutorialConfig, isTutorialActive, finishTutorial, WND_UID, goToStep,
  activeTutorialId } = require("tutorialWnd/tutorialWndState.nut")
let { setResearchUnit } = require("%rGui/unit/unitsWndActions.nut")
let { PURCHASE_BOX_UID } = require("%rGui/shop/msgBoxPurchase.nut")
let { slots, setUnitToSlot, canOpenSelectUnitWithModal, slotBarSelectWndAttached
  selectedUnitToSlot, closeSelectUnitToSlotWnd } = require("%rGui/slotBar/slotBarState.nut")
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")
let { triggerAnim } = require("%rGui/unitsTree/mkUnitPlate.nut")
let { closeMsgBox } = require("%rGui/components/msgBox.nut")
let { TUTORIAL_UNITS_RESEARCH_ID } = require("tutorialConst.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { btnBEsc } = require("%rGui/controlsMenu/gpActBtn.nut")


let STEP_SELECT_NEXT_RESEARCH_DESCRIPTION = "s6_select_next_research_description"
let STEP_PARTING_WORDS = "s9_tutorial_parting_words_research_unit"

let isDebugMode = mkWatched(persist, "isDebugMode", false)

let curResearchingUnitId = Computed(@() servProfile.get()?.levelInfo[curCampaign.get()].lastResearchedUnit ?? "")
let isFirstPredifinedReward = Computed(@()
  (campProfile.get()?.lastReceivedFirstBattlesRewardIds[curCampaign.get()] ?? -1) == 0)
let curResearchUnitStatus = Computed(@() unitsResearchStatus.get()?[curResearchingUnitId.get()] ?? {})

let canBuyCurResearchUnit = Computed(function() {
  let unitFromCanBuyUnits = canBuyUnits.get()?[curResearchingUnitId.get()]
  let canBuyUnit = unitFromCanBuyUnits != null
  let { isResearched = false, canBuy = false } = curResearchUnitStatus.get()
  return canBuyUnit || (isResearched && !canBuy)
})

let needShowTutorial = Computed(@() !isInSquad.get()
  && !isFinishedUnitsResearch.get()
  && isCampaignWithUnitsResearch.get()
  && isFirstPredifinedReward.get()
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

function getObjectsForTutorial() {
  let availableSlotsForSelection = slots.get()
    .map(@(_, idx) {
      keys = $"select_slot_{idx}"
      onClick = @() setUnitToSlot(idx)
    })
    .slice(1)

  let currentUnitNode = nodes.get()[curSelectedUnit.get()]
  let availableResearchNodes = nodes.get()
    .filter(@(node) node.y <= currentUnitNode.y
      && node.reqUnits.findindex(@(v) v == curSelectedUnit.get()) != null)
    .map(@(unit) {
      keys = $"treeNodeUnitPlate:{unit.name}"
      onClick = @() curSelectedUnit.set(unit.name)
    })

  return { availableSlotsForSelection, availableResearchNodes }
}

function forcedUnitPurchaseSkip() {
  if (!isBuyUnitWndOpened.get() || animUnitAfterResearch.get() == null || !animExpPart.get()) {
    closeSelectUnitToSlotWnd()
    goToStep(STEP_SELECT_NEXT_RESEARCH_DESCRIPTION)
  }
  else
    clearTimer(forcedUnitPurchaseSkip)
}

function startTutorial() {
  if (curSelectedUnit.get() != curResearchingUnitId.get())
    curSelectedUnit.set(curResearchingUnitId.get())
  let { availableSlotsForSelection, availableResearchNodes } = getObjectsForTutorial()
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
        nextKeyDelay = -1
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
        }
        text = loc("tutorial_purchase_researched_unit")
        charId = "mary_points"
        nextStepAfter = Computed(@() !isBuyUnitWndOpened.get() && selectedUnitToSlot.get() != null)
        objects = [{
          keys = "purchase_tutor_btn"
          needArrow = true
          function onClick() {
            if (!unitInProgress.get()) {
              let { unitId = "", currencyId = "", price = "" } = delayedPurchaseUnitData.get()
              if(unitId != "" && currencyId != "" && price != "")
                buy_unit(unitId, currencyId, price, { id = "onUnitPurchaseResult", unitId })
            }
            return true
          }
          hotkeys = ["^J:A"]
        }]
      }
      {
        id = "s4_units_wnd_animation"
        nextStepAfter = slotBarSelectWndAttached
        function beforeStart() {
          canOpenSelectUnitWithModal.set(true)
          needSaveUnitDataForTutorial.set(false)
          closeMsgBox(PURCHASE_BOX_UID)
          triggerAnim()
        }
        objects = [{ keys = "sceneRoot", onClick = @() true }]
      }
      {
        id = "s5_set_purchased_unit_to_slot"
        function beforeStart() {
          if(availableSlotsForSelection.len() == 0 || !slotBarSelectWndAttached.get())
            deferOnce(@() goToStep(STEP_SELECT_NEXT_RESEARCH_DESCRIPTION))
          moveModalToTop(WND_UID)
        }
        text = loc("tutorial_set_purchased_unit_to_slot")
        objects = availableSlotsForSelection
      }
      {
        id = STEP_SELECT_NEXT_RESEARCH_DESCRIPTION
        function beforeStart() {
          canOpenSelectUnitWithModal.set(false)
          curSelectedUnit.set(null)
        }
        text = loc("tutorial_select_next_research_description")
        nextKeyDelay = -1
      }
      {
        id = "s7_select_next_research_unit"
        function beforeStart() {
          if(availableResearchNodes.len() == 0)
            deferOnce(@() goToStep(STEP_PARTING_WORDS))
        }
        text = loc("tutorial_select_next_research_unit")
        objects = availableResearchNodes
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
        nextKeyDelay = -1
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
        nextKeyDelay = -1
        charId = "mary_like"
        text = loc("tutorial_finish_research_unit")
      }
    ]
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
      return dlog("Can't start tutorial after first battle: need to get out of the units tree")  // warning disable: -forbidden-function
    if (researchingUnitId == "")
      return dlog("Can't start tutorial after first battle: need researchingUnitId")  // warning disable: -forbidden-function

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
