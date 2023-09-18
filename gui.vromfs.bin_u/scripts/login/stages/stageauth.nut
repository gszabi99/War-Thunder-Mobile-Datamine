from "%scripts/dagui_library.nut" import *
let { get_player_tags } = require("auth_wt")
let { LOGIN_STATE, LT_GAIJIN, LT_GOOGLE, LT_FACEBOOK, LT_APPLE, LT_FIREBASE, LT_GUEST, curLoginType, authTags
} = require("%appGlobals/loginState.nut")
let { subscribe, send } = require("eventbus")
let { authState } = require("%scripts/login/authState.nut")
let exitGame = require("%scripts/utils/exitGame.nut")
let googlePlayAccount = require("android.account.googleplay")
let appleAccount = require("ios.account.apple")
let { getUUID } = require("ios.platform")
let { is_ios, is_android } = require("%appGlobals/clientState/platform.nut")
let fbAccount = is_ios ? require("ios.account.facebook") : require("android.account.fb")
let { errorMsgBox } = require("%scripts/utils/errorMsgBox.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { openUrl } = require("%scripts/url.nut")
let { send_counter } = require("statsd")
let { sendErrorBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { getLocTextForLang } = require("dagor.localize")

let { logStage, onlyActiveStageCb, export, finalizeStage, interruptStage
} = require("mkStageBase.nut")("auth", LOGIN_STATE.LOGIN_STARTED, LOGIN_STATE.AUTHORIZED)


subscribeFMsgBtns({
  loginExitGame = @(_) exitGame()
  loginRecovery = @(_) openUrl(loc("url/recovery"), false, "login_wnd")
})

let mkInterruptWithRecoveryMsg = @(errCode) function(_loginType) {
  interruptStage({ errCode })
  errorMsgBox(errCode,
    [
      { id = "recovery", eventId = "loginRecovery", hotkeys = ["^J:X"] }
      { id = "exit", eventId = "loginExitGame", hotkeys = ["^J:Y"] }
      { id = "tryAgain", styleId = "PRIMARY", isDefault = true }
    ])
}

let proceedAuthByResult = {
  [YU2_OK] = function(loginType) {
    curLoginType(loginType)
    authTags(get_player_tags())
    finalizeStage()
  },

  [YU2_2STEP_AUTH] = function(_loginType) { //error, received if user not logged, because he have 2step authorization activated
    let value = ::is_has_email_two_step_type_sync()
    authState.mutate(@(a) a.__update({ check2StepAuthCode = true, email2step = value }))
    interruptStage({ error = "Need 2step auth" })
    send("StartListenTwoStepCode", {})
  },

  [YU2_WRONG_LOGIN] = mkInterruptWithRecoveryMsg(YU2_WRONG_LOGIN),
  [YU2_WRONG_PARAMETER] = mkInterruptWithRecoveryMsg(YU2_WRONG_PARAMETER),

  [YU2_DOI_INCOMPLETE] = function(_loginType) {
    interruptStage({ error = "DOI_INCOMPLETE" })
    openFMsgBox({ text = loc("yn1/login/DOI_INCOMPLETE"), uid = "verification_email_to_complete" })
  },
}

let function proceedAuthorizationResult(result, loginType) {
  let action = proceedAuthByResult?[result]
  if (action != null) {
    action(loginType)
    return
  }

  errorMsgBox(result,
    [
      { id = "exit", eventId = "loginExitGame", hotkeys = ["^J:X"] }
      { id = "tryAgain", styleId = "PRIMARY", isDefault = true }
    ])
  interruptStage({ errCode = result })
}

subscribe("android.account.googleplay.onSignInCallback",
  onlyActiveStageCb(function(msg) {
    let { player_id, server_auth, error_code = null } = msg
    let errStr = msg.error
    if (errStr != "") {
      send_counter("auth.google_signin_errors", 1, { error = errStr })
      interruptStage({ error = $"Google sign in failed: {errStr} {error_code}" })
      if (errStr != "gp_canceled") {
        let errLocId = $"yn1/login/{errStr}"
        sendErrorBqEvent($"{getLocTextForLang(errLocId, "English")}{error_code}")
        let errCodeStr = error_code != null ? $"\n\n<color={0x80808080}>{error_code}</color>" : ""
        openFMsgBox({ text = $"{loc(errLocId)}{errCodeStr}",
          buttons = [
            { id = "exit", eventId = "loginExitGame", hotkeys = ["^J:X"] }
            { id = "tryAgain", styleId = "PRIMARY", isDefault = true }
          ]
        })
      }
      return
    }
    logStage("Google check_login_pass")
    let result = ::check_login_pass(player_id, server_auth, "google", "google", false, false)
    //check_login_pass is not instant
    onlyActiveStageCb(@(_res) proceedAuthorizationResult(result, LT_GOOGLE))(result)
  }))

subscribe(is_android ? "android.account.fb.onSignInCallback" : "ios.account.facebook.onSignInCallback",
  onlyActiveStageCb(function(msg) {
    let { token, status } = msg
    if (status != fbAccount.FB_RESULT_OK) {
      send_counter("auth.fb_signin_errors", 1, { error = status })
      interruptStage({ error = $"Facebook sign in failed: {status}" })
      if (status != fbAccount.FB_RESULT_CANCEL) {
        errorMsgBox(YU2_UNKNOWN,
          [
            { id = "exit", eventId = "loginExitGame", hotkeys = ["^J:X"] }
            { id = "tryAgain", styleId = "PRIMARY", isDefault = true }
          ])
      }
      return
    }
    logStage("Facebook check_login_pass")
    let result = ::check_login_pass(token, "", "facebook", "facebook", false, false)
    onlyActiveStageCb(@(_res) proceedAuthorizationResult(result, LT_FACEBOOK))(result)
  }))

subscribe("android.account.onGuestFIDReciveCallback",
  onlyActiveStageCb(function(msg) {
    let { guest_FID } = msg
    if (guest_FID == "") {
      send_counter("auth.google_firebase_login_errors", 1, { error = "No FID recived" })
      interruptStage({ error = "Guest sign in failed: No FID recived" })
      errorMsgBox(YU2_UNKNOWN,
        [
          { id = "exit", eventId = "loginExitGame", hotkeys = ["^J:X"] }
          { id = "tryAgain", styleId = "PRIMARY", isDefault = true }
        ])
      return
    }

    logStage("Firebase check_login_pass")
    let result = ::check_login_pass(guest_FID, "", "firebase", "firebase", false, false)
    //check_login_pass is not instant
    onlyActiveStageCb(@(_res) proceedAuthorizationResult(result, LT_FIREBASE))(result)
  }))

subscribe("ios.account.apple.onAppleLoginToken",
  onlyActiveStageCb(function(msg) {
    let { status, token=null } = msg
    if (status != appleAccount.APPLE_LOGIN_SUCCESS) {
      if (status == appleAccount.APPLE_LOGIN_CANCEL) {
        interruptStage({ error = "Cancel login"})
        return
      }
      send_counter("auth.apple_signin_errors", 1, { error = status })
      interruptStage({ error = $"Apple sign in failed: {status}" })
      errorMsgBox(YU2_UNKNOWN,
        [
          { id = "exit", eventId = "loginExitGame", hotkeys = ["^J:X"] }
          { id = "tryAgain", styleId = "PRIMARY", isDefault = true }
        ])
      return
    }
    logStage("Apple check_login_pass")
    let result = ::check_login_pass("", token, "apple", "apple", false, false)
    onlyActiveStageCb(@(_res) proceedAuthorizationResult(result, LT_APPLE))(result)
}))

let loginByType = {
  [LT_GOOGLE] = function(_as) {
    googlePlayAccount.signOut(false)
    googlePlayAccount.startSignIn() //will be event android.account.googleplay.onSignInCallback as result
  },

  [LT_FACEBOOK] = function(_as) {
    if (is_android)
      googlePlayAccount.signOut(false)
    fbAccount.startFBSignIn() //will be event android.account.fb.onSignInCallback as result
  },

  [LT_FIREBASE] = function(_as) {
    googlePlayAccount.signOut(false)
    googlePlayAccount.prepareGuestFID() //will be event android.account.onGuestFIDReciveCallback
  },

  [LT_GUEST] = function(_as) {
    let result = ::check_login_pass(getUUID(), "", "guest", "guest", false, false)
    onlyActiveStageCb(@(_res) proceedAuthorizationResult(result, LT_GUEST))(result)
  },

  [LT_APPLE] = function(_as) {
    appleAccount.getAppleLoginToken()
  },

  [LT_GAIJIN] = function(as) {
    let result = ::check_login_pass(as.loginName,
      as.loginPas,
      "", //We not use stoken in WTM
      as.check2StepAuthCode ? as.twoStepAuthCode : "",
      true,
      false)
    //check_login_pass is not instant
    onlyActiveStageCb(@(_res) proceedAuthorizationResult(result, LT_GAIJIN))(result)
  },
}

let function start() {
  let { loginType } = authState.value
  let loginStart = loginByType?[loginType]
  if (loginStart == null) {
    interruptStage({ error = $"Unknown loginType = {loginType}" })
    return
  }
  logStage($"Start login {loginType}")
  loginStart(authState.value)
}

return export.__merge({
  start
  restart = start
})