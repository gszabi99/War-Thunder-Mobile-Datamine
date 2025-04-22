from "%scripts/dagui_natives.nut" import get_two_step_code_async2
from "%scripts/dagui_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { isLoginStarted, isLoggedIn, loginState, LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { authState } = require("%scripts/login/authState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

const MAX_GET_2STEP_CODE_ATTEMPTS = 10


let attemptsRequest2step = hardPersistWatched("login.attemptsRequest2step", MAX_GET_2STEP_CODE_ATTEMPTS)
isLoginStarted.subscribe(function(_v) {
  attemptsRequest2step(attemptsRequest2step.value - 1)
  if (attemptsRequest2step.value < 0) 
    attemptsRequest2step(MAX_GET_2STEP_CODE_ATTEMPTS)
})

eventbus_subscribe("StartListenTwoStepCode",
  function(_) {
    if (attemptsRequest2step.value > 0)
      get_two_step_code_async2("ProceedGetTwoStepCode")
  })

let doLogin = @() loginState(loginState.value | LOGIN_STATE.LOGIN_STARTED)

eventbus_subscribe("ProceedGetTwoStepCode", function ProceedGetTwoStepCode(p) {
  if (isLoginStarted.value || isLoggedIn.value)
    return
  let { status, code } = p
  if (status == YU2_TIMEOUT && attemptsRequest2step.value > 0) {
    deferOnce(doLogin)
    return
  }

  if (status != YU2_OK)
    return

  authState.mutate(function(s) {
    s.check2StepAuthCode = true
    s.twoStepAuthCode = code
  })
  deferOnce(doLogin)
})
