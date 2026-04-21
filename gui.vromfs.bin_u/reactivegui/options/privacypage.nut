from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { PRIVACY_POLICY_URL, TERMS_OF_SERVICE_URL } = require("%appGlobals/legal.nut")
let { tcf_consent_enabled } = require("%appGlobals/permissions.nut")
let { textButtonPrimary, textButtonCommon, buttonsVGap, mkCustomButton,
  mkButtonTextMultiline, mergeStyles
} = require("%rGui/components/textButton.nut")
let { PRIMARY } = require("%rGui/components/buttonStyles.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { isTcfConsentRequiredForCountry, openTcfConsentWnd } = require("%rGui/notifications/consentTcf/consentTcfState.nut")
let { isOpenedManage, consentRequiredForCurrentRegion } = require("%rGui/notifications/consent/consentState.nut")
let { openLicenseWnd, licenseFileName } = require("%rGui/options/licenseWnd.nut")
let { file_exists } = require("dagor.fs")

let multilineButtonOvrStyle = {
  size = const [hdpx(500), SIZE_TO_CONTENT],
  lineSpacing = hdpx(-4)
}.__update(fontTinyAccentedShadedBold)

let buttonsWidthStyle = {
  ovr = {
    minWidth = hdpx(550)
  }
  childOvr = {
    halign = ALIGN_CENTER
  }.__update(multilineButtonOvrStyle)
}

let logoutToDeleteAccountMsgBox = @() openMsgBox({
  text = loc("mainmenu/questionDeleteAcount")
  buttons = [
    { id = "cancel", isCancel = true }
    { id = "delete", text = utf8ToUpper(loc("mainmenu/btnAccountDelete")), styleId = "PRIMARY", isDefault = true, cb = @() eventbus_send("deleteAccount", {}) }
  ]
})

return @() {
  size = flex()
  watch = [tcf_consent_enabled, isTcfConsentRequiredForCountry, consentRequiredForCurrentRegion]
  flow = FLOW_VERTICAL
  gap = buttonsVGap
  halign = ALIGN_CENTER
  children = [
    textButtonCommon(utf8ToUpper(loc("mainmenu/btnAccountDelete")), logoutToDeleteAccountMsgBox, buttonsWidthStyle)
    mkCustomButton(
      mkButtonTextMultiline(utf8ToUpper(loc("privacyPolicy")), multilineButtonOvrStyle),
      @() eventbus_send("openUrl", { baseUrl = PRIVACY_POLICY_URL }),
      mergeStyles(PRIMARY, buttonsWidthStyle))
    mkCustomButton(
      mkButtonTextMultiline(utf8ToUpper(loc("mainmenu/termsOfService")), multilineButtonOvrStyle),
      @() eventbus_send("openUrl", { baseUrl = TERMS_OF_SERVICE_URL }),
      mergeStyles(PRIMARY, buttonsWidthStyle))
    tcf_consent_enabled.get() && isTcfConsentRequiredForCountry.get()
      ? textButtonPrimary(utf8ToUpper(loc("mainmenu/consentPrivacy")), openTcfConsentWnd, buttonsWidthStyle)
      : null
    !tcf_consent_enabled.get() && consentRequiredForCurrentRegion.get()
      ? textButtonPrimary(utf8ToUpper(loc("mainmenu/consentPrivacy")), @() isOpenedManage.set(true), buttonsWidthStyle)
      : null
    !file_exists(licenseFileName) ? null
      : textButtonPrimary(utf8ToUpper(loc("options/license")), openLicenseWnd, buttonsWidthStyle)
  ]
}
