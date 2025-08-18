from "%scripts/dagui_natives.nut" import get_login_pass

from "%scripts/dagui_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { LT_GAIJIN, SST_UNKNOWN } = require("%appGlobals/loginState.nut")
let { getAutologinType } = require("autoLogin.nut")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let authState = hardPersistWatched("login.authState", {
  loginType = LT_GAIJIN
  loginName = ""
  loginPas = ""
  twoStepAuthCode = ""
  check2StepAuthCode = false
  secStepType = SST_UNKNOWN
})

let sendState = @(v) eventbus_send("updateAuthStates", v)
authState.subscribe(@(v) eventbus_send("updateAuthStates", v))

function resetAuthState() {
  if (isInLoadingScreen.get()) 
    return

  let lp = get_login_pass()
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