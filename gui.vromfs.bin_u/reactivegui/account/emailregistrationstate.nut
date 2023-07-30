from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { defer } = require("dagor.workcycle")
let { register_command } = require("console")
let { getPlayerSsoShortToken } = require("auth_wt")
let { get_authenticated_url_sso } = require("url")
let { authTags } = require("%appGlobals/loginState.nut")
let { subscribeFMsgBtns } = require("%appGlobals/openForeignMsgBox.nut")
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
local needRelogin = false

let function openGuestEmailRegistration() {
  needRelogin = true
  send("openUrl", {
    baseUrl = $"https://login.gaijin.net/{loc("current_lang")}/guest?stoken={getPlayerSsoShortToken()}"
  })
}

let openVerifyEmail = @() defer(@() send("openUrl", {
  baseUrl = get_authenticated_url_sso($"/user.php?skin_lang={loc("current_lang")}").url
})) //get_authenticated_url_sso function is not aSync, so better to do it out of main script path

subscribeFMsgBtns({
  openGuestEmailRegistration = @(_) openGuestEmailRegistration()
})

windowActive.subscribe(function(v) {
  if (!v || !needRelogin)
    return
  needRelogin = false
  defer(@() send("relogin", {})) //to avoid call ecs destroy direct from ecs event about window active
})

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
  needVerifyEmail
  openVerifyEmail
}
