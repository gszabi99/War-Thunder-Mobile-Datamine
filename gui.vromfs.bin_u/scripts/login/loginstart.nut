//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { subscribe } = require("eventbus")
let { loginState, isLoginStarted, isLoggedIn, LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { authState } = require("authState.nut")
let { isAutologinUsed, isAutologinEnabled } = require("autoLogin.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")

subscribe("doLogin", function(authOvr) {
  if (isLoginStarted.value || isOfflineMenu)
    return //just ignore duplicate start

  authState.mutate(@(s) s.__update(authOvr))
  loginState(loginState.value | LOGIN_STATE.LOGIN_STARTED)
})

subscribe("login.checkAutoStart", function(_) {
  if (!isAutologinEnabled() || isAutologinUsed.value || isLoginStarted.value || isLoggedIn.value || isOfflineMenu)
    return
  isAutologinUsed(true)
  loginState(loginState.value | LOGIN_STATE.LOGIN_STARTED)
})

//this method called after scripts hard reload while login in progress, so we know on which stage we are already.
::gui_start_after_scripts_reload <- @() null
