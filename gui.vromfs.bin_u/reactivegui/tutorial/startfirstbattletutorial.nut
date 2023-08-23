from "%globalsDarg/darg_library.nut" import *
let logFB = log_with_prefix("[FIRST_BATTLE_TUTOR] ")
let { send } = require("eventbus")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { register_command } = require("console")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isMainMenuAttached, isUnitsWndAttached, isUnitsWndOpened } = require("%rGui/mainMenu/mainMenuState.nut")
let { setTutorialConfig, isTutorialActive, finishTutorial, activeTutorialId
} = require("tutorialWnd/tutorialWndState.nut")
let { isInSquad } = require("%appGlobals/squadState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { hasJustUnlockedUnitsAnimation } = require("%rGui/unit/justUnlockedUnits.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { newbieOfflineMissions, startCurNewbieMission } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let { randomBattleMode } = require("%rGui/gameModes/gameModeState.nut")

const TUTORIAL_ID = "startFirstBattle"
let isSkipped = hardPersistWatched("firstBattleTutorial.isSkipped", false)
let isDebugMode = mkWatched(persist, "isDebugMode", false)
let hasBattles = Computed(@()
  (servProfile.value?.sharedStatsByCampaign ?? {})
    .findvalue(@(s) (s?.battles ?? 0) != 0 || (s?.offlineBattles ?? 0) != 0)
  != null)
let needShowTutorial = Computed(@() !isInSquad.value
  && !isSkipped.value
  && !hasBattles.value)
let canStartTutorial = Computed(@() isUnitsWndAttached.value
  && !hasModalWindows.value
  && !isTutorialActive.value)
let showTutorial = keepref(Computed(@() canStartTutorial.value
  && (needShowTutorial.value || isDebugMode.value)))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.value == TUTORIAL_ID
  && !isMainMenuAttached.value
  && !isUnitsWndAttached.value))
let finishEarly = @() shouldEarlyCloseTutorial.value ? finishTutorial() : null
shouldEarlyCloseTutorial.subscribe(@(v) v ? deferOnce(finishEarly) : null)

hasBattles.subscribe(@(v) v ? null : isSkipped(false))

let function startTutorial() {
  let unitsListShowEnough = Watched(false)
  local animationStartTime = 0
  setTutorialConfig({
    id = TUTORIAL_ID
    function onStepStatus(stepId, status) {
      logFB($"{stepId}: {status}")
      if (status == "skip_step")
        isSkipped(true)
    }
    steps = [
      //units window
      {
        id = "s1_units_wnd_animation"
        function beforeStart() {
          animationStartTime = get_time_msec()
          resetTimeout(3.0, @() unitsListShowEnough(true)) //to avoid hang when justBought units never become empty.
        }
        nextStepAfter = Computed(@() unitsListShowEnough.value || !hasJustUnlockedUnitsAnimation.value)
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
          onClick = @() isUnitsWndOpened(false)
        }]
      }
      //main menu
      {
        id = "s3_press_battle_button"
        text = loc("tutorial/pressToBattleButton")
        onSkip = @() null
        objects = [{
          keys = "toBattleButton"
          function onClick() {
            if (newbieOfflineMissions.value != null) {
              sendNewbieBqEvent("pressToBattleFromUITutor", { status = "offline_battle", params = ", ".join(newbieOfflineMissions.value) })
              startCurNewbieMission()
            }
            else {
              sendNewbieBqEvent("pressToBattleFromUITutor", { status = "online_battle", params = randomBattleMode.value?.name ?? "" })
              send("queueToGameMode", { modeId = randomBattleMode.value?.gameModeId })
            }
          }
          needArrow = true
        }]
      }
    ]
  })
}


//wait for switch scene animation
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
