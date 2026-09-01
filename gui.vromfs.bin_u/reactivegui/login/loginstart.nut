from "%globalsDarg/darg_library.nut" import *
from "app" import exitGame
from "auth_wt" import resetLoginPass, signOut
from "eventbus" import eventbus_subscribe, eventbus_send
from "gameplayBinding" import isInFlight
from "multiplayer" import destroy_session
from "%sqstd/platform.nut" import is_ios, is_android
from "%appGlobals/clientState/initialState.nut" import isOfflineMenu
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride
from "%appGlobals/loginState.nut" import loginState, LOGIN_STATE, isLoggedIn, curLoginType, authTags, isLoginStarted,
  needLogoutAfterSession
from "%rGui/bqQueue.nut" import forceSendBqQueue
from "%appGlobals/openForeignMsgBox.nut" import subscribeFMsgBtns
import "%appGlobals/clientState/callbackWhenAppWillActive.nut" as callbackWhenAppWillActive
from "guiScriptUtils" import disable_network
from "%appGlobals/util.nut" import is_multiplayer
from "authState.nut" import authState
from "autoLogin.nut" import isAutologinUsed, setAutologinEnabled, isAutologinEnabled


let openUrl = @(baseUrl) eventbus_send("openUrl", { baseUrl })

let { logoutFB = @() null } = is_ios ? require("ios.account.facebook")
      : is_android ? require("android.account.fb")
      : {}


const DELETE_ACCOUNT_URL = "auto_local auto_login https://store.gaijin.net/login.php?return_enc=L3Byb2ZpbGUucGhwP3Byb2ZpbGVTZXR0aW5ncz1wcm9maWxlLXNldHRpbmdzX2RlbGV0ZSZ2aWV3PXNldHRpbmdz"

let canLogout = @() !disable_network()

function startLogout() {
  logoutFB()
  if (loginState.get() == LOGIN_STATE.NOT_LOGGED_IN)
    return
  forceSendBqQueue()
  if (!canLogout())
    return exitGame()

  if (is_multiplayer()) { 
    if (isInFlight()) {
      needLogoutAfterSession.set(true)
      eventbus_send("quitMission", null)
      return
    }
    else
      destroy_session("on startLogout")
  }

  log("Start Logout")
  needLogoutAfterSession.set(false)

  if (isLoggedIn.get()) {
    loginState.set(LOGIN_STATE.NOT_LOGGED_IN)
    curLoginType.set("")
    authTags.set([])
    signOut()
  }
  else
    eventbus_send("login.interrupt", {})
  eventbus_send("gui_start_startscreen")
}

function checkAutoStartLogin() {
  if (!isAutologinEnabled() || isAutologinUsed.get() || isLoginStarted.get() || isLoggedIn.get() || isOfflineMenu)
    return
  isAutologinUsed.set(true)
  loginState.set(loginState.get() | LOGIN_STATE.LOGIN_STARTED)
}

function startRelogin() {
  let wasLoggedIn = loginState.get() != LOGIN_STATE.NOT_LOGGED_IN
  isAutologinUsed.set(false)
  if (wasLoggedIn)
    startLogout()
  else
    checkAutoStartLogin()
}

eventbus_subscribe("doLogin", function(authOvr) {
  if (isLoginStarted.get() || isOfflineMenu)
    return 

  authState.mutate(@(s) s.__update(authOvr))
  loginState.set(loginState.get() | LOGIN_STATE.LOGIN_STARTED)
})

eventbus_subscribe("login.checkAutoStart", @(_) checkAutoStartLogin())


eventbus_subscribe("login.startRelogin", @(_) startRelogin())

eventbus_subscribe("logOutManually", function(_) {
  resetLoginPass()
  eventbus_send("authState.reset", {})
  setAutologinEnabled(false)
  startLogout()
})
eventbus_subscribe("logOut", @(_) startLogout())

eventbus_subscribe("changeName", function(_) {
  openUrl(getCurCircuitOverride("changeNameURL",loc("url/changeName")))
  callbackWhenAppWillActive(@() eventbus_send("logOut", {}))
})

eventbus_subscribe("deleteAccount", function(_) {
  openUrl(getCurCircuitOverride("deleteAccountURL", DELETE_ACCOUNT_URL))
  callbackWhenAppWillActive(@() eventbus_send("logOut", {}))
})

subscribeFMsgBtns({
  function onLostPsnOk(_) {
    destroy_session("after 'on lost psn' message")
    startLogout()
  }
})
