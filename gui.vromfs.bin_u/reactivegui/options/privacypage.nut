from "%globalsDarg/darg_library.nut" import *
from "dagor.fs" import file_exists
from "eventbus" import eventbus_send
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/consent.nut" import isTcfConsentEnabled
from "%rGui/legal.nut" import PRIVACY_POLICY_URL, TERMS_OF_SERVICE_URL
from "%rGui/components/buttonStyles.nut" import PRIMARY
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/textButton.nut" import textButtonPrimary, textButtonCommon, buttonsVGap, mkCustomButton,
  mkButtonTextMultiline, mergeStyles
from "%rGui/notifications/consentFirebase/consentState.nut" import isOpenedManage, consentRequiredForCurrentRegion
from "%rGui/notifications/consentTcf/consentTcfState.nut" import isTcfConsentRequiredForCountry, openTcfConsentWnd
from "%rGui/options/licenseWnd.nut" import openLicenseWnd, licenseFileName


let multilineButtonOvrStyle = {
  size = const [hdpx(500), SIZE_TO_CONTENT],
  lineSpacing = hdpx(-4)
}.__update(fontBoldTinyAccentedShaded)

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
  size = FLEX
  watch = [isTcfConsentEnabled, isTcfConsentRequiredForCountry, consentRequiredForCurrentRegion]
  flow = FLOW_VERTICAL
  gap = buttonsVGap
  halign = ALIGN_CENTER
  children = [
    mkCustomButton(
      mkButtonTextMultiline(utf8ToUpper(loc("privacyPolicy")), multilineButtonOvrStyle),
      @() eventbus_send("openUrl", { baseUrl = PRIVACY_POLICY_URL }),
      mergeStyles(PRIMARY, buttonsWidthStyle))
    mkCustomButton(
      mkButtonTextMultiline(utf8ToUpper(loc("mainmenu/termsOfService")), multilineButtonOvrStyle),
      @() eventbus_send("openUrl", { baseUrl = TERMS_OF_SERVICE_URL }),
      mergeStyles(PRIMARY, buttonsWidthStyle))
    isTcfConsentEnabled.get() && isTcfConsentRequiredForCountry.get()
      ? textButtonPrimary(utf8ToUpper(loc("mainmenu/consentPrivacy")), openTcfConsentWnd, buttonsWidthStyle)
      : null
    !isTcfConsentEnabled.get() && consentRequiredForCurrentRegion.get()
      ? textButtonPrimary(utf8ToUpper(loc("mainmenu/consentPrivacy")), @() isOpenedManage.set(true), buttonsWidthStyle)
      : null
    !file_exists(licenseFileName) ? null
      : textButtonPrimary(utf8ToUpper(loc("options/license")), openLicenseWnd, buttonsWidthStyle)
    textButtonCommon(utf8ToUpper(loc("mainmenu/btnAccountDelete")), logoutToDeleteAccountMsgBox, buttonsWidthStyle)
  ]
}
