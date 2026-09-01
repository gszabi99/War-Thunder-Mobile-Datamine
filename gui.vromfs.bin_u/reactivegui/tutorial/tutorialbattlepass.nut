from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.workcycle" import deferOnce, resetTimeout
from "%appGlobals/pServer/campaign.nut" import firstLoginTime
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/squadState.nut" import isInSquad
from "%rGui/battlePass/battlePassState.nut" import tutorialFreeMarkIdx, isBpSeasonActive
from "%rGui/battlePass/passState.nut" import BATTLE_PASS, isPassSceneAttached
from "%rGui/components/modalWindows.nut" import hasModalWindows
from "%rGui/components/msgBox.nut" import openMsgBox
import "%rGui/event/shouldShowEventMechanics.nut" as shouldShowEventMechanics
from "%rGui/gameModes/newbieOfflineMissions.nut" import hasFirstBattleRewards
from "%rGui/mainMenu/mainMenuState.nut" import isMainMenuTopScene
from "%rGui/quests/bqQuests.nut" import sendBqQuestsTask, sendBqQuestsStage
from "%rGui/quests/questBar.nut" import calcStageCompletion
from "%rGui/quests/questsState.nut" import COMMON_TAB, isQuestsAttached, questsCfg, questsBySection,
  getStarsTotalNonUpdatable, progressUnlockByTab, progressUnlockBySection, DAILY_SECTION, tutorialSectionId,
  tutorialQuestBtnKey
from "%rGui/quests/rewardsComps.nut" import getRewardsPreviewInfo, getEventCurrencyReward
from "%rGui/seasonScene/seasonSceneState.nut" import openMainSeasonScene, PASS_SCENE, openQuestsWndOnTab
from "%rGui/tutorial/completedTutorials.nut" import markTutorialCompleted, isFinishedArsenal, isFinishedBattlePass,
  isFinishedSlotAttributes
from "%rGui/tutorial/tutorialConst.nut" import TUTORIAL_BATTLE_PASS_ID, questTutorialOptionalTime
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import setTutorialConfig, isTutorialActive, finishTutorial,
  activeTutorialId
from "%rGui/unlocks/unlocks.nut" import receiveUnlockRewards, batchReceiveRewards, unlockInProgress


let logT = log_with_prefix("[BATTLE_PASS_TUTOR] ")


let isDebugMode = mkWatched(persist, "isDebugMode", false)
let tabId = COMMON_TAB

let canShowTutorialByCampaign = Computed(@() isFinishedSlotAttributes.get() && isFinishedArsenal.get())

let sectionId = Computed(@() questsCfg.get()?[tabId][0])

let hasRewardsToReceive = Computed(function() {
  local rewards = 0
  foreach (q in questsBySection.get()?[sectionId.get()] ?? {})
    if (q.hasReward)
      if (++rewards >= 2)
        return true
  return false
})

let almostReadyToShowTutorial = Computed(@() !isInSquad.get()
  && !isFinishedBattlePass.get()
  && canShowTutorialByCampaign.get()
  && hasRewardsToReceive.get()
  && !hasFirstBattleRewards.get())

let isFullProgressBar = Computed(function() {
  if (!almostReadyToShowTutorial.get())
    return true
  let progressUnlock = progressUnlockByTab.get()?[tabId] ?? progressUnlockBySection.get()?[sectionId.get()]
  let { stages = [], current = 0 } = progressUnlock
  return null == stages.findvalue(@(_, idx) calcStageCompletion(stages, idx, current) != 1.0)
})

let needShowTutorial = Computed(@() almostReadyToShowTutorial.get() && !isFullProgressBar.get())
let canStartTutorial = Computed(@() !hasModalWindows.get()
  && tutorialQuestBtnKey.get() != null
  && isMainMenuTopScene.get()
  && isBpSeasonActive.get()
  && !isTutorialActive.get()
  && shouldShowEventMechanics.get())
let showTutorial = keepref(Computed(@() canStartTutorial.get()
  && (needShowTutorial.get() || isDebugMode.get())))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.get() == TUTORIAL_BATTLE_PASS_ID
  && !isMainMenuTopScene.get()
  && !isQuestsAttached.get()
  && !isPassSceneAttached.get()))

let finishEarly = @() shouldEarlyCloseTutorial.get() ? finishTutorial() : null
shouldEarlyCloseTutorial.subscribe(@(v) v ? deferOnce(finishEarly) : null)

function receiveReward(item, currencyReward) {
  receiveUnlockRewards(item.name, 1, { stage = 1 })
  sendBqQuestsTask(item, getStarsTotalNonUpdatable(item), currencyReward?.count ?? 0, currencyReward?.id)
}

let mkReceiveRewardStepObjectNonUpdatable = @() (questsBySection.get()?[sectionId.get()] ?? {})
  .reduce(function(res, q) {
    if (!q.hasReward)
      return res
    let item = q.__merge({ tabId, sectionId = sectionId.get() })
    res.append({
      keys = $"quest_reward_receive_btn_{item.name}"
      onClick = @() receiveReward(item, getEventCurrencyReward(getRewardsPreviewInfo(item, serverConfigs.get())))
      needArrow = true
    })
    return res
  }, [])

