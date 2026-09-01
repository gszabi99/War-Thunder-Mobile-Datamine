from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_send
from "%appGlobals/pServer/bqClient.nut" import sendNewbieBqEvent
from "%appGlobals/squadState.nut" import isInSquad
from "%rGui/components/modalWindows.nut" import hasModalWindows
from "%rGui/gameModes/gameModeState.nut" import randomBattleMode, isGameModesReceived, shouldStartNewbieSingleOnline
from "%rGui/gameModes/newbieOfflineMissions.nut" import newbieOfflineMissions, isNextBattleNewbieOffline,
  newbieLocalMP, startCurNewbieMission
from "%rGui/mainMenu/mainMenuState.nut" import isInMenuNoModals, isMainMenuTopScene
from "%rGui/rewards/freeRewardCampaigns.nut" import needShowTutorialAfterReward
from "%rGui/tutorial/completedTutorials.nut" import markTutorialCompleted, mkIsTutorialCompleted
from "%rGui/tutorial/tutorialConst.nut" import TUTORIAL_AFTER_REWARD_ID
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import setTutorialConfig, isTutorialActive, finishTutorial,
  activeTutorialId
from "%rGui/unit/unitPurchaseEffectScene.nut" import isPurchEffectVisible, needOpenPurchEffect, hasUnitToShow


let logFB = log_with_prefix("[FIRST_BATTLE_TUTOR] ")


let isFinished = mkIsTutorialCompleted(TUTORIAL_AFTER_REWARD_ID)
let isDebugMode = mkWatched(persist, "isDebugMode", false)
let needShowTutorial = Computed(@() !isInSquad.get()
  && !isFinished.get()
  && needShowTutorialAfterReward.get())
let canStartTutorial = Computed(@() !hasModalWindows.get()
  && isInMenuNoModals.get()
  && !hasUnitToShow.get()
  && !isTutorialActive.get()
  && !isPurchEffectVisible.get()
  && !needOpenPurchEffect.get())
let showTutorial = keepref(Computed(@() canStartTutorial.get()
  && (needShowTutorial.get() || isDebugMode.get())))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.get() == TUTORIAL_AFTER_REWARD_ID
  && !isMainMenuTopScene.get()))
let finishEarly = @() shouldEarlyCloseTutorial.get() ? finishTutorial() : null
shouldEarlyCloseTutorial.subscribe(@(v) v ? deferOnce(finishEarly) : null)

function startTutorial() {
  setTutorialConfig({
    id = TUTORIAL_AFTER_REWARD_ID
    function onStepStatus(stepId, status) {
      logFB($"{stepId}: {status}")
      if (status == "tutorial_finished" && isMainMenuTopScene.get()) {
        markTutorialCompleted(TUTORIAL_AFTER_REWARD_ID)
        needShowTutorialAfterReward.set(false)
      }
    }
    steps = [
      {
        id = "s1_press_battle_button"
        text = loc("tutorial/pressToBattleButton")
        onSkip = @() null
        objects = [{
          keys = "toBattleButton"
          function onClick() {
            if (isNextBattleNewbieOffline.get() != null && !shouldStartNewbieSingleOnline.get()) {
              sendNewbieBqEvent("pressToBattleFromUITutor",
                { status = "offline_battle",
                  params = ", ".join(newbieOfflineMissions.get() != null ? newbieOfflineMissions.get()
                    : newbieLocalMP.get()?.mission_decl.missions_list.keys() ?? [])
                })
              startCurNewbieMission()
            }
            else {
              sendNewbieBqEvent("pressToBattleFromUITutor", {
                status = "online_battle",
                params = randomBattleMode.get()?.name ?? ""
              })
              if (isGameModesReceived.get())
                eventbus_send("queueToGameMode", { modeId = randomBattleMode.get()?.gameModeId })
            }
          }
          hotkeys = ["^J:X | Enter"]
          needArrow = true
        }]
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
  @() activeTutorialId.get() != TUTORIAL_AFTER_REWARD_ID ? isDebugMode.set(true)
    : finishTutorial(),
  "debug.tutorial_after_free_reward")
