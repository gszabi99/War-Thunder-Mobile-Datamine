from "%globalsDarg/darg_library.nut" import *

let eventbus = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { LT_GAIJIN, LT_GOOGLE, LT_APPLE, LT_FIREBASE, LT_FACEBOOK, availableLoginTypes, isLoginByGajin
} = require("%appGlobals/loginState.nut")
let { TERMS_OF_SERVICE_URL, PRIVACY_POLICY_URL } = require("%appGlobals/legal.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { defButtonHeight, BRIGHT } = require("%rGui/components/buttonStyles.nut")
let { mkCustomButton, textButtonBright, textButtonCommon, buttonsHGap } = require("%rGui/components/textButton.nut")
let urlText = require("%rGui/components/urlText.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { optLang } = require("%rGui/options/options/langOptions.nut")
let mkOption = require("%rGui/options/mkOption.nut")
let { contentWidth } = require("%rGui/options/optionsStyle.nut")
let { btnBUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { getCurrentLanguage } = require("dagor.localize")

let fbButtonVisible = getCurrentLanguage() != "Russian"
let loginName = mkWatched(persist, "loginName", "")
let loginPas = mkWatched(persist, "loginPas", "")
let twoStepAuthCode = mkWatched(persist, "twoStepAuthCode", "")
let check2StepAuthCode = mkWatched(persist, "check2StepAuthCode", false)

let isShowLanguagesList = Watched(false)

loginName.subscribe(@(_) check2StepAuthCode(false))
check2StepAuthCode.subscribe(@(v) v ? isLoginByGajin(true) : null)

eventbus.subscribe("updateAuthStates", function(params) {
  loginName(params?.loginName ?? loginName.value)
  loginPas(params?.loginPas ?? loginPas.value)
  check2StepAuthCode(params?.check2StepAuthCode ?? check2StepAuthCode.value)
})

let gaijinLogoWidth = (256.0 / 128.0 * defButtonHeight).tointeger()
let appleLogoHeight = (0.5 * defButtonHeight).tointeger()
let appleLogoWidth = (48.0 / 58.0 * appleLogoHeight).tointeger()
let googleLogoHeight = (0.5 * defButtonHeight).tointeger()
let googleLogoWidth = (59.0 / 62.0 * googleLogoHeight).tointeger()

let cancelText = utf8ToUpper(loc("mainmenu/btnCancel"))

let urlColor = Color(0, 204, 255)

local languageTitle = loc("profile/language")
let languageTitleEn = loc("profile/language/en")
languageTitle = languageTitle == languageTitleEn ? languageTitle
  : "".concat(languageTitle, loc("ui/parentheses/space", { text = languageTitleEn }))

let function doLoginGaijin() {
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

  eventbus.send("doLogin", {
    loginType = LT_GAIJIN
    loginName = loginName.value
    loginPas = loginPas.value
    check2StepAuthCode = check2StepAuthCode.value
    twoStepAuthCode = check2StepAuthCode.value ? twoStepAuthCode.value : ""
  })
}

let transparentButtonIconWidth = (0.5 * defButtonHeight).tointeger()
let function transparentButton(text, icon, onClick, override = {}) {
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

let supportUrl = loc("url/support")
let supportButton = transparentButton(loc("mainmenu/support"), "ui/gameuiskin#menu_support.svg",
  @() eventbus.send("openUrl", { baseUrl = supportUrl }),
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

let gaijinLogo = {
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

let sighUp = urlText(loc("mainmenu/signUp"), loc("url/signUp"), { ovr = { hplace = ALIGN_RIGHT } })
let recoveryPassword = urlText(loc("msgbox/btn_recovery"), loc("url/recovery"))

let gaijinAuthorization = @() {
  watch = check2StepAuthCode
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_CENTER
      children = [
        gaijinLogo
        sighUp
      ]
    }
    mkTextInputField(loginName, loc("mainmenu/login"), { inputType = "mail" })
    mkTextInputField(loginPas, loc("mainmenu/password"), { password = "\u2022" })
    check2StepAuthCode.value
      ? mkTextInputField(twoStepAuthCode, loc("mainmenu/2stepVerifCode"), { inputType = "num" })
      : null
    recoveryPassword
    {
      flow = FLOW_HORIZONTAL
      gap = buttonsHGap
      children = [
        textButtonCommon(cancelText, @() isLoginByGajin.update(false), { hotkeys = [btnBUp] })
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

let firebaseLoginButtonContent = {
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
}

let loginButtons = {
  [LT_GAIJIN] = mkCustomButton(gaijinLogo, @() isLoginByGajin.update(true), BRIGHT),
  [LT_GOOGLE] = mkCustomButton(googleLoginButtonContent,
    @() eventbus.send("doLogin", { loginType = LT_GOOGLE }),
    BRIGHT),
  [LT_APPLE] = mkCustomButton(appleLoginButtonContent,
    @() eventbus.send("doLogin", { loginType = LT_APPLE }),
    BRIGHT),
  [LT_FIREBASE] = mkCustomButton(firebaseLoginButtonContent,
    @() eventbus.send("doLogin", { loginType = LT_FIREBASE }),
    BRIGHT),
  [LT_FACEBOOK] = !fbButtonVisible ? null
    : mkCustomButton(fbLoginButtonContent,
    @() eventbus.send("doLogin", { loginType = LT_FACEBOOK }),
     BRIGHT),
}.filter(@(button) button != null)

let mainAuthorizationButtons = [LT_APPLE, LT_GOOGLE, LT_FIREBASE, LT_FACEBOOK, LT_GAIJIN]
  .filter(@(lt) availableLoginTypes?[lt] ?? false)
  .map(@(lt) loginButtons?[lt])

mainAuthorizationButtons.insert(0, {
  rendObj = ROBJ_TEXT
  halign = ALIGN_CENTER
  text = loc("choose_authorization_method")
  color = Color(255, 255, 255)
  fontFx = FFT_GLOW
  fontFxFactor = 64
  fontFxColor = Color(0, 0, 0)
}.__update(fontMedium))

let langOptionsContent = {
  size = [contentWidth, flex()]
  flow = FLOW_VERTICAL
  halign = ALIGN_LEFT
  valign = ALIGN_CENTER
  children = [
    mkOption(optLang)
    textButtonCommon(cancelText, @() isShowLanguagesList.update(false))
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
    : mainAuthorizationButtons
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
let checkAutoLogin = @() eventbus.send("login.checkAutoStart", {})

return {
  key = {}
  size = flex()
  padding = saBordersRv
  rendObj = ROBJ_SOLID
  color = Color(17, 20, 26, 210)

  function onAttach() {
    eventbus.send("authState.request", {})
    deferOnce(checkAutoLogin)
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
