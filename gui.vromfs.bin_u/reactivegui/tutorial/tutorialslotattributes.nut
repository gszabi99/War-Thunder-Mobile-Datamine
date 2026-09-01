from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.workcycle" import deferOnce, resetTimeout
from "sound_wt" import playSound
from "%appGlobals/pServer/campaign.nut" import campConfigs, curCampaign, abTests
from "%appGlobals/pServer/pServerApi.nut" import slotInProgress, buy_slot_level
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/pServer/slots.nut" import curCampaignSlots, curSlots
from "%rGui/attributes/attrBlockComp.nut" import applyAttrRowChange
from "%rGui/attributes/attrState.nut" import hasSlotAttrPreset, curCategoryId, selAttributes, getMaxAttrLevelData,
  attrPresets
from "%rGui/attributes/buyLevelComp.nut" import countLevelBlock, generateDataDiscount
import "%rGui/attributes/slotAttr/buySlotLevelWnd.nut" as buySlotLevelWnd
from "%rGui/attributes/slotAttr/slotAttrState.nut" import isSlotAttrAttached, openSlotAttrWnd, slotAttributes,
  leftSlotSp, isApplyBtnAttached, applyAttributes, hasUpgradedAttrUnitNotUpdatable, needDistributeCampaignSlotExp
from "%rGui/components/backButtonBlink.nut" import backButtonBlink
from "%rGui/components/modalWindows.nut" import hasModalWindows
from "%rGui/mainMenu/mainMenuState.nut" import isMainMenuAttached
from "%rGui/notifications/logEvents.nut" import sendTelemetryEvent
from "%rGui/slotBar/slotBarState.nut" import selectedSlotIdx, slotBarSlotKey, slotLevelsCfg, slotMaxLevel
from "%rGui/tutorial/completedTutorials.nut" import markTutorialCompleted, isFinishedSlotAttributes
from "%rGui/tutorial/tutorialConst.nut" import TUTORIAL_SLOT_ATTRIBUTES_ID
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import setTutorialConfig, isTutorialActive, finishTutorial,
  activeTutorialId, goToStep


let logT = log_with_prefix("[SLOT_ATTR_TUTOR] ")


const BOOST_LEVEL_STEP = "s9_press_level_boost_btn"

let isDebugMode = mkWatched(persist, "isDebugMode", false)

let usedFreeGold = Computed(@() (servProfile.get()?.freeGoldUse["purchaseSlotLevel"] ?? 0) >= 1)
let hasSlotForTutor = @(cSlots) cSlots != null && null != cSlots.slots.findindex(@(slot) slot.sp > 0)
let needShowTutorial = Computed(@() !isFinishedSlotAttributes.get()
  && !usedFreeGold.get()
  && hasSlotAttrPreset.get()
  && curCampaignSlots.get() != null
  && selectedSlotIdx.get() != null
  && null == curCampaignSlots.get().slots.findvalue(@(slot) slot.attrLevels.len() > 0)
  && hasSlotForTutor(curCampaignSlots.get())
  && !needDistributeCampaignSlotExp.get())
let canStartTutorial = Computed(@() !hasModalWindows.get()
  && isMainMenuAttached.get()
  && !isTutorialActive.get())
let showTutorial = keepref(Computed(@() canStartTutorial.get()
  && (needShowTutorial.get() || isDebugMode.get())))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.get() == TUTORIAL_SLOT_ATTRIBUTES_ID
  && !(isMainMenuAttached.get() || isSlotAttrAttached.get())))
let finishEarly = @() shouldEarlyCloseTutorial.get() ? finishTutorial() : null
shouldEarlyCloseTutorial.subscribe(@(v) v ? deferOnce(finishEarly) : null)


function getTutorSlotIndex(cSlots) {
  if (cSlots == null)
    return null
  local slotIdx = null
  local sp = 0
  foreach (idx, slot in cSlots.slots)
    if (slot.sp > sp) {
      slotIdx = idx
      sp = slot.sp
    }
  return slotIdx
}

