from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { deferOnce, setInterval, clearTimer } = require("dagor.workcycle")
let { LT_GAIJIN, LT_GOOGLE, LT_APPLE, LT_FIREBASE, LT_GUEST, LT_FACEBOOK, LT_NSWITCH, SST_MAIL, SST_UNKNOWN, availableLoginTypes, isLoginByGajin
} = require("%appGlobals/loginState.nut")
let { TERMS_OF_SERVICE_URL, PRIVACY_POLICY_URL } = require("%appGlobals/legal.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { defButtonHeight, BRIGHT } = require("%rGui/components/buttonStyles.nut")
let { mkCustomButton, textButtonBright, textButtonCommon, buttonsHGap } = require("%rGui/components/textButton.nut")
let { urlText, urlLikeButton } = require("%rGui/components/urlText.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { optLang } = require("%rGui/options/options/langOptions.nut")
let mkOption = require("%rGui/options/mkOption.nut")
let { contentWidth } = require("%rGui/options/optionsStyle.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { getCurrentLanguage } = require("dagor.localize")
let { openSupportTicketWndOrUrl } = require("%rGui/feedback/supportWnd.nut")
let { is_nswitch } = require("%sqstd/platform.nut")
let { GP_SUCCESS = 0, getGPStatus = @() 0 } = require("android.account.googleplay")

let fbButtonVisible = getCurrentLanguage() != "Russian"
let gpButtonVisible = getGPStatus() == GP_SUCCESS
let loginName = mkWatched(persist, "loginName", "")
let loginPas = mkWatched(persist, "loginPas", "")
let twoStepAuthCode = mkWatched(persist, "twoStepAuthCode", "")
let check2StepAuthCode = mkWatched(persist, "check2StepAuthCode", false)
let hasEmail2step = mkWatched(persist, "hasEmail2step", false)
let secStepType = mkWatched(persist, "secStepType", SST_UNKNOWN)
let showPasswordIconSize = [hdpxi(50), hdpxi(40)]

let isShowLanguagesList = Watched(false)
let isPasswordVisible = Watched(false)
let isCanViewPassword = Watched(true)

loginName.subscribe(function(_) {
  check2StepAuthCode(false)
  hasEmail2step(false)
})

loginPas.subscribe(function(v) {
  check2StepAuthCode(false)
  hasEmail2step(false)
  if (v == "")
    isCanViewPassword(true)
})

check2StepAuthCode.subscribe(@(v) v ? isLoginByGajin(true) : null)

eventbus_subscribe("updateAuthStates", function(params) {
  let incomingPass = params?.loginPas ?? loginPas.value
  let isPassEqual = (loginPas.value == incomingPass)
  loginName(params?.loginName ?? loginName.value)
  loginPas(incomingPass)
  isCanViewPassword(loginPas.value == "" || (isCanViewPassword.value && isPassEqual))
  check2StepAuthCode(params?.check2StepAuthCode ?? check2StepAuthCode.value)
  secStepType(params?.secStepType ?? SST_UNKNOWN)
  hasEmail2step(secStepType.value == SST_MAIL)
})

let gaijinLogoWidth = (256.0 / 128.0 * defButtonHeight).tointeger()
let appleLogoHeight = (0.5 * defButtonHeight).tointeger()
let appleLogoWidth = (48.0 / 58.0 * appleLogoHeight).tointeger()
let googleLogoHeight = (0.5 * defButtonHeight).tointeger()
let googleLogoWidth = (59.0 / 62.0 * googleLogoHeight).tointeger()
let refrIconSize = hdpxi(37)
let cancelText = utf8ToUpper(loc("mainmenu/btnCancel"))

let urlColor = Color(0, 204, 255)

let resendTimeout = 30

local languageTitle = loc("profile/language")
let languageTitleEn = loc("profile/language/en")
languageTitle = languageTitle == languageTitleEn ? languageTitle
  : "".concat(languageTitle, loc("ui/parentheses/space", { text = languageTitleEn }))

function doLoginGaijin() {
  if (loginName.value == "") {
    anim_start(loginName)
    return
  }

  if (loginPas.value == "") {
    anim_start(loginPas)
    return
  }

  if (check2StepAuthCode.value && twoStepAuthCode.value == "") {
    anim_start(twoStepAuthCode)
    return
  }

  eventbus_send("doLogin", {
    loginType = LT_GAIJIN
    loginName = loginName.value
    loginPas = loginPas.value
    check2StepAuthCode = check2StepAuthCode.value
    twoStepAuthCode = check2StepAuthCode.value ? twoStepAuthCode.value : ""
  })
}

let transparentButtonIconWidth = (0.5 * defButtonHeight).tointeger()
function transparentButton(text, icon, onClick, override = {}) {
  let stateFlags = Watched(0)
  return @() {
    behavior = Behaviors.Button
    watch = stateFlags
    size = [SIZE_TO_CONTENT, defButtonHeight]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(30)
    onElemState = @(v) stateFlags(v)
    sound = { click  = "click" }
    onClick
    transform = { scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
    children = [
      {
        rendObj = ROBJ_TEXT
        text
      }.__update(fontSmall, override?.textOverride ?? {})
      {
        rendObj = ROBJ_IMAGE
        size = [ transparentButtonIconWidth, transparentButtonIconWidth ]
        image = Picture($"{icon}:{transparentButtonIconWidth}:{transparentButtonIconWidth}")
      }
    ]
  }
}

let languageButton = transparentButton(languageTitle, "ui/gameuiskin#menu_lang.svg",
  @() isShowLanguagesList.update(true))

let supportButton = transparentButton(loc("mainmenu/support"), "ui/gameuiskin#menu_support.svg",
  openSupportTicketWndOrUrl,
  {
    textOverride = {
      children = {
        rendObj = ROBJ_FRAME
        borderWidth = [0, 0, 2, 0]
        size = flex()
        pos = [0, 2]
      }
    }
  })

let mkGaijinLogo = @() {
  size = [ gaijinLogoWidth, defButtonHeight ]
  rendObj = ROBJ_IMAGE
  image = Picture($"!ui/gaijin_logo.svg:{gaijinLogoWidth}:{defButtonHeight}")
  keepAspect = KEEP_ASPECT_FIT
}

let mkTextInputField = @(textWatch, nameText, options = {}) textInput(textWatch, {
  placeholder = nameText
  onChange = @(value) textWatch(value)
  onEscape = @() textWatch("")
}.__update(options))

let mkPasswordInputField = @() {
  watch = [isPasswordVisible, isCanViewPassword]
  valign = ALIGN_CENTER
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    mkTextInputField(loginPas, loc("mainmenu/password"), { password = isPasswordVisible.value ? null : "\u2022" })
    isCanViewPassword.value
      ? {
          rendObj = ROBJ_IMAGE
          size = showPasswordIconSize
          image = Picture($"ui/gameuiskin#icon_password_hide.svg:{showPasswordIconSize[0]}:showPasswordIconSize[1]:P")
          hplace = ALIGN_RIGHT
          pos = [-hdpx(16), 0]
          behavior = Behaviors.Button
          onClick = @() isPasswordVisible(!isPasswordVisible.value)
          opacity = isPasswordVisible.value ? 1.0 : 0.4
          keepAspect = true
        }
      : null
  ]
}

let sighUp = urlText(loc("mainmenu/signUp"), loc("url/signUp"), { ovr = { hplace = ALIGN_RIGHT } })
let recoveryPassword = urlText(loc("msgbox/btn_recovery"), loc("url/recovery"))

let resendTimer = Watched(resendTimeout)
local timerMult = 1;
function updateResendTimer() {
  let v = resendTimer.value - 1
  if ( v >= 0 )
    resendTimer(v)
}

check2StepAuthCode.subscribe( function (v) { if (v) resendTimer(resendTimeout * timerMult) } )

function doResendCode() {
  timerMult++
  eventbus_send("doLogin", {
    loginType = LT_GAIJIN
    loginName = loginName.value
    loginPas = loginPas.value
    check2StepAuthCode = false
    twoStepAuthCode = ""
  })
}
let resendCodeBlock = @() {
  size = [flex(), hdpx(55)]
  flow = FLOW_HORIZONTAL
  watch = [resendTimer]
  valign = ALIGN_CENTER
  children = resendTimer.value > 0
    ? {
        rendObj = ROBJ_TEXT
        text = loc("msgbox/btn_resend_code_message", {value = resendTimer.value})
        color = Color(192, 192, 192)
        fontFx = FFT_GLOW
        fontFxFactor = 64
        fontFxColor = Color(0, 0, 0)
      }.__update(fontSmall)
    : [
        urlLikeButton(loc("msgbox/btn_resend_code"), doResendCode, { ovr = { hplace = ALIGN_RIGHT } })
        {
          size = [ refrIconSize, refrIconSize ]
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#refresh.svg:{refrIconSize}:{refrIconSize}:P")
          keepAspect = KEEP_ASPECT_FIT
        }
      ]
}

let gaijinAuthorization = @() {
  watch = [check2StepAuthCode, hasEmail2step, secStepType]
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_CENTER
      children = [
        mkGaijinLogo()
        sighUp
      ]
    }
    mkTextInputField(loginName, loc("mainmenu/login"), { inputType = "mail" })
    mkPasswordInputField
    check2StepAuthCode.value
      ? mkTextInputField(twoStepAuthCode, loc($"mainmenu/2step/code{secStepType.value}"), { inputType = "num" })
      : null
    hasEmail2step.value ? resendCodeBlock : recoveryPassword
    {
      flow = FLOW_HORIZONTAL
      gap = buttonsHGap
      children = [
        textButtonCommon(cancelText, @() isLoginByGajin.update(false), { hotkeys = [btnBEscUp] })
        textButtonBright(utf8ToUpper(loc("msgbox/btn_signIn")), doLoginGaijin, { hotkeys = ["^J:X"] })
      ]
    }
  ]
}

let appleLoginButtonContent = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(15)
  children = [
    {
      size = [ appleLogoWidth, appleLogoHeight ]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#apple_logo.svg:{appleLogoWidth}:{appleLogoHeight}")
      keepAspect = KEEP_ASPECT_FIT
      color = Color(0, 0, 0)
    }
    {
      rendObj = ROBJ_TEXT
      text = loc("mainmenu/AppleId")
      color = Color(0, 0, 0)
    }.__update(fontSmallAccented)
  ]
}

