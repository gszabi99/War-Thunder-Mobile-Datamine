from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.workcycle" import deferOnce
from "%appGlobals/pServer/campaign.nut" import campConfigs, abTests
from "%appGlobals/pServer/pServerApi.nut" import buy_unit_level
from "%appGlobals/pServer/profile.nut" import campMyUnits
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/attributes/attrState.nut" import hasSlotAttrPreset
from "%rGui/attributes/buyLevelComp.nut" import countLevelBlock, generateDataDiscount
import "%rGui/attributes/unitAttr/buyUnitLevelWnd.nut" as buyUnitLevelWnd
from "%rGui/attributes/unitAttr/unitAttrState.nut" import openUnitAttrWnd, isUnitAttrOpened
from "%rGui/components/modalWindows.nut" import hasModalWindows
from "%rGui/mainMenu/mainMenuState.nut" import isMainMenuAttached
from "%rGui/tutorial/completedTutorials.nut" import markTutorialCompleted, isFinishedAttributes, isFinishedUnitsResearch
from "%rGui/tutorial/tutorialConst.nut" import TUTORIAL_ATTRIBUTES_ID
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import setTutorialConfig, isTutorialActive, finishTutorial,
  activeTutorialId
from "%rGui/unit/hangarUnit.nut" import hangarUnitName


let logT = log_with_prefix("[ATTR_TUTOR] ")


let isDebugMode = mkWatched(persist, "isDebugMode", false)

let usedFreeGold = Computed(@() (servProfile.get()?.freeGoldUse["purchaseUnitLevel"] ?? 0) >= 1)
let needShowTutorial = Computed(@() isFinishedUnitsResearch.get()
  && !isFinishedAttributes.get()
  && !usedFreeGold.get()
  && !hasSlotAttrPreset.get())
let canStartTutorial = Computed(@() !hasModalWindows.get()
  && isMainMenuAttached.get()
  && !isTutorialActive.get()
  && (abTests.get()?.hasSpendTutorials ?? "false") == "true")
let showTutorial = keepref(Computed(@() canStartTutorial.get()
  && (needShowTutorial.get() || isDebugMode.get())))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.get() == TUTORIAL_ATTRIBUTES_ID
  && !(isMainMenuAttached.get() || isUnitAttrOpened.get())))
let finishEarly = @() shouldEarlyCloseTutorial.get() ? finishTutorial() : null
shouldEarlyCloseTutorial.subscribe(@(v) v ? deferOnce(finishEarly) : null)

function startTutorial() {
  let unitName = hangarUnitName.get()
  let { maxLevel = null, level = 0, levelPreset = null, exp = null } = campMyUnits.get()?[unitName]
  let unitLevels = campConfigs.get()?.unitLevels[levelPreset] ?? []
  let levelsToMax = (maxLevel ?? unitLevels.len()) - level
  let { levels } = generateDataDiscount(campConfigs.get()?.unitLevelsDiscount ?? [], levelsToMax)[1]
  let { nextLevelExp } = countLevelBlock(unitLevels , level, levels, exp)
  setTutorialConfig({
    id = TUTORIAL_ATTRIBUTES_ID
    function onStepStatus(stepId, status) {
      logT($"{stepId}: {status}")
      if (status == "tutorial_finished")
        markTutorialCompleted(TUTORIAL_ATTRIBUTES_ID)
    },
    steps = [
      {
        id = "s1_open_attr_wnd"
        text = loc("tutorial/attributes/init")
        charId = "mary_like"
        objects = [{
          keys = "attr_btn"
          needArrow = true
          onClick = openUnitAttrWnd
        }]
      }
      {
        id = "s2_open_lvl_boost_wnd"
        text = loc("tutorial/attributes/init")
        charId = "mary_like"
        objects = [{
          keys = "attrLevelBoostBtn"
          needArrow = true
          onClick = @() buyUnitLevelWnd(unitName)
        }]
      }
      {
        id = "s3_open_slot_attributes"
        text = loc("tutorial/attributes/levelBtn")
        objects = [{
          keys = "attrOneLevelBtn"
          needArrow = true
          onClick = @() buy_unit_level(unitName, level, level + levels, nextLevelExp, 0, "closeBuyUnitLevelWnd")
        }]
      }
      {
        id = "s4_open_slot_attributes"
        text = loc("tutorial/slotAttributes/finish")
        charId = "mary_points"
        objects = [
          { keys = ["unitUpgradePoints", "unitUpgradePointsValue"], sizeIncAdd = hdpx(5), needArrow = true }
          { keys = "attributesList" }
        ]
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

register_command(
  function() {
    if (activeTutorialId.get() == TUTORIAL_ATTRIBUTES_ID)
      return finishTutorial()
    else if (hasSlotAttrPreset.get())
      console_print("Unable to start tutorial, because of existing slot attribute preset") 
    else if (usedFreeGold.get())
      console_print("Unable to start tutorial, because of no free gold use") 
    else
      isDebugMode.set(true)
  },
  "debug.tutorial_attributes")
