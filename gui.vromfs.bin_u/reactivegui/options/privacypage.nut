from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { PRIVACY_POLICY_URL } = require("%appGlobals/legal.nut")
let { textButtonPrimary, textButtonCommon, buttonsHGap } = require("%rGui/components/textButton.nut")
let { is_pc } = require("%sqstd/platform.nut")
let { isGDPR = @() false, showConsentForm = @(_) null } = is_pc ? require("%rGui/consent/consentDbg.nut") : (require_optional("consent") ?? {})
let { openMsgBox } = require("%rGui/components/msgBox.nut")

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

return {
  size = flex()
  padding = [buttonsHGap, 0, 0, 0]
  flow = FLOW_VERTICAL
  gap = buttonsHGap
  halign = ALIGN_CENTER
  children = [
    textButtonCommon(loc("mainmenu/btnAccountDelete"), logoutToDeleteAccountMsgBox, buttonsWidthStyle)
    textButtonPrimary(loc("options/personalData"), @() eventbus_send("openUrl", { baseUrl = PRIVACY_POLICY_URL }), buttonsWidthStyle)
    !isGDPR() ? null : textButtonPrimary(loc("mainmenu/consentPrivacy"), @() showConsentForm(true), buttonsWidthStyle)
  ]
}