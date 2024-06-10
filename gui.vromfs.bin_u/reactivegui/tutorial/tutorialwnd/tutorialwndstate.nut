from "%globalsDarg/darg_library.nut" import *

/*
Tutoral config:
{
  id : string //for big query
  stepSkipDelay : float //3sec by default
  nextStepDelay : float = 0.5 //delay before you can do next step by click light block. Work only when block dont have onClick action
  state : table //tutorial state, can be modified by tutoral actions.
  style : table //custom style
  onStepStatus : function(stepId, status) //called on each step status change

  steps : array -> [
    {
      id : string //for big query, and unordered move to step
      text : string //or Watched(string)
      textCtor : function(text) //custom creator for text
      nextKeyDelay : float  //when not set can't next by any key. When < 0 will be calculated by text length.
      skipKeyDelay : float //when not set = nextKeyDelay + 1 sec. If nextKeyDelay also not set, will be SKIP_DELAY.
      beforeStart : function(state) //action before start
      onFinish : function(state) //action on step finish, after object action.
      onNextKey : function(state) //when function not set, will be used function from the first object
      onSkip : function(state) //called only when step skipped. if null, will be called onNextKey instead
      nextStepAfter : Watched(bool) //next step will start automatically when watch become true.
                            //if watch already true on the step start, step will be skipped
      arrowLinks : [[from1, to1], [from2, to2], ...] //from* and to* are indexes in objects
      objects : array -> [
        {
          keys : anytype //all types except of listed below - is object key to highlight
                         //array of keys to higlight group. Will combine them all to single box.
                         //function which return key or array of keys to highlight
                         //Observable which value is key or array of keys to highlight
          onClick : function(state) //action onClick. If return true, next step will be not called
          hotkey : string //custom hotkey to activate this onClickAction
          sizeIncAdd : int //higlight size increase. Default value = 0
          ctor : function(box) //custom creator for this box
          needArrow : bool //show pointer arrow to this object if it not zero size.
        }
      ]
    }
  ]
}
*/

let utf8 = require("utf8")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { get_time_msec } = require("dagor.time")
let { register_command } = require("console")
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")

const WND_UID = "tutorial_wnd"
const SKIP_DELAY_DEFAULT = 3.0
const SKIP_DELAY_AFTER_NEXT_KEY = 2.0
local tutorialConfig = null

let state = Watched({
  version = 0 //to subscribe on config changes
  step = 0
})
let tutorialConfigVersion = Computed(@() state.value.version)
let stepIdx = Computed(@() state.value.step)
let nextKeyAllowed = Watched(false)
let skipKeyAllowed = Watched(false)
local stepStartTime = 0
state.subscribe(function(_) { stepStartTime = get_time_msec() })

let sendCurStepBq = @(status) "id" not in tutorialConfig ? null
  : sendUiBqEvent("ui_tutorial", {
      id = tutorialConfig.id
      step = tutorialConfig?.steps[stepIdx.value].id ?? stepIdx.value
      status = status
    })

function onStepStatus(status) {
  sendCurStepBq(status)
  tutorialConfig?.onStepStatus(tutorialConfig?.steps[stepIdx.value].id ?? stepIdx.value, status)
}

function setTutorialConfig(config) {
  if (config != null && tutorialConfig != null) {
    logerr($"Try to start tutorial '{config?.id}' while other tutorial in progress '{tutorialConfig?.id}'")
    return
  }
  onStepStatus("tutorial_finished")

  tutorialConfig = config
  state({
    version = state.value.version + 1
    step = 0
  })
  tutorialConfig?.steps[0].beforeStart() //only for debug purpose, when start from the middle of the tutorial.

  onStepStatus("tutorial_started")
}

let finishTutorial = @() setTutorialConfig(null)

function saveResultTutorial(id) {
  let blk = get_local_custom_settings_blk()
  blk.addBlock("tutorials")[id] = true
  eventbus_send("saveProfile", {})
}

function goToStep(idxOrId) {
  if (tutorialConfig == null)
    return
  let { steps = [] } = tutorialConfig
  let idx = type(idxOrId) == "integer" ? idxOrId
    : (steps.findindex(@(s) s?.id == idxOrId) ?? -1)
  steps?[stepIdx.value].onFinish()

  if (idx in steps) { // waring disable: -in-instead-contains
    steps?[idx].beforeStart()
    state.mutate(@(s) s.step <- idx)
    return
  }

  if (idx != idxOrId)
    logerr($"Try to move to not exist tutorial step '{idxOrId}' in the tutorial '{tutorialConfig?.id}'. Finalize tutorial.")
  finishTutorial()
}

let nextStep = @() goToStep(stepIdx.value + 1)

function skipStepImpl() {
  let step = tutorialConfig?.steps[stepIdx.value]
  let onNextKey = step?.onNextKey ?? step?.objects[0].onClick
  if (!onNextKey?())
    nextStep()
}

function nextStepByDefaultHotkey() {
  onStepStatus("step_success")
  skipStepImpl()
}

function skipStep() {
  onStepStatus("skip_step")
  let step = tutorialConfig?.steps[stepIdx.value]
  let onSkip = step?.onSkip ?? step?.onNextKey ?? step?.objects[0].onClick
  if (!onSkip?())
    nextStep()
}

let calcNextDelayByText = @(text)
  clamp(0.03 * utf8(text).charCount(), 1.0, 5.0)

let allowNextKey = @() nextKeyAllowed(true)
let allowSkipKey = @() skipKeyAllowed(true)
function updateNextKeyTimer() {
  local { nextKeyDelay = null, skipKeyDelay = null, text = "" } = tutorialConfig?.steps[stepIdx.value]
  gui_scene.clearTimer(allowNextKey)
  gui_scene.clearTimer(allowSkipKey)
  skipKeyAllowed(false)

  if (nextKeyDelay == null) {
    nextKeyAllowed(false)
    gui_scene.setTimeout(skipKeyDelay ?? SKIP_DELAY_DEFAULT, allowSkipKey)
    return
  }

  if (nextKeyDelay < 0)
    nextKeyDelay = calcNextDelayByText(text instanceof Watched ? text.value : text)

  if (nextKeyDelay == 0) {
    nextKeyAllowed(true)
    gui_scene.setTimeout(skipKeyDelay ?? SKIP_DELAY_DEFAULT, allowSkipKey)
  }
  else {
    nextKeyAllowed(false)
    gui_scene.setTimeout(nextKeyDelay, allowNextKey)
    gui_scene.setTimeout(skipKeyDelay ?? (nextKeyDelay + SKIP_DELAY_AFTER_NEXT_KEY), allowSkipKey)
  }
}
state.subscribe(@(_) updateNextKeyTimer())


register_command(finishTutorial, "tutorial.closeCurrentTutorial")

return {
  isTutorialActive = Computed(@() tutorialConfigVersion.value > 0 && tutorialConfig != null)
  activeTutorialId = Computed(@() tutorialConfigVersion.value > 0 && tutorialConfig != null ? tutorialConfig.id : null)
  tutorialConfigVersion
  getTutorialConfig = @() tutorialConfig != null ? freeze(tutorialConfig) : null
  setTutorialConfig
  stepIdx
  nextKeyAllowed
  skipKeyAllowed
  goToStep = function(idxOrId) {
    onStepStatus("step_success")
    goToStep(idxOrId)
  }
  nextStep = function() {
    onStepStatus("step_success")
    nextStep()
  }
  nextStepByDefaultHotkey
  skipStep
  finishTutorial
  getTimeAfterStepStart = @() 0.001 * (get_time_msec() - stepStartTime)
  saveResultTutorial
  WND_UID
}