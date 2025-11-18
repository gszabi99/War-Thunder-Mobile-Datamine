from "%scripts/dagui_natives.nut" import disable_network
from "app" import exitGame
from "%scripts/dagui_library.nut" import *
let { subscribeFMsgBtns } = require("%appGlobals/openForeignMsgBox.nut")
let { is_multiplayer } = require("%scripts/util.nut")
let { broadcastEvent } = require("%sqStdLibs/helpers/subscriptions.nut")
let { destroy_session } = require("multiplayer")
let { isOnlineSettingsAvailable, loginState, LOGIN_STATE, isLoggedIn, curLoginType, authTags, isLoginStarted
} = require("%appGlobals/loginState.nut")
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { openUrl } = require("%scripts/url.nut")
let callbackWhenAppWillActive = require("%scripts/clientState/callbackWhenAppWillActive.nut")
let { shouldDisableMenu, isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { isAutologinUsed, setAutologinEnabled, isAutologinEnabled } = require("autoLogin.nut")
let { resetLoginPass, signOut } = require("auth_wt")
let { forceSendBqQueue } = require("%scripts/bqQueue.nut")
let { isInFlight } = require("gameplayBinding")
let { is_ios, is_android } = require("%appGlobals/clientState/platform.nut")
let { logoutFB = @() null } = is_ios ? require("ios.account.facebook")
      : is_android ? require("android.account.fb")
      : {}
let { authState } = require("authState.nut")


let DELETE_ACCOUNT_URL = "auto_local auto_login https://store.gaijin.net/login.php?return_enc=L3Byb2ZpbGUucGhwP3Byb2ZpbGVTZXR0aW5ncz1wcm9maWxlLXNldHRpbmdzX2RlbGV0ZSZ2aWV3PXNldHRpbmdz"

let needLogoutAfterSession = mkWatched(persist, "needLogoutAfterSession", false)

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

  if (shouldDisableMenu || isOnlineSettingsAvailable.get())
    broadcastEvent("BeforeProfileInvalidation") 

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

eventbus_subscribe("logOutManually", function(_) {
  resetLoginPass()
  eventbus_send("authState.reset", {})
  setAutologinEnabled(false)
  startLogout()
})
eventbus_subscribe("logOut", @(_) startLogout())
eventbus_subscribe("relogin", @(_) startRelogin())

eventbus_subscribe("changeName", function(_) {
  openUrl(loc("url/changeName"))
  callbackWhenAppWillActive(@() eventbus_send("logOut", {}))
})

eventbus_subscribe("deleteAccount", function(_) {
  openUrl(DELETE_ACCOUNT_URL)
  callbackWhenAppWillActive(@() eventbus_send("logOut", {}))
})

subscribeFMsgBtns({
  function onLostPsnOk(_) {
    destroy_session("after 'on lost psn' message")
    startLogout()
  }
})

return {
  canLogout
  startLogout
  startRelogin
  needLogoutAfterSession
}