let nswitchLoginButtonContent = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(15)
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("mainmenu/nswitch")
      color = Color(0, 0, 0)
    }.__update(fontSmallAccented)
  ]
}

let googleLoginButtonContent = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(15)
  children = [
    {
      size = [ googleLogoWidth, googleLogoHeight ]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#google_logo.svg:{googleLogoWidth}:{googleLogoHeight}")
      keepAspect = KEEP_ASPECT_FIT
      color = Color(0, 0, 0)
    }
    {
      rendObj = ROBJ_TEXT
      text = "Google"
      color = Color(0, 0, 0)
    }.__update(fontSmallAccented)
  ]
}

let fbLoginButtonContent = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(15)
  children = [
    {
      size = [ googleLogoWidth, googleLogoHeight ]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#facebook_logo.svg:{googleLogoWidth}:{googleLogoHeight}")
      keepAspect = KEEP_ASPECT_FIT
      color = Color(0,0,0)
    }
    {
      rendObj = ROBJ_TEXT
      text = "Facebook"
      color = Color(0,0,0)
    }.__update(fontSmallAccented)
  ]
}

let firebaseLoginButtonContent = freeze({
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(15)
  children = [
    {
      size = [ googleLogoWidth, googleLogoHeight ]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#guest_login.svg:{googleLogoWidth}:{googleLogoHeight}")
      keepAspect = KEEP_ASPECT_FIT
      color = Color(0, 0, 0)
    }
    {
      rendObj = ROBJ_TEXT
      text = loc("authorization_method/guest")
      color = Color(0, 0, 0)
    }.__update(fontSmallAccented)
  ]
})

