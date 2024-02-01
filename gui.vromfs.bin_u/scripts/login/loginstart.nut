from "%scripts/dagui_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { loginState, isLoginStarted, isLoggedIn, LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { authState } = require("authState.nut")
let { isAutologinUsed, isAutologinEnabled } = require("autoLogin.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")

eventbus_subscribe("doLogin", function(authOvr) {
  if (isLoginStarted.value || isOfflineMenu)
    return //just ignore duplicate start

  authState.mutate(@(s) s.__update(authOvr))
  loginState(loginState.value | LOGIN_STATE.LOGIN_STARTED)
})

eventbus_subscribe("login.checkAutoStart", function(_) {
  if (!isAutologinEnabled() || isAutologinUsed.value || isLoginStarted.value || isLoggedIn.value || isOfflineMenu)
    return
  isAutologinUsed(true)
  loginState(loginState.value | LOGIN_STATE.LOGIN_STARTED)
})
