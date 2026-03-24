from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/legal.nut" import PRIVACY_POLICY_URL
from "%rGui/notifications/consentTcf/consentTcfState.nut" import isOpenedPartners, isOpenedManage,
  totalPartners, doSkipClose
from "%rGui/notifications/consentTcf/consentTcfComps.nut" import mkContent, mkIntroButtons,
  mkTextarea, mkTextareaWithLinks, mkLink, openUrl, gapAbove, gapBelow, gapAboveAndBelow

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

let introButtons = mkIntroButtons(BQ_WND_ID)

return @() mkContent(loc("consent_tcf/intro/header"), mkIntroDesc, introButtons, doSkipClose, true)
