//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let needLogoutAfterSession = persist("needLogoutAfterSession", @() Watched(false))
let { isOnlineSettingsAvailable, loginState, LOGIN_STATE, isLoggedIn } = require("%appGlobals/loginState.nut")
let { subscribe, send } = require("eventbus")
let { openUrl } = require("%scripts/url.nut")
let callbackWhenAppWillActive = require("%scripts/clientState/callbackWhenAppWillActive.nut")
let { shouldDisableMenu } = require("%appGlobals/clientState/initialState.nut")
let { isAutologinUsed, setAutologinEnabled } = require("autoLogin.nut")
let { resetLoginPass } = require("auth_wt")

let canLogout = @() !::disable_network()

let function startLogout() {
  if (loginState.value == LOGIN_STATE.NOT_LOGGED_IN)
    return
  if (!canLogout())
    return ::exit_game()

  if (::is_multiplayer()) { //we cant logout from session instantly, so need to return "to debriefing"
    if (::is_in_flight()) {
      needLogoutAfterSession(true)
      send("quitMission", null)
      return
    }
    else
      ::destroy_session()
  }

  if (shouldDisableMenu || isOnlineSettingsAvailable.value)
    ::broadcastEvent("BeforeProfileInvalidation") // Here save any data into profile.

  log("Start Logout")
  needLogoutAfterSession(false)

  if (isLoggedIn.value) {
    loginState(LOGIN_STATE.NOT_LOGGED_IN)
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
  callbackWhenAppWillActive(startLogout)
})

return {
  canLogout = canLogout
  startLogout = startLogout
  needLogoutAfterSession = needLogoutAfterSession
}