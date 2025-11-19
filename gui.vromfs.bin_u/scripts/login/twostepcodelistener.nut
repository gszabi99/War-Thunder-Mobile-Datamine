from "%scripts/dagui_library.nut" import *

let { getTwoStepCodeAsync2 } = require("auth_wt")
let { eventbus_subscribe } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { isLoginStarted, isLoggedIn, loginState, LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { authState } = require("%scripts/login/authState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

const MAX_GET_2STEP_CODE_ATTEMPTS = 10


let attemptsRequest2step = hardPersistWatched("login.attemptsRequest2step", MAX_GET_2STEP_CODE_ATTEMPTS)
isLoginStarted.subscribe(function(_v) {
  attemptsRequest2step.set(attemptsRequest2step.get() - 1)
  if (attemptsRequest2step.get() < 0) 
    attemptsRequest2step.set(MAX_GET_2STEP_CODE_ATTEMPTS)
})

eventbus_subscribe("StartListenTwoStepCode",
  function(_) {
    if (attemptsRequest2step.get() > 0)
      getTwoStepCodeAsync2("ProceedGetTwoStepCode")
  })

let doLogin = @() loginState.set(loginState.get() | LOGIN_STATE.LOGIN_STARTED)

eventbus_subscribe("ProceedGetTwoStepCode", function ProceedGetTwoStepCode(p) {
  if (isLoginStarted.get() || isLoggedIn.get())
    return
  let { status, code } = p
  if (status == YU2_TIMEOUT && attemptsRequest2step.get() > 0) {
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
