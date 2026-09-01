from "%globalScripts/yuplay2Consts.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "auth_wt" import getTwoStepCodeAsync2
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_subscribe
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/loginState.nut" import isLoginStarted, isLoggedIn, loginState, LOGIN_STATE
from "%rGui/login/authState.nut" import authState


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
