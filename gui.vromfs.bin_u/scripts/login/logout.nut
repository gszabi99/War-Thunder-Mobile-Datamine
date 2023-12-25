from "%scripts/dagui_library.nut" import *
let { subscribeFMsgBtns } = require("%appGlobals/openForeignMsgBox.nut")
let { is_multiplayer } = require("%scripts/util.nut")
let { broadcastEvent } = require("%sqStdLibs/helpers/subscriptions.nut")
let { destroy_session } = require("multiplayer")
let { isOnlineSettingsAvailable, loginState, LOGIN_STATE, isLoggedIn, curLoginType, authTags
} = require("%appGlobals/loginState.nut")
let { subscribe, send } = require("eventbus")
let { openUrl } = require("%scripts/url.nut")
let callbackWhenAppWillActive = require("%scripts/clientState/callbackWhenAppWillActive.nut")
let { shouldDisableMenu } = require("%appGlobals/clientState/initialState.nut")
let { isAutologinUsed, setAutologinEnabled } = require("autoLogin.nut")
let { resetLoginPass } = require("auth_wt")
let { forceSendBqQueue } = require("%scripts/bqQueue.nut")
let { isInFlight } = require("gameplayBinding")
let { is_ios, is_android } = require("%appGlobals/clientState/platform.nut")
let { logoutFB = @() null } = is_ios ? require("ios.account.facebook")
      : is_android ? require("android.account.fb")
      : {}

// Here "return_enc" is Base64 encoded string: "/profile.php?profileSettings=profile-settings_delete&view=settings"
let DELETE_ACCOUNT_URL = "auto_local auto_login https://store.gaijin.net/login.php?return_enc=L3Byb2ZpbGUucGhwP3Byb2ZpbGVTZXR0aW5ncz1wcm9maWxlLXNldHRpbmdzX2RlbGV0ZSZ2aWV3PXNldHRpbmdz"

let needLogoutAfterSession = mkWatched(persist, "needLogoutAfterSession", false)

let canLogout = @() !::disable_network()

let function startLogout() {
  logoutFB()
  if (loginState.value == LOGIN_STATE.NOT_LOGGED_IN)
    return
  forceSendBqQueue()
  if (!canLogout())
    return ::exit_game()

  if (is_multiplayer()) { //we cant logout from session instantly, so need to return "to debriefing"
    if (isInFlight()) {
      needLogoutAfterSession(true)
      send("quitMission", null)
      return
    }
    else
      destroy_session("on startLogout")
  }

  if (shouldDisableMenu || isOnlineSettingsAvailable.value)
    broadcastEvent("BeforeProfileInvalidation") // Here save any data into profile.

  log("Start Logout")
  needLogoutAfterSession(false)

  if (isLoggedIn.value) {
    loginState(LOGIN_STATE.NOT_LOGGED_IN)
    curLoginType("")
    authTags([])
    ::sign_out()
  }
  else
    send("login.interrupt", {})
  ::gui_start_startscreen()
}

subscribe("logOutManually", function(_) {
  resetLoginPass()
  send("authState.reset", {})
  setAutologinEnabled(false)
  startLogout()
})
subscribe("logOut", @(_) startLogout())
subscribe("relogin", function(_) {
  isAutologinUsed(false)
  startLogout()
})

subscribe("changeName", function(_) {
  openUrl(loc("url/changeName"))
  callbackWhenAppWillActive("logOut")
})

subscribe("deleteAccount", function(_) {
  openUrl(DELETE_ACCOUNT_URL)
  callbackWhenAppWillActive("logOut")
})

subscribeFMsgBtns({
  function onLostPsnOk(_) {
    destroy_session("after 'on lost psn' message")
    startLogout()
  }
})

return {
  canLogout = canLogout
  startLogout = startLogout
  needLogoutAfterSession = needLogoutAfterSession
}