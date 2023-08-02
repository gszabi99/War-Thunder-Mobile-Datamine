from "%globalsDarg/darg_library.nut" import *
let { send, subscribe } = require("eventbus")
let { defer } = require("dagor.workcycle")
let { register_command } = require("console")
let { getPlayerSsoShortTokenAsync, YU2_OK, renewToken, get_player_tags, get_authenticated_url_sso
} = require("auth_wt")
let { json_to_string } = require("json")
let logGuest = log_with_prefix("[GUEST] ")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { authTags, isLoginByGajin } = require("%appGlobals/loginState.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { windowActive } = require("%globalScripts/windowState.nut")

let isGuestLoginBase = Computed(@() authTags.value.contains("guestlogin")
  || authTags.value.contains("firebaselogin"))
let isDebugGuestLogin = mkWatched(persist, "isDebugGuestLogin", false)
let isGuestLogin = Computed(@() isGuestLoginBase.value != isDebugGuestLogin.value)
let needVerifyEmailBase = Computed(@() !isGuestLogin.value
  && !authTags.value.contains("email_verified")
  && !(authTags.value.contains("gplogin") || authTags.value.contains("applelogin") || authTags.value.contains("fblogin")))
let isDebugVerifyEmail = mkWatched(persist, "isDebugVerifyEmail", false)
let needVerifyEmail = Computed(@() needVerifyEmailBase.value != isDebugVerifyEmail.value)
local needCheckRelogin = hardPersistWatched("guest.needCheckRelogin", false)

let openGuestEmailRegistrationImpl = @(stoken) send("openUrl",
  { baseUrl = $"https://login.gaijin.net/{loc("current_lang")}/guest?stoken={stoken}" })

subscribe("onGetStokenForGuestEmail", function(msg) {
  let { status, stoken = null } = msg
  if (status != YU2_OK) {
    logGuest("Error on get SSO token for guewt registration = ", status)
    openFMsgBox({ text = loc("error/serverTemporaryUnavailable") })
  }
  else {
    logGuest("Open guest registration link")
    needCheckRelogin(true)
    openGuestEmailRegistrationImpl(stoken)
  }
})

let function openGuestEmailRegistration() {
  logGuest("getPlayerSsoShortTokenAsync")
  getPlayerSsoShortTokenAsync("onGetStokenForGuestEmail")
}

let function openVerifyEmail() {
  logGuest("Open verify message")
  let url = $"/user.php?skin_lang={loc("current_lang")}"
  get_authenticated_url_sso(url, "", "", "onAuthenticatedUrlResult", json_to_string({ notAuthUrl = url }))
}

subscribeFMsgBtns({
  openGuestEmailRegistration = @(_) openGuestEmailRegistration()
})

windowActive.subscribe(function(v) {
  if (!v || !needCheckRelogin.value)
    return
  needCheckRelogin(false)
  logGuest("Request renew token")
  renewToken("onRenewAuthToken")
})

let function onGuestTagsUpdate() {
  if (isGuestLogin.value)
    return
  isLoginByGajin.update(true)
  openFMsgBox({ text = loc("msg/needToLoginByYourLinkedMail"), isPersist = true })
  defer(@() send("logOutManually", {})) //to avoid call ecs destroy direct from ecs event about window active
}

subscribe("onRenewAuthToken", function(_) {
  authTags(get_player_tags())
  isDebugGuestLogin(false)
  logGuest($"onRenewAuthToken. isGuestLogin = {isGuestLogin.value}, Tags = ", authTags.value)
  onGuestTagsUpdate()
})

subscribe("onRenewGuestAuthTokenInAdvance", function(_) {
  authTags(get_player_tags())
  logGuest($"onRenewGuestAuthTokenInAdvance. isGuestLogin = {isGuestLogin.value}, Tags = ", authTags.value)
  onGuestTagsUpdate()
})

let function renewGuestRegistrationTags() {
  logGuest("Request renew guest token in advance")
  renewToken("onRenewGuestAuthTokenInAdvance")
}

register_command(function() {
    isDebugGuestLogin(!isDebugGuestLogin.value)
    console_print("isGuestLogin = ", isGuestLogin.value) //warning disable: -forbidden-function
  }, "ui.debug.guestLogin")

register_command(function() {
    isDebugVerifyEmail(!isDebugVerifyEmail.value)
    console_print("needVerifyEmail = ", needVerifyEmail.value) //warning disable: -forbidden-function
  }, "ui.debug.verifyEmail")

return {
  isGuestLogin
  openGuestEmailRegistration
  renewGuestRegistrationTags
  needVerifyEmail
  openVerifyEmail
}
