from "%globalsDarg/darg_library.nut" import *
let logFB = log_with_prefix("[FIRST_BATTLE_TUTOR] ")
let { eventbus_send } = require("eventbus")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { register_command } = require("console")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { isUnitsTreeOpen, isUnitsTreeAttached } = require("%rGui/unitsTree/unitsTreeState.nut")
let { setTutorialConfig, isTutorialActive, finishTutorial, activeTutorialId
} = require("tutorialWnd/tutorialWndState.nut")
let { markTutorialCompleted, mkIsTutorialCompleted } = require("completedTutorials.nut")
let { isInSquad } = require("%appGlobals/squadState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { hasJustUnlockedUnitsAnimation } = require("%rGui/unit/justUnlockedUnits.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { newbieOfflineMissions, startCurNewbieMission } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let { randomBattleMode, shouldStartNewbieSingleOnline } = require("%rGui/gameModes/gameModeState.nut")
let { isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { btnBEsc } = require("%rGui/controlsMenu/gpActBtn.nut")

const TUTORIAL_ID = "startFirstBattle"
let isFinished = mkIsTutorialCompleted(TUTORIAL_ID)
let isDebugMode = mkWatched(persist, "isDebugMode", false)
let hasBattles = Computed(@()
  (servProfile.value?.sharedStatsByCampaign ?? {})
    .findvalue(@(s) (s?.battles ?? 0) != 0 || (s?.offlineBattles ?? 0) != 0)
  != null)

let needShowTutorial = Computed(@() !isInSquad.get()
  && !isFinished.get()
  && !isCampaignWithUnitsResearch.get()
  && !hasBattles.get())
let canStartTutorial = Computed(@() isUnitsTreeAttached.get()
  && !hasModalWindows.get()
  && !isTutorialActive.value)
let showTutorial = keepref(Computed(@() canStartTutorial.value
  && (needShowTutorial.value || isDebugMode.value)))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.value == TUTORIAL_ID
  && !isMainMenuAttached.get()
  && !isUnitsTreeAttached.get()))
let finishEarly = @() shouldEarlyCloseTutorial.value ? finishTutorial() : null
shouldEarlyCloseTutorial.subscribe(@(v) v ? deferOnce(finishEarly) : null)

hasBattles.subscribe(@(v) v ? null : markTutorialCompleted(TUTORIAL_ID))

function startTutorial() {
  let unitsListShowEnough = Watched(false)
  local animationStartTime = 0
  setTutorialConfig({
    id = TUTORIAL_ID
    function onStepStatus(stepId, status) {
      logFB($"{stepId}: {status}")
      if (status == "tutorial_finished")
        markTutorialCompleted(TUTORIAL_ID)
    }
    steps = [
      
      {
        id = "s1_units_wnd_animation"
        function beforeStart() {
          animationStartTime = get_time_msec()
          resetTimeout(3.0, @() unitsListShowEnough(true)) 
        }
        nextStepAfter = Computed(@() unitsListShowEnough.value || !hasJustUnlockedUnitsAnimation.get())
        objects = [{
          keys = "sceneRoot"
          onClick = @() animationStartTime + 1000 <= get_time_msec()
        }]
      }
      {
        id = "s2_units_wnd_press_back"
        text = loc("tutorial/pressBackToReturnToMainScreen")
        objects = [{
          keys = "backButton"
          sizeIncAdd = hdpx(20)
          needArrow = true
          onClick = @() isUnitsTreeOpen(false)
          hotkeys = [btnBEsc]
        }]
      }
      
      {
        id = "s3_press_battle_button"
        text = loc("tutorial/pressToBattleButton")
        charId = "mary_like"
        onSkip = @() null
        objects = [{
          keys = "toBattleButton"
          function onClick() {
            if (newbieOfflineMissions.get() != null && !shouldStartNewbieSingleOnline.get()) {
              sendNewbieBqEvent("pressToBattleFromUITutor", { status = "offline_battle", params = ", ".join(newbieOfflineMissions.value) })
              startCurNewbieMission()
            }
            else {
              sendNewbieBqEvent("pressToBattleFromUITutor", { status = "online_battle", params = randomBattleMode.value?.name ?? "" })
              eventbus_send("queueToGameMode", { modeId = randomBattleMode.value?.gameModeId })
            }
          }
          needArrow = true
          hotkeys = ["^J:X | Enter"]
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
  @() activeTutorialId.value != TUTORIAL_ID ? isDebugMode(true)
    : finishTutorial(),
  "debug.first_battle_ui_tutorial")
