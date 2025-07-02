from "%globalsDarg/darg_library.nut" import *
let logT = log_with_prefix("[BATTLE_PASS_TUTOR] ")
let { register_command } = require("console")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { isInSquad } = require("%appGlobals/squadState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { isCampaignWithUnitsResearch, curCampaign, campProfile, sharedStats } = require("%appGlobals/pServer/campaign.nut")
let { receiveUnlockRewards, unlockInProgress } = require("%rGui/unlocks/unlocks.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isMainMenuTopScene } = require("%rGui/mainMenu/mainMenuState.nut")
let { sendBqQuestsTask } = require("%rGui/quests/bqQuests.nut")
let { openQuestsWndOnTab, COMMON_TAB, isQuestsOpen, curTabId, EVENT_TAB, questsBySection,
  tutorialSectionId, tutorialSectionIdWithReward, isSameTutorialSectionId } = require("%rGui/quests/questsState.nut")
let { getRewardsPreviewInfo, getEventCurrencyReward } = require("%rGui/quests/rewardsComps.nut")
let { openEventWnd, curEventLootboxes, isFitSeasonRewardsRequirements } = require("%rGui/event/eventState.nut")
let { openEventWndLootbox } = require("%rGui/shop/lootboxPreviewState.nut")
let { markTutorialCompleted, mkIsTutorialCompleted,
  isFinishedBattlePass, isFinishedSlotAttributes, isFinishedArsenal } = require("completedTutorials.nut")
let { questTutorialOptionalTime } = require("tutorialConst.nut")
let { setTutorialConfig, isTutorialActive, finishTutorial, activeTutorialId } = require("tutorialWnd/tutorialWndState.nut")


const TUTORIAL_ID = "tutorialMainEvent"
let isDebugMode = mkWatched(persist, "isDebugMode", false)
let tabId = EVENT_TAB
let isFinished = mkIsTutorialCompleted(TUTORIAL_ID)

let canShowTutorialByCampaign = Computed(@() !isCampaignWithUnitsResearch.get()
  || (isFinishedSlotAttributes.get() && isFinishedArsenal.get()))

let hasFirstBattles = Computed(function() {
  let idx = (campProfile.get()?.lastReceivedFirstBattlesRewardIds[curCampaign.get()] ?? -1) + 1
  if (idx < 0)
    return false
  let battleRewardsLen = serverConfigs.get()?.firstBattlesRewards[curCampaign.get()].len() ?? 0
  return idx < battleRewardsLen
})

let needShowTutorial = Computed(@() !isInSquad.get()
  && !isFinished.get()
  && canShowTutorialByCampaign.get()
  && isFinishedBattlePass.get()
  && !hasFirstBattles.get()
  && tutorialSectionIdWithReward.get() != null
  && isFitSeasonRewardsRequirements.get())
let canStartTutorial = Computed(@() !hasModalWindows.get()
  && isMainMenuTopScene.get()
  && !isTutorialActive.get())
let showTutorial = keepref(Computed(@() canStartTutorial.get()
  && (needShowTutorial.get() || isDebugMode.get())))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.get() == TUTORIAL_ID
  && !isMainMenuTopScene.get() && !isQuestsOpen.get()))

let finishEarly = @() shouldEarlyCloseTutorial.get() ? finishTutorial() : null
shouldEarlyCloseTutorial.subscribe(@(v) v ? deferOnce(finishEarly) : null)

function receiveReward(item, currencyReward) {
  receiveUnlockRewards(item.name, 1, { stage = 1 })
  sendBqQuestsTask(item, currencyReward?.count ?? 0, currencyReward?.id)
}

