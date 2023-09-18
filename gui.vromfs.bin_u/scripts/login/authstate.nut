
from "%scripts/dagui_library.nut" import *
let { send, subscribe } = require("eventbus")
let { LT_GAIJIN } = require("%appGlobals/loginState.nut")
let { getAutologinType } = require("autoLogin.nut")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let authState = hardPersistWatched("login.authState", {
  loginType = LT_GAIJIN
  loginName = ""
  loginPas = ""
  twoStepAuthCode = ""
  check2StepAuthCode = false
  email2step = false
})

let sendState = @(v) send("updateAuthStates", v)
authState.subscribe(@(v) send("updateAuthStates", v))

let function resetAuthState() {
  if (isInLoadingScreen.value) //app may be not inited
    return

  let lp = ::get_login_pass()
  authState.mutate(function(s) {
    s.loginType = getAutologinType()
    s.loginName = lp.login
    s.loginPas = lp.password
    s.check2StepAuthCode = false
    s.email2step = false
  })
}

subscribe("authState.reset", @(_) resetAuthState())
subscribe("authState.request", function(_) {
  let { loginName, loginPas } = authState.value
  if (loginName == "" && loginPas == "")
    resetAuthState()
  else
    sendState(authState.value)
})

return {
  authState
  resetAuthState
}