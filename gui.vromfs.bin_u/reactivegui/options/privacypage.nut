from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { PRIVACY_POLICY_URL } = require("%appGlobals/legal.nut")
let { textButtonPrimary, textButtonCommon, buttonsHGap } = require("%rGui/components/textButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { isOpenedManage, consentRequiredForCurrentRegion } = require("%rGui/notifications/consent/consentState.nut")
let { openLicenseWnd, licenseFileName } = require("licenseWnd.nut")
let { file_exists } = require("dagor.fs")

let buttonsWidthStyle = {
  ovr = {
    minWidth = hdpx(550)
  }
}

let logoutToDeleteAccountMsgBox = @() openMsgBox({
  text = loc("mainmenu/questionDeleteAcount")
  buttons = [
    { id = "cancel", isCancel = true }
    { id = "delete", text = loc("mainmenu/btnAccountDelete"), styleId = "PRIMARY", isDefault = true, cb = @() eventbus_send("deleteAccount", {}) }
  ]
})

return @() {
  size = flex()
  watch = consentRequiredForCurrentRegion
  padding = [buttonsHGap, 0, 0, 0]
  flow = FLOW_VERTICAL
  gap = buttonsHGap
  halign = ALIGN_CENTER
  children = [
    textButtonCommon(loc("mainmenu/btnAccountDelete"), logoutToDeleteAccountMsgBox, buttonsWidthStyle)
    textButtonPrimary(loc("options/personalData"), @() eventbus_send("openUrl", { baseUrl = PRIVACY_POLICY_URL }), buttonsWidthStyle)
    consentRequiredForCurrentRegion.get() ? textButtonPrimary(loc("mainmenu/consentPrivacy"), @() isOpenedManage(true), buttonsWidthStyle) : null
    !file_exists(licenseFileName) ? null
      : textButtonPrimary(loc("options/license"), openLicenseWnd, buttonsWidthStyle)
  ]
}
