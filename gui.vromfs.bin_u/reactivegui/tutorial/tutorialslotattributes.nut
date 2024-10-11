from "%globalsDarg/darg_library.nut" import *
let logT = log_with_prefix("[SLOT_ATTR_TUTOR] ")
let { playSound } = require("sound_wt")
let { register_command } = require("console")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { curCampaignSlots, campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { setTutorialConfig, isTutorialActive, finishTutorial, activeTutorialId, goToStep
} = require("tutorialWnd/tutorialWndState.nut")
let { markTutorialCompleted, mkIsTutorialCompleted } = require("completedTutorials.nut")
let { hasSlotAttrPreset, curCategoryId, selAttributes, getMaxAttrLevelData, attrPresets
} = require("%rGui/attributes/attrState.nut")
let { isSlotAttrAttached, openSlotAttrWnd, slotAttributes, leftSlotSp,
  applyAttributes, hasUpgradedAttrUnitNotUpdatable
} = require("%rGui/attributes/slotAttr/slotAttrState.nut")
let { selectedSlotIdx, slotBarSlotKey } = require("%rGui/slotBar/slotBarState.nut")
let { applyAttrRowChange } = require("%rGui/attributes/attrBlockComp.nut")
let { backButtonBlink } = require("%rGui/components/backButtonBlink.nut")
let { sendAppsFlyerEvent } = require("%rGui/notifications/logEvents.nut")

let FINISH_STEP = "s6_finish_slot_attributes_tutorial"

const TUTORIAL_ID = "tutorialSlotAttributes"
let isDebugMode = mkWatched(persist, "isDebugMode", false)
let isFinished = mkIsTutorialCompleted(TUTORIAL_ID)

let hasSlotForTutor = @(cSlots) cSlots != null && null != cSlots.slots.findindex(@(slot) slot.sp > 0)
let needShowTutorial = Computed(@() !isFinished.get()
  && hasSlotAttrPreset.get()
  && curCampaignSlots.get() != null
  && selectedSlotIdx.get() != null
  && null == curCampaignSlots.get().slots.findvalue(@(slot) slot.attrLevels.len() > 0)
  && hasSlotForTutor(curCampaignSlots.get()))
let canStartTutorial = Computed(@() !hasModalWindows.get()
  && isMainMenuAttached.get()
  && !isTutorialActive.get())
let showTutorial = keepref(Computed(@() canStartTutorial.get()
  && (needShowTutorial.get() || isDebugMode.get())))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.get() == TUTORIAL_ID
  && (!hasSlotForTutor(curCampaignSlots.get())
    || !(isMainMenuAttached.get() || isSlotAttrAttached.get()))))
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

let getIncButtonsForTutorial = @(cat) cat?.attrList.map(@(attr, idx) {
  keys = $"slotAttrProgressBtn_{idx}"
  function onClick() {
    let catId = curCategoryId.get()
    let minLevel = slotAttributes.get()?[catId][attr.id] ?? 0
    let selLevel = max(selAttributes.get()?[catId][attr.id] ?? minLevel, minLevel)
    let { maxLevel } = getMaxAttrLevelData(attr, selLevel, leftSlotSp.get())
    applyAttrRowChange(catId, attr.id, selLevel + 1, Watched(selLevel), Watched(minLevel), Watched(maxLevel))
  }
  needArrow = idx == 0
}) ?? []

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

  setTutorialConfig({
    id = TUTORIAL_ID
    function onStepStatus(stepId, status) {
      logT($"{stepId}: {status}")
      if (status == "tutorial_finished")
        markTutorialCompleted(TUTORIAL_ID)
    }
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
          onClick = @() openSlotAttrWnd()
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
        nextKeyDelay = -1
        objects = [
          { keys = ["upgradePoints", "upgradePointsValue"], sizeIncAdd = hdpx(5), needArrow = true }
          { keys = "slotAttributesList" }
        ]
      }
      {
        id = "s5_change_slot_attributes"
        function beforeStart() {
          if(availableIncButtons.len() == 0)
            deferOnce(@() goToStep(FINISH_STEP))
        }
        text = loc("tutorial/slotAttributes/clickPlusBtn")
        charId = "mary_points"
        objects = availableIncButtons
      }
      {
        id = FINISH_STEP
        nextKeyDelay = -1
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
                sendAppsFlyerEvent("add_unit_attributes")
              applyAttributes()
              backButtonBlink("UnitAttr")
              playSound("characteristics_apply")
            }
          }
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
    if (activeTutorialId.get() == TUTORIAL_ID)
      return finishTutorial()
    if (!hasSlotForTutor(curCampaignSlots.get()))
      console_print("Unable to start tutorial, because of no slots with SP available") //warning disable: -forbidden-function
    else
      isDebugMode.set(true)
  },
  "debug.tutorial_slot_attributes")
