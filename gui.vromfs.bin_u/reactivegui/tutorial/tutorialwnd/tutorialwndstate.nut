from "%globalsDarg/darg_library.nut" import *










































let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { get_time_msec } = require("dagor.time")
let { register_command } = require("console")


const WND_UID = "tutorial_wnd"
local tutorialConfig = null

let state = Watched({
  version = 0 
  step = 0
})

let tutorialConfigVersion = Computed(@() state.value.version)
let stepIdx = Computed(@() state.value.step)

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

function tryCallWithRes(action, actionId) {
  local res = null
  try {
    res = action?()
  }
  catch(_) {
    logerr($"Tutorial interrupt by error: {tutorialConfig?.id}/{tutorialConfig?.steps[stepIdx.get()].id ?? stepIdx.get()}/{actionId}")
    tutorialConfig = null
    state.set({ version = state.get().version + 1, step = 0 })
  }
  return res
}

function tryCall(action, actionId) {
  tryCallWithRes(action, actionId)
  return tutorialConfig != null
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

  if (tryCall(tutorialConfig?.steps[0].beforeStart, "beforeStart")) 
    onStepStatus("tutorial_started")
}

let finishTutorial = @() setTutorialConfig(null)

function goToStep(idxOrId) {
  if (tutorialConfig == null)
    return
  let { steps = [] } = tutorialConfig
  let idx = type(idxOrId) == "integer" ? idxOrId
    : (steps.findindex(@(s) s?.id == idxOrId) ?? -1)
  if (!tryCall(steps?[stepIdx.value].onFinish, "onFinish"))
    return

  if (idx in steps) { 
    if (!tryCall(steps?[idx].beforeStart, "beforeStart"))
      return
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
  if (!tryCallWithRes(onNextKey, "onNextKey"))
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
  if (!tryCallWithRes(onSkip, "onSkip"))
    nextStep()
}

register_command(finishTutorial, "tutorial.closeCurrentTutorial")

return {
  isTutorialActive = Computed(@() tutorialConfigVersion.value > 0 && tutorialConfig != null)
  activeTutorialId = Computed(@() tutorialConfigVersion.value > 0 && tutorialConfig != null ? tutorialConfig.id : null)
  tutorialConfigVersion
  getTutorialConfig = @() tutorialConfig != null ? freeze(tutorialConfig) : null
  setTutorialConfig
  stepIdx
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
  WND_UID
}