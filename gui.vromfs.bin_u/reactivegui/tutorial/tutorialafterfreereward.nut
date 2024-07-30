from "%globalsDarg/darg_library.nut" import *
let logFB = log_with_prefix("[FIRST_BATTLE_TUTOR] ")
let { register_command } = require("console")
let { eventbus_send } = require("eventbus")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { isInSquad } = require("%appGlobals/squadState.nut")
let { newbieOfflineMissions, startCurNewbieMission } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let { randomBattleMode } = require("%rGui/gameModes/gameModeState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { setTutorialConfig, isTutorialActive, finishTutorial,
  activeTutorialId } = require("tutorialWnd/tutorialWndState.nut")
let { needShowTutorialAfterReward } = require("%rGui/rewards/freeRewardCampaigns.nut")

const TUTORIAL_ID = "tutorialAfterFreeReward"
let isSkipped = hardPersistWatched("tutorialAfterFreeReward.isSkipped", false)
let isDebugMode = mkWatched(persist, "isDebugMode", false)
let needShowTutorial = Computed(@() !isInSquad.get()
  && !isSkipped.get()
  && isCampaignWithUnitsResearch.get()
  && needShowTutorialAfterReward.get())
let canStartTutorial = Computed(@() !hasModalWindows.get()
  && isMainMenuAttached.get()
  && !isTutorialActive.get())
let showTutorial = keepref(Computed(@() canStartTutorial.get()
  && (needShowTutorial.get() || isDebugMode.get())))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.get() == TUTORIAL_ID
  && !isMainMenuAttached.get()))
let finishEarly = @() shouldEarlyCloseTutorial.get() ? finishTutorial() : null
shouldEarlyCloseTutorial.subscribe(@(v) v ? deferOnce(finishEarly) : null)

function startTutorial() {
  let unitsListShowEnough = Watched(false)
  setTutorialConfig({
    id = TUTORIAL_ID
    function onStepStatus(stepId, status) {
      logFB($"{stepId}: {status}")
      if (status == "skip_step")
        isSkipped(true)
      if (stepId == "s3_press_battle_button" && status == "tutorial_finished")
        needShowTutorialAfterReward.set(false)
    }
    steps = [
      {
        id = "s1_units_wnd_animation"
        function beforeStart() {
          resetTimeout(0.5, @() unitsListShowEnough.set(true))
        }
        nextStepAfter = unitsListShowEnough
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s3_press_battle_button"
        text = loc("tutorial/pressToBattleButton")
        onSkip = @() null
        objects = [{
          keys = "toBattleButton"
          function onClick() {
            if (newbieOfflineMissions.get() != null) {
              sendNewbieBqEvent("pressToBattleFromUITutor", {
                status = "offline_battle",
                params = ", ".join(newbieOfflineMissions.get())
              })
              startCurNewbieMission()
            }
            else {
              sendNewbieBqEvent("pressToBattleFromUITutor", {
                status = "online_battle",
                params = randomBattleMode.get()?.name ?? ""
              })
              eventbus_send("queueToGameMode", { modeId = randomBattleMode.get()?.gameModeId })
            }
          }
          needArrow = true
        }]
      }
    ]
  })
}

let startTutorialDelayed = @() deferOnce(function() {
  if (!showTutorial.value)
    return
  startTutorial()
  isDebugMode(false)
})

startTutorialDelayed()
showTutorial.subscribe(@(v) v ? startTutorialDelayed() : null)

register_command(
  @() activeTutorialId.get() != TUTORIAL_ID ? isDebugMode(true)
    : finishTutorial(),
  "debug.tutorial_after_free_reward")
