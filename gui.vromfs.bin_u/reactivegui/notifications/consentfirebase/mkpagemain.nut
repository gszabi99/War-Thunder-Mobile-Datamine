from "%globalsDarg/darg_library.nut" import *
let logC = log_with_prefix("[consent] ")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { can_skip_consent } = require("%appGlobals/permissions.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { needOpenConsentWnd, isOpenedPartners, isOpenedManage,
  defaultPointsTable, applyConsent, savedPoints, isConsentAcceptedOnce, setupAnalytics} = require("%rGui/notifications/consentFirebase/consentState.nut")
let { mkContent, mkLinkText } = require("%rGui/notifications/consentFirebase/consentComps.nut")

function close() {
  if (!isConsentAcceptedOnce.get()) {
    savedPoints.set(defaultPointsTable.map(@(_) false))
    logC("Firebase consent skipped")
    sendUiBqEvent("ads_consent_firebase", { id = "consent_skip" })
    setupAnalytics()
  }
  needOpenConsentWnd.set(false)
}

let mainButtons = [
  textButtonCommon(utf8ToUpper(loc("consentWnd/btns/notConsent")), @() applyConsent(defaultPointsTable.map(@(_) false), {wnd="consentMain", action="dont_consent"}))
  {size = flex()}
  textButtonPrimary(utf8ToUpper(loc("consentWnd/btns/consent")), @() applyConsent(defaultPointsTable, {wnd="consentMain", action="accept_all"}))
]

let mkTextArea = @(id){
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = loc(id)
}.__update(fontTiny)

let desc = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children = [
    mkTextArea("consentWnd/main/consentMesssagePart1")
    mkLinkText(loc("consentWnd/main/partners"), @() isOpenedPartners.set(true))
    mkTextArea("consentWnd/main/consentMesssagePart2")
    mkLinkText(loc("consentWnd/main/manage"), @() isOpenedManage.set(true), { hplace = ALIGN_CENTER })
  ]
}

return @() mkContent(loc("consentWnd/main/header"), desc, mainButtons, can_skip_consent.get() ? close : null, true)