function startTutorial() {
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
        id = "s1_press_quests_wnd_btn"
        text = loc("tutorial/mainEvent/openQuestWnd")
        objects = [{
          keys = "quest_wnd_btn"
          onClick = @() openQuestsWndOnTab(COMMON_TAB)
          needArrow = true
        }]
        charId = "mary_like"
      }
      {
        id = "s2_open_quests_wnd"
        beforeStart = @() resetTimeout(0.5, @() wndShowEnough.set(true))
        nextStepAfter = wndShowEnough
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s3_open_main_event_tab"
        text = loc("tutorial/mainEvent/openMainEventTab")
        objects = [{
          keys = "main_event_tab"
          onClick = @() curTabId.set(tabId)
          needArrow = true
        }]
        charId = "mary_points"
      }
      {
        id = "s4_open_section_with_reward"
        text = isSameTutorialSectionId.get() ? loc("tutorial/mainEvent/sectionInfo")
          : "\n".concat(loc("tutorial/mainEvent/sectionInfo"), loc("tutorial/mainEvent/openSectionWithReward"))
        hasNextKey = isSameTutorialSectionId.get()
        objects = [{
          keys = Computed(@() $"sectionId_{tutorialSectionIdWithReward.get()}")
          onClick = isSameTutorialSectionId.get() ? null
            : @() tutorialSectionId.set(tutorialSectionIdWithReward.get())
          needArrow = true
        }]
        charId = "mary_points"
      }
      {
        id = "s5_receive_reward"
        beforeStart = @() wndShowEnough.set(false)
        text = loc("tutorial/mainEvent/receiveReward")
        objects = (questsBySection.get()?[tutorialSectionIdWithReward.get()] ?? {})
          .reduce(function(res, q) {
            if (!q.hasReward)
              return res
            let item = q.__merge({ tabId, sectionId = tutorialSectionIdWithReward.get() })
            res.append({
              keys = $"quest_reward_receive_btn_{item.name}"
              onClick = @() receiveReward(item, getEventCurrencyReward(getRewardsPreviewInfo(item, serverConfigs.get())))
              needArrow = true
            })
            return res
          }, [])
        charId = "mary_points"
      }
      {
        id = "s6_show_reward_animation"
        beforeStart = @() resetTimeout(0.5, @() wndShowEnough.set(true))
        nextStepAfter = Computed(@() wndShowEnough.get() && unlockInProgress.get().len() == 0)
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s7_press_lootboxes_wnd_btn"
        beforeStart = @() wndShowEnough.set(false)
        text = loc("tutorial/mainEvent/openLootboxesWnd")
        objects = [{
          keys = "quest_header_btn"
          onClick = openEventWnd
          needArrow = true
        }]
        charId = "mary_like"
      }
      {
        id = "s8_open_lootboxes_wnd"
        beforeStart = @() resetTimeout(0.5, @() wndShowEnough.set(true))
        nextStepAfter = wndShowEnough
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s9_open_middle_lootbox"
        text = loc("tutorial/mainEvent/openMiddleLootbox")
        objects = [{
          keys = Computed(@() $"lootbox_{curEventLootboxes.get()?[1].name}")
          onClick = @() openEventWndLootbox(curEventLootboxes.get()?[1].name)
          needArrow = true
        }]
        charId = "mary_points"
      }
      {
        id = "s10_show_jackpot_progress"
        text = loc("tutorial/mainEvent/jackpotProgressInfo")
        hasNextKey = true
        objects = [{
          keys = "jackpot_progress"
          needArrow = true
        }]
      }
      {
        id = "s11_show_end_time"
        text = loc("tutorial/mainEvent/timeInfo")
        hasNextKey = true
        objects = [{
          keys = "event_time"
          needArrow = true
        }]
        charId = "mary_like"
      }
    ]
  })
}

let startTutorialDelayed = @() deferOnce(function() {
  if (!showTutorial.get())
    return
  if ((sharedStats.get()?.firstLoginTime ?? 0) < questTutorialOptionalTime)
    openMsgBox({
      text = loc("tutorial/mainEvent/available")
      buttons = [
        { id = "cancel", isCancel = true, cb = @() markTutorialCompleted(TUTORIAL_ID) }
        { id = "ok", styleId = "PRIMARY", cb = startTutorial, isDefault = true }
      ]
    })
  else
    startTutorial()
  isDebugMode.set(false)
})

startTutorialDelayed()
showTutorial.subscribe(@(v) v ? startTutorialDelayed() : null)

activeTutorialId.subscribe(@(tutorialId) tutorialId != TUTORIAL_ID ? tutorialSectionId.set(null) : null)

register_command(
  function() {
    if (activeTutorialId.get() == TUTORIAL_ID)
      return finishTutorial()
    if (tutorialSectionIdWithReward.get() == null)
      console_print("Unable to start tutorial, because of no avaiable rewards to get") 
    else
      isDebugMode.set(true)
  }
  "debug.tutorial_main_event")
