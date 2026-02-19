from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/legal.nut" import PRIVACY_POLICY_URL
from "%rGui/components/textButton.nut" import textButtonCommon, textButtonPrimary
from "%rGui/notifications/consentTcf/consentTcfState.nut" import isOpenedPartners, isOpenedManage,
  totalPartners, doAnswerAllAndClose, doAskSaveAndClose
from "%rGui/notifications/consentTcf/consentTcfComps.nut" import mkContent, mkTextarea, mkTextareaWithLinks,
  mkLink, openUrl, gapAbove, gapBelow, gapAboveAndBelow

const BQ_WND_ID = "consentMain"

let mkIntroDesc = @() [
  mkTextarea(loc("consent_tcf/intro/desc/p1"), gapBelow)
  mkTextareaWithLinks(loc("consent_tcf/intro/desc/p2"), {
    ["{partnersLink}"] = mkLink(loc("consent_tcf/intro/desc/p2/partnersLink", { count = totalPartners.get() }), 
      @() isOpenedPartners.set(true))
  })
  mkTextarea(loc("consent_tcf/intro/desc/p3"), gapAboveAndBelow)
  mkTextareaWithLinks(loc("consent_tcf/intro/desc/p4"), {
    ["{privacyPolicyLink}"] = mkLink(loc("consent_tcf/intro/desc/p4/privacyPolicyLink"), 
      @() openUrl(PRIVACY_POLICY_URL))
  })
  mkTextarea(nbsp)
  mkLink(loc("consent_tcf/intro/managePreferences"), @() isOpenedManage.set(true), gapAbove.__merge({ hplace = ALIGN_CENTER }))
]

let introButtons = [
  textButtonCommon(utf8ToUpper(loc("consentWnd/btns/notConsent")), @() doAnswerAllAndClose(BQ_WND_ID, false))
  {size = flex()}
  textButtonPrimary(utf8ToUpper(loc("consentWnd/btns/consent")), @() doAnswerAllAndClose(BQ_WND_ID, true))
]

return @() mkContent(loc("consent_tcf/intro/header"), mkIntroDesc, introButtons, @() doAskSaveAndClose(BQ_WND_ID))