let guestLoginButtonContent = firebaseLoginButtonContent

let loginButtonCtors = {
  [LT_GAIJIN] = @() mkCustomButton(mkGaijinLogo(), @() isLoginByGajin.update(true), BRIGHT),
  [LT_GOOGLE] =  !gpButtonVisible ? null
    : @() mkCustomButton(googleLoginButtonContent,
      @() eventbus_send("doLogin", { loginType = LT_GOOGLE }),
        BRIGHT),
  [LT_APPLE] = @() mkCustomButton(appleLoginButtonContent,
    @() eventbus_send("doLogin", { loginType = LT_APPLE }),
    BRIGHT),
  [LT_NSWITCH] = @() mkCustomButton(nswitchLoginButtonContent,
    @() eventbus_send("doLogin", { loginType = LT_NSWITCH }),
    BRIGHT),
  [LT_FIREBASE] = @() mkCustomButton(firebaseLoginButtonContent,
    @() eventbus_send("doLogin", { loginType = LT_FIREBASE }),
    BRIGHT),
  [LT_GUEST] = @() mkCustomButton(guestLoginButtonContent,
    @() eventbus_send("doLogin", { loginType = LT_GUEST }),
    BRIGHT),
  [LT_FACEBOOK] = !fbButtonVisible ? null
    : @() mkCustomButton(fbLoginButtonContent,
        @() eventbus_send("doLogin", { loginType = LT_FACEBOOK }),
         BRIGHT),
}.filter(@(btnCtor) btnCtor != null)

