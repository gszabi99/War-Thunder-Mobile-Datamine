from "%globalsDarg/darg_library.nut" import *
let logFB = log_with_prefix("[FIRST_BATTLE_TUTOR] ")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { register_command } = require("console")
let { setTutorialConfig, isTutorialActive, finishTutorial, activeTutorialId, nextStep, WND_UID
} = require("tutorialWnd/tutorialWndState.nut")
let { markTutorialCompleted, mkIsTutorialCompleted } = require("completedTutorials.nut")
let { isInSquad } = require("%appGlobals/squadState.nut")
let { isInRespawn, isRespawnStarted } = require("%appGlobals/clientState/respawnStateBase.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { showRespChooseWnd, curSlotName, applyBullet } = require("%rGui/respawn/respawnChooseBulletWnd.nut")
let { bulletsInfo, visibleBullets, chosenBullets } = require("%rGui/respawn/bulletsChoiceState.nut")
let { selSlot } = require("%rGui/respawn/respawnState.nut")
let { lightCtor } = require("tutorialWnd/tutorialWndDefStyle.nut")
let { bulletsLegend, headerMargin, gap } = require("%rGui/respawn/respawnComps.nut")
let { sendPlayerActivityToServer } = require("%rGui/respawn/playerActivity.nut")
let { moveModalToTop } = require("%rGui/components/modalWindows.nut")

const TUTORIAL_ID = "choosingShells"

let choiceCount = Computed(@() chosenBullets.get().len())
let objectsForSixStep = Watched([])
let setCurSlot = @(name) curSlotName.set(name)

let isFinished = mkIsTutorialCompleted(TUTORIAL_ID)
let isDebugMode = mkWatched(persist, "isDebugMode", false)
let hasEnoughBullets = Computed(@() visibleBullets.get().len() >= 3)
let needShowTutorial = Computed(@() hasEnoughBullets.get()
  && !isInSquad.get()
  && !isFinished.get())
let canStartTutorial = Computed(@() !isTutorialActive.get()
  && !isRespawnStarted.get()
  && isInRespawn.get()
  && selSlot.get()?.name != null)
let showTutorial = keepref(Computed(@() canStartTutorial.get()
  && (needShowTutorial.get() || isDebugMode.get())))

let runMsgBox = @() openMsgBox({
  text = loc("tutorial_open_third_shell_prompt"),
  buttons = [
    {
      text = loc("msgbox/btn_no")
      function cb() {
        markTutorialCompleted(TUTORIAL_ID)
        finishTutorial()
      }
    }
    { text = loc("msgbox/btn_yes"), cb = nextStep, styleId = "PRIMARY", isDefault = true }
  ]
})

function setTutorialBulletsData() {
  let { bulletsOrder = null, bulletSets = null } = bulletsInfo.get()
  if(!bulletsOrder || !bulletSets)
    return
  objectsForSixStep.set(bulletsOrder
    .filter(@(name) (visibleBullets.get()?[name] ?? false)
      && name != curSlotName.get())
        .map(@(name) {
          keys = name
          function onClick() {
            setCurSlot(name)
          }
        })
  )
}

function startTutorial() {
  let unitsListShowEnough = Watched(false)
  setTutorialConfig({
    id = TUTORIAL_ID
    function onStepStatus(stepId, status) {
      logFB($"{stepId}: {status}")
      sendPlayerActivityToServer()
      if (stepId == "s9_change_shell" && status == "tutorial_finished")
        markTutorialCompleted(TUTORIAL_ID)
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
        id = "s2_open_third_shell_prompt"
        beforeStart = runMsgBox
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s3_open_ammo_menu_prompt"
        text = loc("tutorial_open_ammo_menu_prompt")
        charId = "mary_points"
        objects = [{
          keys = $"respBulletsBtn{choiceCount.get() - 1}"
          needArrow = true
        }]
      }
      {
        id = "s4_view_ammo_details"
        function beforeStart() {
          showRespChooseWnd(1, null, null)
          moveModalToTop(WND_UID)
        }
        text = loc("tutorial_view_ammo_details")
        charId = "mary_points"
        nextKeyDelay = 1
        objects = [{ keys = "bulletsInfo" }]
      }
      {
        id = "s5_select_new_shell"
        text = loc("tutorial_select_new_shell")
        objects = objectsForSixStep.get()
      }
      {
        id = "s6_compare_shells"
        text = loc("tutorial_compare_shells")
        nextKeyDelay = 1
        objects = [{ keys = "curBulletInfo" }]
      }
      {
        id = "s7_quick_compare_shells"
        nextKeyDelay = 1
        text = loc("tutorial_quick_compare_shells")
        objects = objectsForSixStep.get().map(@(obj) { keys = $"{obj.keys}_icon" })
      }
      {
        id = "s8_shell_properties"
        nextKeyDelay = 1
        text = loc("tutorial_shell_properties")
        objects = [{
          keys = "bulletsLegend"
          ctor = @(box) lightCtor(box, {
            borderWidth = null
            transform = {
              translate = [0, -(headerMargin[1] + headerMargin[3] + gap)]
            }
            children = bulletsLegend.__update({ fillColor = 0xFF000000 })
          })
        }]
      }
      {
        id = "s9_change_shell"
        text = loc("tutorial_change_shell")
        charId = "mary_like"
        objects = [{
          keys = ["applyButton", "errorButton", "closeButton"]
          onClick = applyBullet
        }]
      }
    ]
  })
}

let startTutorialDelayed = @() deferOnce(function() {
  if (!showTutorial.get())
    return
  setTutorialBulletsData()
  startTutorial()
  isDebugMode.set(false)
})

startTutorialDelayed()
showTutorial.subscribe(@(v) v ? startTutorialDelayed() : null)

register_command(
  @() activeTutorialId.get() != TUTORIAL_ID ? isDebugMode.set(true)
    : finishTutorial(),
  "debug.choosing_shells_ui_tutorial")