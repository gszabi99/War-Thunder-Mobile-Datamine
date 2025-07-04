from "%scripts/dagui_natives.nut" import sign_out
from "%scripts/dagui_library.nut" import *
from "gameplayBinding" import pause_game

let { registerRespondent } = require("scriptRespondent")
let { eventbus_subscribe } = require("eventbus")
let { broadcastEvent } = require("%sqStdLibs/helpers/subscriptions.nut")
let { deferOnce } = require("dagor.workcycle")
let { loginState, isLoginStarted, LOGIN_STATE, getLoginStateDebugStr, isLoggedIn, isAuthAndUpdated, isAuthorized
} = require("%appGlobals/loginState.nut")
let updateClientStates = require("%scripts/clientState/updateClientStates.nut")

let logerrL = @(text) logerr($"[LOGIN] {text}")

local curStages = []

let isNeedUpdateStages = @(state) (state & LOGIN_STATE.LOGIN_STARTED) != 0
  && curStages.len() > 0

let isStageCompleted = @(state, stage) (state & stage.finishState) == stage.finishState
let isStageAllowed = @(state, stage) (state & stage.reqState) == stage.reqState

local prevState = loginState.value
function startNextLoginStages() {
  let state = loginState.value
  let wasState = prevState
  prevState = state
  if (isNeedUpdateStages(state))
    foreach (stage in curStages)
      if ("start" in stage
        && !isStageCompleted(state, stage)
        && isStageAllowed(state, stage)
        && !isStageAllowed(wasState, stage)
      ) {
        stage.logStage("Start")
        stage.start()
        if (loginState.value == LOGIN_STATE.NOT_LOGGED_IN) {
          stage.logStage("login process was interrupted right from stage start")
          break
        }
      }
}
loginState.subscribe(function(s) {
  if (s == LOGIN_STATE.NOT_LOGGED_IN)
    prevState = s 
  deferOnce(startNextLoginStages)
})

function restartLoginStages() { 
  let state = loginState.value
  if (!isNeedUpdateStages(state))
    return
  foreach (stage in curStages)
    if ("restart" in stage
      && !isStageCompleted(state, stage)
      && isStageAllowed(state, stage)
    ) {
      stage.logStage("Restart")
      stage.restart()
    }
}

eventbus_subscribe("login.interrupt", function(_errData) {
  let state = loginState.value
  foreach (stage in curStages)
    if ("interrupt" in stage
      && !isStageCompleted(state, stage)
      && isStageAllowed(state, stage)
    ) {
      stage.logStage("Interrupt")
      stage.interrupt()
    }
  let wasAuthorized = isAuthorized.value
  loginState(LOGIN_STATE.NOT_LOGGED_IN)
  if (wasAuthorized)
    sign_out()
})

function getStagesErrors(stages) {
  let errors = []
  let ids = {}
  foreach (s in stages) {
    let { id } = s
    if (id in ids)
      errors.append($"Duplicate stage '{id}'")
    ids[id] <- true
  }

  local state = LOGIN_STATE.LOGIN_STARTED
  local hasChanges = true
  let leftStages = clone stages
  while (leftStages.len() > 0 && hasChanges) {
    hasChanges = false
    for (local idx = leftStages.len() - 1; idx >= 0; idx--) {
      let { id, reqState, finishState } = leftStages[idx]
      if ((state & reqState) != reqState)
        continue
      let duplicate = state & finishState
      if (duplicate != 0)
        errors.append($"Stage '{id}' has already used finishState: {getLoginStateDebugStr(duplicate)}")
      state = state | finishState
      leftStages.remove(idx)
      hasChanges = true
    }
  }

  leftStages.each(@(s) errors.append($"Stage '{s.id}' can't activate because no stages to set requirements."))
  if ((state & LOGIN_STATE.LOGGED_IN) != LOGIN_STATE.LOGGED_IN) {
    let missState = getLoginStateDebugStr(LOGIN_STATE.LOGGED_IN & ~state)
    errors.append($"Login stages incomplete. Require to set also {missState}")
  }

  return errors
}

function initStages(stages) {
  if (curStages.len() > 0 && isLoginStarted.value) {
    logerrL("Try to change login stages while in the active login process!")
    return
  }
  let errors = getStagesErrors(stages)
  if (errors.len() > 0) {
    errors.each(@(e) logerrL(e))
    return
  }
  curStages = stages
  deferOnce(restartLoginStages) 
}

isAuthAndUpdated.subscribe(function(v) {
  if (!v)
    broadcastEvent("SignOut") 
})

isLoggedIn.subscribe(function(v) {
  if (v)
    broadcastEvent("LoginComplete")  
})

registerRespondent("is_logged_in", @() isLoggedIn.get())

eventbus_subscribe("gui_start_startscreen", function gui_start_startscreen(...) {
  pause_game(false) 
  deferOnce(updateClientStates)
})

return {
  initStages
}