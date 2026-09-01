from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.workcycle" import deferOnce, resetTimeout
from "%appGlobals/clientState/initialState.nut" import shouldDisableMenu
from "%appGlobals/clientState/respawnStateBase.nut" import isInRespawn, isRespawnStarted, respawnsLeft,
  respawnsTotalInitial
from "%appGlobals/squadState.nut" import isInSquad
from "%rGui/bullets/bulletsConst.nut" import BS_UNLOCKED
from "%rGui/components/modalWindows.nut" import MWP_ALWAYS_TOP
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/respawn/bulletsChoiceState.nut" import chosenBullets, bulletsStatus
from "%rGui/respawn/playerActivity.nut" import sendPlayerActivityToServer
from "%rGui/respawn/respawnChooseBulletWnd.nut" import showRespChooseWnd, curSlotName, applyBullet
from "%rGui/respawn/respawnComps.nut" import bulletsLegend, headerMargin, gap
from "%rGui/respawn/respawnState.nut" import selSlot, respawnSlots
from "%rGui/tutorial/completedTutorials.nut" import markTutorialCompleted, mkIsTutorialCompleted
from "%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut" import lightCtor
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import setTutorialConfig, isTutorialActive, finishTutorial,
  activeTutorialId, nextStep


let logFB = log_with_prefix("[FIRST_BATTLE_TUTOR] ")

const TUTORIAL_ID = "choosingShells"

let isFakeUnit = Computed(@() selSlot.get()?.isFake ?? false)
let choiceCount = Computed(@() chosenBullets.get().len())
let setCurSlot = @(name) curSlotName.set(name)

let isFinished = mkIsTutorialCompleted(TUTORIAL_ID)
let isDebugMode = mkWatched(persist, "isDebugMode", false)
let allowedBullets = Computed(@() choiceCount.get() > 1
  ? bulletsStatus.get().filter(@(s) (s & BS_UNLOCKED) != 0)
  : {})
let hasEnoughBullets = Computed(@() allowedBullets.get().len() >= 3)
let needShowTutorial = Computed(@() hasEnoughBullets.get()
  && !isFakeUnit.get()
  && !isInSquad.get()
  && !isFinished.get())
let canStartTutorial = shouldDisableMenu ? Watched(false)
  : Computed(@() !isTutorialActive.get()
      && !isRespawnStarted.get()
      && respawnSlots.get().len() > 1
      && isInRespawn.get()
      && selSlot.get()?.name != null
      && respawnsLeft.get() == respawnsTotalInitial.get())
let showTutorial = keepref(Computed(@() canStartTutorial.get()
  && (needShowTutorial.get() || isDebugMode.get())))

let runMsgBox = @() openMsgBox({
  modalPriority = MWP_ALWAYS_TOP
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

function startTutorial() {
  let unitsListShowEnough = Watched(false)
  let allowedBulletsForChoose = allowedBullets.get()
    .filter(@(_, name) name != curSlotName.get())
    .map(@(_, name) {
      keys = name
      function onClick() {
        setCurSlot(name)
      }
    })
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
        }
        text = loc("tutorial_view_ammo_details")
        charId = "mary_points"
        hasNextKey = true
        objects = [{ keys = "bulletsInfo" }]
      }
      {
        id = "s5_select_new_shell"
        text = loc("tutorial_select_new_shell")
        objects = allowedBulletsForChoose
      }
      {
        id = "s6_compare_shells"
        text = loc("tutorial_compare_shells")
        hasNextKey = true
        objects = [{ keys = "curBulletInfo" }]
      }
      {
        id = "s7_quick_compare_shells"
        hasNextKey = true
        text = loc("tutorial_quick_compare_shells")
        objects = allowedBulletsForChoose.map(@(obj) { keys = $"{obj.keys}_icon" })
      }
      {
        id = "s8_shell_properties"
        hasNextKey = true
        text = loc("tutorial_shell_properties")
        objects = [{
          keys = "bulletsLegend"
          ctor = @(box) lightCtor(box, {
            borderWidth = null
            transform = {
              translate = [0, -(headerMargin[1] + headerMargin[3] + gap)]
            }
            children = bulletsLegend.__merge({ fillColor = 0xFF000000 })
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
  startTutorial()
  isDebugMode.set(false)
})

startTutorialDelayed()
showTutorial.subscribe(@(v) v ? startTutorialDelayed() : null)

register_command(
  @() activeTutorialId.get() != TUTORIAL_ID ? isDebugMode.set(true)
    : finishTutorial(),
  "debug.tutorial_choosing_shells")