from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { defer } = require("dagor.workcycle")
let { register_command } = require("console")
let { getPlayerSsoShortTokenAsync, YU2_OK, renewToken, get_player_tags, get_authenticated_url_sso
} = require("auth_wt")
let { object_to_json_string } = require("json")
let logGuest = log_with_prefix("[GUEST] ")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { authTags, isLoginByGajin } = require("%appGlobals/loginState.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { windowActive } = require("%appGlobals/windowState.nut")
let { accountLink } = require("%rGui/contacts/contactLists.nut")
let { isContactsReceived } = require("%rGui/contacts/contactsState.nut")
let { LINK_TO_GAIJIN_ACCOUNT_URL } = require("%appGlobals/commonUrl.nut")


let isGuestLoginBase = Computed(@() authTags.value.contains("guestlogin")
  || authTags.value.contains("firebaselogin"))
let isDebugGuestLogin = mkWatched(persist, "isDebugGuestLogin", false)
let isGuestLogin = Computed(@() isGuestLoginBase.value != isDebugGuestLogin.value)
let needVerifyEmailBase = Computed(@() !isGuestLogin.value
  && isContactsReceived.get()
  && accountLink.get() == null
  && !authTags.value.contains("email_verified")
  && !(authTags.value.contains("gplogin") || authTags.value.contains("applelogin")
        || authTags.value.contains("fblogin") || authTags.value.contains("hwlogin")))
let isDebugVerifyEmail = mkWatched(persist, "isDebugVerifyEmail", false)
let needVerifyEmail = Computed(@() needVerifyEmailBase.value != isDebugVerifyEmail.value)
local needCheckRelogin = hardPersistWatched("guest.needCheckRelogin", false)

let openGuestEmailRegistrationImpl = @(stoken) eventbus_send("openUrl",
  { baseUrl = $"https://login.gaijin.net/{loc("current_lang")}/guest?stoken={stoken}" })

eventbus_subscribe("onGetStokenForGuestEmail", function(msg) {
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

function openGuestEmailRegistration() {
  logGuest("getPlayerSsoShortTokenAsync")
  getPlayerSsoShortTokenAsync("onGetStokenForGuestEmail")
}

function linkEmailWithLogout() {
  eventbus_send("openUrl", { baseUrl = LINK_TO_GAIJIN_ACCOUNT_URL })
  defer(@() eventbus_send("logOutManually", {}))
}

function openVerifyEmail() {
  logGuest("Open verify message")
  let url = $"https://store.gaijin.net/user.php?skin_lang={loc("current_lang")}"
  get_authenticated_url_sso(url, "", "", "onAuthenticatedUrlResult", object_to_json_string({ notAuthUrl = url }))
}

subscribeFMsgBtns({
  openGuestEmailRegistration = @(_) openGuestEmailRegistration()
  linkEmailWithLogout = @(_) linkEmailWithLogout()
})

windowActive.subscribe(function(v) {
  if (!v || !needCheckRelogin.value)
    return
  needCheckRelogin(false)
  logGuest("Request renew token")
  renewToken("onRenewAuthToken")
})

function onGuestTagsUpdate() {
  if (!authTags.get().contains("email_verified"))
    return
  isLoginByGajin.update(true)
  openFMsgBox({ text = loc("msg/needToLoginByYourLinkedMail"), isPersist = true })
  defer(@() eventbus_send("logOutManually", {})) //to avoid call ecs destroy direct from ecs event about window active
}

eventbus_subscribe("onRenewAuthToken", function(_) {
  authTags(get_player_tags())
  isDebugGuestLogin(false)
  logGuest($"onRenewAuthToken. isGuestLogin = {isGuestLogin.value}, Tags = ", authTags.value)
  onGuestTagsUpdate()
})

eventbus_subscribe("onRenewGuestAuthTokenInAdvance", function(_) {
  authTags(get_player_tags())
  logGuest($"onRenewGuestAuthTokenInAdvance. isGuestLogin = {isGuestLogin.value}, Tags = ", authTags.value)
  onGuestTagsUpdate()
})

function renewGuestRegistrationTags() {
  if (!isGuestLogin.get())
    return
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