let getIncButtonsForTutorial = @(cat) cat?.attrList.reduce(function(res, attr, idx) {
  let catId = curCategoryId.get()
  let minLevel = slotAttributes.get()?[catId][attr.id] ?? 0
  let selLevel = max(selAttributes.get()?[catId][attr.id] ?? minLevel, minLevel)
  let { maxLevel } = getMaxAttrLevelData(attr, selLevel, leftSlotSp.get())
  return selLevel >= maxLevel ? res
    : res.append({
        keys = $"slotAttrProgressBtn_{idx}"
        function onClick() {
          applyAttrRowChange(catId, attr.id, selLevel + 1, Watched(selLevel), Watched(minLevel), Watched(maxLevel))
          playSound("click")
        }
        needArrow = idx == 0
      })
}, []) ?? []

function startTutorial() {
  let slotIdx = getTutorSlotIndex(curCampaignSlots.get())
  if (slotIdx == null) {
    logerr("Tutorial 'slot attributes' started without slotIdx")
    return
  }

  let slotPresets = attrPresets.get()?[campConfigs.get()?.campaignCfg.slotAttrPreset] ?? []

  if(curCategoryId.get() == null)
    curCategoryId.set(slotPresets?[0].id)

  let curSlotCategory = slotPresets.findvalue(@(p) p.id == curCategoryId.get())
  let availableIncButtons = getIncButtonsForTutorial(curSlotCategory)

  logT($"Started for slot #{slotIdx + 1}")
  let isCurrentSlot = Computed(@() selectedSlotIdx.get() == slotIdx)
  let wasCurrentSlotAtStart = isCurrentSlot.get()
  let wndShowEnough = Watched(false)

  let { level = 0, exp = 0 } = curSlots.get()[slotIdx]
  let levelsToMax = slotMaxLevel.get() - level
  let { levels } = generateDataDiscount(campConfigs.get()?.unitLevelsDiscount ?? [], levelsToMax, hasSlotAttrPreset.get())[0]
  let { nextLevelExp } = countLevelBlock(slotLevelsCfg.get(), level, levels, exp)

  let addSteps = (abTests.get()?.hasSpendTutorials ?? "false") == "true"
    ? [
        {
          id = "s5_change_slot_attributes"
          function beforeStart() {
            if (availableIncButtons.len() == 0)
              deferOnce(@() goToStep(BOOST_LEVEL_STEP))
          }
          text = loc("tutorial/slotAttributes/clickPlusBtn")
          charId = "mary_points"
          objects = availableIncButtons
        }
        {
          id = "s6_show_apply_btn"
          nextStepAfter = isApplyBtnAttached
        }
        {
          id = "s7_mark_slot_attr_apply_btn"
          charId = null
          text = loc("tutorial/slotAttributes/applyChanges")
          objects = [
            { keys = "sceneRoot" },
            {
              keys = "slotAttrApplyBtn"
              needArrow = true
              function onClick() {
                if (!hasUpgradedAttrUnitNotUpdatable())
                  sendTelemetryEvent("add_unit_attributes")
                applyAttributes()
                backButtonBlink("UnitAttr")
                playSound("characteristics_apply")
              }
              hotkeys = ["^J:X"]
            }
          ]
        }
        {
          id = "s8_show_boost_level_btn"
          nextStepAfter = Computed(@() !slotInProgress.get())
        }
        {
          id = BOOST_LEVEL_STEP
          charId = "mary_points"
          text = loc("tutorial/slotAttributes/clickBoostBtn")
          objects = [
            {
              keys = "slotAttrLevelBoostBtn"
              needArrow = true
              onClick = @() buySlotLevelWnd(selectedSlotIdx.get())
              hotkeys = ["^J:X"]
            }
          ]
        }
        {
          id = "s10_press_one_level_btn"
          charId = "mary_points"
          text = loc("tutorial/slotAttributes/oneLevelBtn")
          objects = [
            {
              keys = "slotAttrOneLevelBtn"
              needArrow = true
              onClick = @() buy_slot_level(curCampaign.get(), slotIdx, level, level + levels, nextLevelExp, 0, "closeBuySlotLevelWnd")
              hotkeys = ["^J:X"]
            }
          ]
        }
        {
          id = "s11_finish_slot_attributes_tutorial"
          hasNextKey = true
          charId = "mary_like"
          text = loc("tutorial/slotAttributes/finish")
        }
      ]
    : [
        {
          id = "s5_change_slot_attributes"
          function beforeStart() {
            if(availableIncButtons.len() == 0)
              deferOnce(@() goToStep("s6_finish_slot_attributes_tutorial"))
          }
          text = loc("tutorial/slotAttributes/clickPlusBtn")
          charId = "mary_points"
          objects = availableIncButtons
        }
        {
          id = "s6_finish_slot_attributes_tutorial"
          hasNextKey = true
          charId = "mary_like"
          text = loc("tutorial/slotAttributes/finish")
        }
        {
          id = "s7_mark_slot_attr_apply_btn"
          charId = null
          objects = [
            { keys = "sceneRoot" },
            {
              keys = "slotAttrApplyBtn"
              needArrow = true
              function onClick() {
                if(!hasUpgradedAttrUnitNotUpdatable())
                  sendTelemetryEvent("add_unit_attributes")
                applyAttributes()
                backButtonBlink("UnitAttr")
                playSound("characteristics_apply")
              }
              hotkeys = ["^J:X"]
            }
          ]
        }
      ]

  setTutorialConfig({
    id = TUTORIAL_SLOT_ATTRIBUTES_ID
    function onStepStatus(stepId, status) {
      logT($"{stepId}: {status}")
      if (status == "tutorial_finished")
        markTutorialCompleted(TUTORIAL_SLOT_ATTRIBUTES_ID)
    },
    steps = [
      {
        id = "s1_mainmenu_select_slot"
        nextStepAfter = isCurrentSlot
        text = "\n".concat(loc("tutorial/slotAttributes/initCongratulations"),
          loc("tutorial/slotAttributes/chooseSlot"))
        charId = "mary_like"
        objects = [{
          keys = slotBarSlotKey(slotIdx)
          needArrow = true
          function onClick() {
            selectedSlotIdx.set(slotIdx)
            return true
          }
        }]
      }
      {
        id = "s2_press_crew_upgrade_button"
        text = !wasCurrentSlotAtStart ? loc("tutorial/slotAttributes/moveToAtributesWnd")
          : "\n".concat(loc("tutorial/slotAttributes/initCongratulations"),
            loc("tutorial/slotAttributes/moveToAtributesWnd"))
        charId = "mary_like"
        objects = [{
          keys = "slot_crew_btn"
          needArrow = true
          onClick = openSlotAttrWnd
        }]
      }
      {
        id = "s3_open_slot_attributes"
        beforeStart = @() resetTimeout(0.5, @() wndShowEnough.set(true))
        nextStepAfter = wndShowEnough
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s4_open_slot_attributes"
        text = loc("tutorial/slotAttributes/attributesInfo")
        charId = "mary_points"
        hasNextKey = true
        objects = [
          { keys = ["upgradePoints", "upgradePointsValue"], sizeIncAdd = hdpx(5), needArrow = true }
          { keys = "slotAttributesList" }
        ]
      }
    ].extend(addSteps)
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
    if (activeTutorialId.get() == TUTORIAL_SLOT_ATTRIBUTES_ID)
      return finishTutorial()
    if (!hasSlotForTutor(curCampaignSlots.get()))
      console_print("Unable to start tutorial, because of no slots with SP available") 
    else if (!hasSlotAttrPreset.get())
      console_print("Unable to start tutorial, because of no slot attribute preset") 
    else if (usedFreeGold.get())
      console_print("Unable to start tutorial, because of no free gold use") 
    else
      isDebugMode.set(true)
  },
  "debug.tutorial_slot_attributes")