function mkMainAuthorizationButtons() {
  let res = [LT_APPLE, LT_GOOGLE, LT_FIREBASE, LT_GUEST, LT_FACEBOOK, LT_GAIJIN, LT_NSWITCH]
    .filter(@(lt) availableLoginTypes?[lt] ?? false)
    .map(@(lt) loginButtonCtors?[lt]())
  if (!is_nswitch)
    res.insert(0, {
      rendObj = ROBJ_TEXT
      halign = ALIGN_CENTER
      text = loc("choose_authorization_method")
      color = Color(255, 255, 255)
      fontFx = FFT_GLOW
      fontFxFactor = 64
      fontFxColor = Color(0, 0, 0)
    }.__update(fontMedium))
  return res
}

let langOptionsContent = {
  size = [contentWidth, flex()]
  flow = FLOW_VERTICAL
  halign = ALIGN_LEFT
  valign = ALIGN_CENTER
  children = [
    mkOption(optLang)
    textButtonCommon(cancelText, @() isShowLanguagesList.update(false), { hotkeys = [btnBEscUp] })
  ]
}

let contentBlock = @() {
  watch = [ isLoginByGajin, isShowLanguagesList ]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = buttonsHGap
  children = isShowLanguagesList.value ? langOptionsContent
    : isLoginByGajin.value ? gaijinAuthorization
    : mkMainAuthorizationButtons()
}

let supportBlock = {
  hplace = ALIGN_RIGHT
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  children = [
    supportButton
    languageButton
  ]
}

let urlOvr = { ovr = { color = urlColor }, childOvr  = { color = urlColor } }
let termsOfServiceUrl = urlText(loc("termsOfService"), TERMS_OF_SERVICE_URL, urlOvr)
let privacyPolicyUrl = urlText(loc("privacyPolicy"), PRIVACY_POLICY_URL, urlOvr)
let checkAutoLogin = @() eventbus_send("login.checkAutoStart", {})

let mkLoginWnd = @() {
  key = {}
  size = flex()
  padding = saBordersRv
  rendObj = ROBJ_SOLID
  color = Color(17, 20, 26, 210)

  function onAttach() {
    eventbus_send("authState.request", {})
    deferOnce(checkAutoLogin)
    setInterval(1.0, updateResendTimer)
  }
  function onDetach() {
    clearTimer(updateResendTimer)
  }
  children = [
    contentBlock
    supportBlock
    {
      hplace = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      flow = FLOW_HORIZONTAL
      children = [
        termsOfServiceUrl
        {
          rendObj = ROBJ_TEXT
          text = loc("ui/comma")
        }.__update(fontSmall)
        privacyPolicyUrl
      ]
    }
  ]
  animations = wndSwitchAnim
}

return mkLoginWnd