function startTutorial() {
  let wndShowEnough = Watched(false)
  let stepObjectsForSecondReward = []
  let stepObjectsForKeyReward = []
  setTutorialConfig({
    id = TUTORIAL_BATTLE_PASS_ID
    function onStepStatus(stepId, status) {
      logT($"{stepId}: {status}")
      if (status == "tutorial_finished")
        markTutorialCompleted(TUTORIAL_BATTLE_PASS_ID)
    }
    steps = [
      {
        id = "s1_press_quest_wnd_btn"
        text = loc("tutorial/battlePass/openQuestWnd")
        objects = [{
          keys = tutorialQuestBtnKey
          function onClick() {
            tutorialSectionId.set(DAILY_SECTION)
            openQuestsWndOnTab(tabId)
          }
          needArrow = true
        }]
        charId = "mary_like"
      }
      {
        id = "s2_open_quest_wnd"
        beforeStart = @() resetTimeout(0.5, @() wndShowEnough.set(true))
        nextStepAfter = wndShowEnough
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s3_receive_first_reward"
        beforeStart = @() wndShowEnough.set(false)
        text = loc("tutorial/battlePass/receiveFirstReward")
        objects = mkReceiveRewardStepObjectNonUpdatable()
        charId = "mary_points"
      }
      {
        id = "s4_show_reward_animation"
        beforeStart = @() resetTimeout(0.5, @() wndShowEnough.set(true))
        nextStepAfter = Computed(@() wndShowEnough.get() && unlockInProgress.get().len() == 0)
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s5_receive_second_reward"
        function beforeStart() {
          stepObjectsForSecondReward.extend(mkReceiveRewardStepObjectNonUpdatable())
          wndShowEnough.set(false)
        }
        text = loc("tutorial/battlePass/receiveFirstReward")
        objects = stepObjectsForSecondReward
        charId = "mary_points"
      }
      {
        id = "s6_show_reward_animation"
        beforeStart = @() resetTimeout(0.5, @() wndShowEnough.set(true))
        nextStepAfter = Computed(@() wndShowEnough.get() && unlockInProgress.get().len() == 0)
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s7_receive_key_reward"
        function beforeStart() {
          wndShowEnough.set(false)
          let progressUnlock = progressUnlockByTab.get()?[tabId] ?? progressUnlockBySection.get()?[sectionId.get()]
          if (progressUnlock == null)
            return
          let { hasReward = false, stage, name, stages } = progressUnlock
          if (!hasReward)
            return

          let stageIdx = stage - 1
          let count = stages?[stageIdx].updStats[0].value.tointeger() ?? 0
          let id = stages?[stageIdx].updStats[0].name
          stepObjectsForKeyReward.append({
            keys = $"quest_bar_stage_{stageIdx}"
            function onClick() {
              batchReceiveRewards([{ unlock = name, up_to_stage = stage }])
              let unlock = progressUnlock.__merge({ tabId, sectionId = sectionId.get() })
              sendBqQuestsStage(unlock, getStarsTotalNonUpdatable(unlock), count, id)
            }
            needArrow = true
          })
        }
        text = loc("tutorial/battlePass/receiveSecondReward")
        objects = stepObjectsForKeyReward
        charId = "mary_like"
      }
      {
        id = "s8_show_reward_animation"
        beforeStart = @() resetTimeout(0.5, @() wndShowEnough.set(true))
        nextStepAfter = Computed(@() wndShowEnough.get() && unlockInProgress.get().len() == 0)
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s9_press_battle_pass_wnd_btn"
        text = loc("tutorial/battlePass/openBattlePassWnd")
        objects = [{
          keys = "quest_header_btn"
          onClick = @() openMainSeasonScene(PASS_SCENE, BATTLE_PASS)
          needArrow = true
        }]
        charId = "mary_points"
      }
      {
        id = "s10_open_battle_pass_wnd"
        beforeStart = @() resetTimeout(0.5, @() wndShowEnough.set(true))
        nextStepAfter = wndShowEnough
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s11_show_progress_bar"
        text = loc("tutorial/battlePass/progressBarInfo")
        hasNextKey = true
        objects = [{
          keys = "battle_pass_progress_bar"
          needArrow = true
        }]
      }
      {
        id = "s12_show_free_reward"
        text = loc("tutorial/battlePass/rewardInfo")
        hasNextKey = true
        objects = [{
          keys = Computed(@() $"battle_pass_reward_{tutorialFreeMarkIdx.get()}")
          needArrow = true
        }]
      }
      {
        id = "s13_show_end_time"
        text = loc("tutorial/battlePass/timeInfo")
        hasNextKey = true
        objects = [{
          keys = "battle_pass_time"
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
  if (firstLoginTime.get() < questTutorialOptionalTime)
    openMsgBox({
      text = loc("tutorial/battlePass/available")
      buttons = [
        { id = "cancel", isCancel = true, cb = @() markTutorialCompleted(TUTORIAL_BATTLE_PASS_ID) }
        { id = "ok", styleId = "PRIMARY", cb = startTutorial, isDefault = true }
      ]
    })
  else
    startTutorial()
  isDebugMode.set(false)
})

startTutorialDelayed()
showTutorial.subscribe(@(v) v ? startTutorialDelayed() : null)

activeTutorialId.subscribe(@(tutorialId) tutorialId != TUTORIAL_BATTLE_PASS_ID ? tutorialSectionId.set(null) : null)

register_command(
  function() {
    if (activeTutorialId.get() == TUTORIAL_BATTLE_PASS_ID)
      return finishTutorial()
    else if (!hasRewardsToReceive.get())
      console_print("Unable to start tutorial, because of no avaiable rewards to get") 
    else if (!isBpSeasonActive.get())
      console_print("Unable to start tutorial, because of no active battle pass season") 
    else if (tutorialQuestBtnKey.get() == null)
      console_print("Unable to start tutorial, because of broken quest button in main menu") 
    else
      isDebugMode.set(true)
  }
  "debug.tutorial_battle_pass")
