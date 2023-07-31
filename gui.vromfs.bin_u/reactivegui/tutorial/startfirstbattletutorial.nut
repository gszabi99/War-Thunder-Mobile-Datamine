from "%globalsDarg/darg_library.nut" import *
let logFB = log_with_prefix("[FIRST_BATTLE_TUTOR] ")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInMenuNoModals, isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { needFirstBattleTutor, startTutor, firstBattleTutor, isTutorialMissionsDebug
} = require("tutorialMissions.nut")
let { resetTimeout } = require("dagor.workcycle")
let { setTutorialConfig, isTutorialActive, finishTutorial, activeTutorialId
} = require("tutorialWnd/tutorialWndState.nut")

const TUTORIAL_ID = "startFirstBattle"
let isSkipped = hardPersistWatched("firstBattleTutorial.isSkipped", false)
let showTutorial = keepref(Computed(@() needFirstBattleTutor.value
  && !isSkipped.value
  && isInMenuNoModals.value
  && !isTutorialActive.value))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.value == TUTORIAL_ID
  && !isMainMenuAttached.value))
shouldEarlyCloseTutorial.subscribe(@(v) v ? finishTutorial() : null)

isTutorialMissionsDebug.subscribe(@(v) v ? isSkipped(false)
  : isTutorialActive.value ? finishTutorial()
  : null)

let startTutorial = @() setTutorialConfig({
  id = TUTORIAL_ID
  onStepStatus = @(stepId, status) logFB($"{stepId}: {status}")
  steps = [
    {
      id = "s1_press_battle_button"
      text = loc("tutorial/pressToBattleButton")
      function onSkip() {
        isSkipped(true) //to avoid reopen it in this session
        isTutorialMissionsDebug(false) //to disable reopen tutorial if opened by debug mode
        finishTutorial()
        return true
      }
      objects = [{
        keys = "toBattleButton"
        function onClick() {
          startTutor(firstBattleTutor.value)
          isTutorialMissionsDebug(false) //to disable reopen tutorial if opened by debug mode
        }
        needArrow = true
      }]
    }
  ]
})


//wait for switch scene animation
let startTutorialDelayed = @() resetTimeout(0.3, function() {
  if (showTutorial.value)
    startTutorial()
})

startTutorialDelayed()
showTutorial.subscribe(@(v) v ? startTutorialDelayed() : null)
