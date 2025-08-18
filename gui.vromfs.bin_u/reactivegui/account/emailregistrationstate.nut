from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { defer, resetTimeout, clearTimer } = require("dagor.workcycle")
let { register_command } = require("console")
let { getPlayerSsoShortTokenAsync, YU2_OK, renewToken, get_player_tags, get_authenticated_url_sso
} = require("auth_wt")
let { object_to_json_string } = require("json")
let logGuest = log_with_prefix("[GUEST] ")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { authTags, isLoginByGajin, isLoggedIn } = require("%appGlobals/loginState.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { isInLoadingScreen, isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { windowActive } = require("%appGlobals/windowState.nut")
let { accountLink } = require("%rGui/contacts/contactLists.nut")
let { isContactsReceived } = require("%rGui/contacts/contactsState.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")


let AUTH_TAG_REQUEST_TIME = 60
let MAX_ATTEMPTS_TO_UPDATE_TAGS = 3

let isGuestLoginBase = Computed(@() authTags.get().contains("guestlogin")
  || authTags.get().contains("firebaselogin"))
let isDebugGuestLogin = mkWatched(persist, "isDebugGuestLogin", false)
let isGuestLogin = Computed(@() isGuestLoginBase.get() != isDebugGuestLogin.get())
let needVerifyEmailBase = Computed(@() !isGuestLogin.get()
  && isContactsReceived.get()
  && accountLink.get() == null
  && !authTags.get().contains("email_verified")
  && !(authTags.get().contains("gplogin") || authTags.get().contains("applelogin")
        || authTags.get().contains("fblogin") || authTags.get().contains("hwlogin")))
let isDebugVerifyEmail = mkWatched(persist, "isDebugVerifyEmail", false)
let needVerifyEmail = Computed(@() needVerifyEmailBase.get() != isDebugVerifyEmail.get())
let needCheckRelogin = hardPersistWatched("guest.needCheckRelogin", false)
let attemptsToUpdateTags = hardPersistWatched("guest.attemptsToUpdateTags", 0)
let isDelayedUpdateTagsActive = hardPersistWatched("guest.isDelayedUpdateTagsActive", false)
let canShowModalToRelogin = hardPersistWatched("guest.canShowModalToRelogin", false)

let needShowModalToRelogin = keepref(Computed(@() isInMenuNoModals.get()
  && !isInLoadingScreen.get()
  && !isTutorialActive.get()
  && !isInDebriefing.get()
  && canShowModalToRelogin.get()
  && isLoggedIn.get()))

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
    needCheckRelogin.set(true)
    openGuestEmailRegistrationImpl(stoken)
  }
})

function openGuestEmailRegistration() {
  logGuest("getPlayerSsoShortTokenAsync")
  getPlayerSsoShortTokenAsync("onGetStokenForGuestEmail")
}

function reloginToLinkedEmail(needShowMsg = true) {
  isLoginByGajin.set(true)
  if (needShowMsg)
    openFMsgBox({ text = loc("msg/needReloginToLinkedEmail"), isPersist = true })
  defer(@() eventbus_send("logOutManually", {})) 
}

function openVerifyEmail() {
  logGuest("Open verify message")
  let url = $"https://store.gaijin.net/user.php?skin_lang={loc("current_lang")}"
  get_authenticated_url_sso(url, "", "", "onAuthenticatedUrlResult", object_to_json_string({ notAuthUrl = url }))
}

subscribeFMsgBtns({
  openGuestEmailRegistration = @(_) openGuestEmailRegistration()
  reloginToLinkedEmail = @(_) reloginToLinkedEmail(false)
})

windowActive.subscribe(function(v) {
  if (!v || !needCheckRelogin.get())
    return
  needCheckRelogin.set(false)
  logGuest("Request renew token")
  renewToken("onRenewAuthToken")
})

function delayedUpdateAuthTags() {
  if (attemptsToUpdateTags.get() >= MAX_ATTEMPTS_TO_UPDATE_TAGS || !isLoggedIn.get())
    return clearTimer(delayedUpdateAuthTags)
  attemptsToUpdateTags.set(attemptsToUpdateTags.get() + 1)

  logGuest("Delayed request for authorization tags has been set. Tags = ", authTags.get())
  renewToken("onRenewAuthToken")
  resetTimeout(AUTH_TAG_REQUEST_TIME, delayedUpdateAuthTags)
}

isLoggedIn.subscribe(function(_) {
  isDelayedUpdateTagsActive.set(false)
  canShowModalToRelogin.set(false)
})
isDelayedUpdateTagsActive.subscribe(@(v) v
  ? resetTimeout(AUTH_TAG_REQUEST_TIME, delayedUpdateAuthTags)
  : clearTimer(delayedUpdateAuthTags))

needShowModalToRelogin.subscribe(function(v) {
  if (v) {
    isDelayedUpdateTagsActive.set(false)
    canShowModalToRelogin.set(false)
    openFMsgBox({
      text = loc("msg/needReloginToLinkedEmail")
      isPersist = true
      buttons = [
        { id = "ok", eventId = "reloginToLinkedEmail", isDefault = true, styleId = "PRIMARY" }
      ]
    })
  }
})

function onGuestTagsUpdate() {
  if (!authTags.get().contains("email_verified"))
    return
  reloginToLinkedEmail()
}

function onGuestTagsUpdateWithWaiting() {
  if (!authTags.get().contains("email_verified"))
    return isDelayedUpdateTagsActive.set(true)
  if (!isDelayedUpdateTagsActive.get())
    reloginToLinkedEmail()
  else
    canShowModalToRelogin.set(true)
}

eventbus_subscribe("onRenewAuthToken", function(_) {
  authTags.set(get_player_tags())
  isDebugGuestLogin.set(false)
  logGuest($"onRenewAuthToken. isGuestLogin = {isGuestLogin.get()}, Tags = ", authTags.get())
  onGuestTagsUpdateWithWaiting()
})

eventbus_subscribe("onRenewGuestAuthTokenInAdvance", function(_) {
  authTags.set(get_player_tags())
  logGuest($"onRenewGuestAuthTokenInAdvance. isGuestLogin = {isGuestLogin.get()}, Tags = ", authTags.get())
  onGuestTagsUpdate()
})

function renewGuestRegistrationTags() {
  if (!isGuestLogin.get())
    return
  logGuest("Request renew guest token in advance")
  renewToken("onRenewGuestAuthTokenInAdvance")
}

register_command(function() {
    isDebugGuestLogin.set(!isDebugGuestLogin.get())
    console_print("isGuestLogin = ", isGuestLogin.get()) 
  }, "ui.debug.guestLogin")

register_command(function() {
    isDebugVerifyEmail.set(!isDebugVerifyEmail.get())
    console_print("needVerifyEmail = ", needVerifyEmail.get()) 
  }, "ui.debug.verifyEmail")

return {
  isGuestLogin
  openGuestEmailRegistration
  renewGuestRegistrationTags
  needVerifyEmail
  openVerifyEmail
}
