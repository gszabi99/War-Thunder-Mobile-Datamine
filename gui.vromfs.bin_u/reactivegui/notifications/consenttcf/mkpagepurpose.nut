from "%globalsDarg/darg_library.nut" import *
from "%rGui/notifications/consentTcf/consentTcfState.nut" import showPurposeInfo
from "%rGui/notifications/consentTcf/consentTcfComps.nut" import mkContent, mkTextarea, gapAbove, gapAboveAndBelow, fadedAndMinor

let quitPurpose = @() showPurposeInfo.set(null)

function mkPurposeDesc() {
  let { info = null, getVendorList = null } = showPurposeInfo.get()
  if (info == null)
    return null
  let { name, description, illustrations = [] } = info
  let vendorList = getVendorList?() ?? []
  let vendorsListTitle = "".concat(loc("consent_tcf/manage/consent_partners"),
    loc("ui/parentheses/space", { text = vendorList.len() }))

  return [
    mkTextarea(name)
    mkTextarea(description, fadedAndMinor.__merge(gapAbove))
    illustrations.len() ? mkTextarea(loc("consent_tcf/manage/illustrations"), gapAbove) : null
  ]
    .extend(illustrations.map(@(v) mkTextarea(v, fadedAndMinor.__merge(gapAbove))))
    .append(mkTextarea(vendorsListTitle, gapAboveAndBelow))
    .extend(vendorList.map(@(v) mkTextarea(v.name)))
}

return @() mkContent(loc("readMore"), mkPurposeDesc, null, quitPurpose)
