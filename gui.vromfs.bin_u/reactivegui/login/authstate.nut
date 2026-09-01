from "%globalsDarg/darg_library.nut" import *
from "auth_wt" import getLoginPass
from "eventbus" import eventbus_send, eventbus_subscribe
from "%appGlobals/clientState/clientState.nut" import isInLoadingScreen
from "%appGlobals/loginState.nut" import SST_UNKNOWN, authState
from "autoLogin.nut" import getAutologinType

let sendState = @(v) eventbus_send("updateAuthStates", v)
authState.subscribe(@(v) eventbus_send("updateAuthStates", v))

function resetAuthState() {
  if (isInLoadingScreen.get()) 
    return

  let lp = getLoginPass()
  authState.mutate(function(s) {
    s.loginType = getAutologinType()
    s.loginName = lp.login
    s.loginPas = lp.password
    s.check2StepAuthCode = false
    s.secStepType = SST_UNKNOWN
  })
}

eventbus_subscribe("authState.reset", @(_) resetAuthState())
eventbus_subscribe("authState.request", function(_) {
  let { loginName, loginPas } = authState.get()
  if (loginName == "" && loginPas == "")
    resetAuthState()
  else
    sendState(authState.get())
})

return {
  authState
  resetAuthState
}