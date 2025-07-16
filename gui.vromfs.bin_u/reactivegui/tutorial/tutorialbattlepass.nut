from "%globalsDarg/darg_library.nut" import *
let logT = log_with_prefix("[BATTLE_PASS_TUTOR] ")
let { register_command } = require("console")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { isInSquad } = require("%appGlobals/squadState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { isCampaignWithUnitsResearch, curCampaign, campProfile, firstLoginTime } = require("%appGlobals/pServer/campaign.nut")
let { receiveUnlockRewards, unlockInProgress } = require("%rGui/unlocks/unlocks.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isMainMenuTopScene } = require("%rGui/mainMenu/mainMenuState.nut")
let { openBattlePassWnd, battlePassOpenCounter, tutorialFreeMarkIdx, isBpSeasonActive
} = require("%rGui/battlePass/battlePassState.nut")
let { sendBqQuestsTask, sendBqQuestsStage } = require("%rGui/quests/bqQuests.nut")
let { calcStageCompletion } = require("%rGui/quests/questBar.nut")
let { openQuestsWndOnTab, COMMON_TAB, isQuestsOpen, questsCfg, questsBySection,
  progressUnlockByTab, progressUnlockBySection, DAILY_SECTION, tutorialSectionId } = require("%rGui/quests/questsState.nut")
let { getRewardsPreviewInfo, getEventCurrencyReward } = require("%rGui/quests/rewardsComps.nut")
let { markTutorialCompleted,
  isFinishedArsenal, isFinishedBattlePass, isFinishedSlotAttributes } = require("completedTutorials.nut")
let { TUTORIAL_BATTLE_PASS_ID, questTutorialOptionalTime } = require("tutorialConst.nut")
let { setTutorialConfig, isTutorialActive, finishTutorial, activeTutorialId } = require("tutorialWnd/tutorialWndState.nut")


let isDebugMode = mkWatched(persist, "isDebugMode", false)
let tabId = COMMON_TAB

let canShowTutorialByCampaign = Computed(@() !isCampaignWithUnitsResearch.get()
  || (isFinishedSlotAttributes.get() && isFinishedArsenal.get()))

let sectionId = Computed(@() questsCfg.get()?[tabId][0])

let hasRewardsToReceive = Computed(function() {
  local rewards = 0
  foreach (q in questsBySection.get()?[sectionId.get()] ?? {})
    if (q.hasReward)
      if (++rewards >= 2)
        return true
  return false
})

let hasFirstBattles = Computed(function() {
  let idx = (campProfile.get()?.lastReceivedFirstBattlesRewardIds[curCampaign.get()] ?? -1) + 1
  if (idx < 0)
    return false
  let battleRewardsLen = serverConfigs.get()?.firstBattlesRewards[curCampaign.get()].len() ?? 0
  return idx < battleRewardsLen
})

let almostReadyToShowTutorial = Computed(@() !isInSquad.get()
  && !isFinishedBattlePass.get()
  && canShowTutorialByCampaign.get()
  && hasRewardsToReceive.get()
  && !hasFirstBattles.get())

let isFullProgressBar = Computed(function() {
  if (!almostReadyToShowTutorial.get())
    return true
  let progressUnlock = progressUnlockByTab.get()?[tabId] ?? progressUnlockBySection.get()?[sectionId.get()]
  let { stages = [], current = 0 } = progressUnlock
  return null == stages.findvalue(@(_, idx) calcStageCompletion(stages, idx, current) != 1.0)
})

let needShowTutorial = Computed(@() almostReadyToShowTutorial.get() && !isFullProgressBar.get())
let canStartTutorial = Computed(@() !hasModalWindows.get()
  && isMainMenuTopScene.get()
  && isBpSeasonActive.get()
  && !isTutorialActive.get())
let showTutorial = keepref(Computed(@() canStartTutorial.get()
  && (needShowTutorial.get() || isDebugMode.get())))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.get() == TUTORIAL_BATTLE_PASS_ID
  && !isMainMenuTopScene.get() && battlePassOpenCounter.get() == 0 && !isQuestsOpen.get()))

let finishEarly = @() shouldEarlyCloseTutorial.get() ? finishTutorial() : null
shouldEarlyCloseTutorial.subscribe(@(v) v ? deferOnce(finishEarly) : null)

function receiveReward(item, currencyReward) {
  receiveUnlockRewards(item.name, 1, { stage = 1 })
  sendBqQuestsTask(item, currencyReward?.count ?? 0, currencyReward?.id)
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
          keys = "quest_wnd_btn"
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
              receiveUnlockRewards(name, stage, { stage, finalStage = stage })
              sendBqQuestsStage(progressUnlock.__merge({ tabId, sectionId = sectionId.get() }), count, id)
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
          onClick = openBattlePassWnd
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
    else
      isDebugMode.set(true)
  }
  "debug.tutorial_battle_pass")
