from "%globalsDarg/darg_library.nut" import *
from "%rGui/notifications/consentTcf/consentTcfState.nut" import isOpenedPartners, vendorsListsCfg, vendorsLists
from "%rGui/notifications/consentTcf/consentTcfComps.nut" import mkContent, mkStatusContent, mkTitle, mkTextarea, mkLink, openUrl, fontMinor, gapBelow

let quitPartners = @() isOpenedPartners.set(false)

function mkPartnersDesc() {
  let privacyPolicyText = loc("privacyPolicy")

  let list = []
  foreach (idx, vl in vendorsLists.get())
    if (vl.len()) {
      let { titleLocId, itemToPartnerData } = vendorsListsCfg[idx]
      list.append(mkTitle(loc(titleLocId)))
      foreach (v in vl) {
        let p = itemToPartnerData(v)
        list.append(mkTextarea(p.name),
          mkLink(privacyPolicyText, @() openUrl(p.policy), gapBelow.__merge(fontMinor)))
      }
    }

  return list.len() ? list : mkStatusContent(loc("ui/empty"))
}

return @() mkContent(loc("consent_tcf/partners/manage"), mkPartnersDesc, null, quitPartners)
