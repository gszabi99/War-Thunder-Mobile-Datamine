from "%globalsDarg/darg_library.nut" import *
from "%rGui/notifications/consentTcf/consentTcfState.nut" import isOpenedPartnersExt, vendorsLists, vendorsListsCfg,
  getPurposesList, getSpecialPurposesList, getFeaturesList, getDataCategoiresList, mkPartnersExtLists
from "%rGui/notifications/consentTcf/consentTcfComps.nut" import mkContent, mkTextarea, mkLink,
  separatorLine, openUrl, gapAbove, gapBelow, gapAboveAndBelow, fadedAndMinor
from "%rGui/notifications/consentTcf/mkExpandableSwitch.nut" import mkExpandableSwitch, mkSwitch


let quitPartnersExt = @() isOpenedPartnersExt.set(false)

let bullet = loc("ui/bullet")

function mkPurposesBulletedList(titleLocId, idList, dataList, isEnabledKey = "isEnabled") {
  if (idList.len() == 0)
    return []
  let bulletedTextComps = dataList
    .filter(@(v) idList.contains(v.info.id))
    .map(@(v) mkTextarea("".concat(bullet, v.info.name,
      v?[isEnabledKey] == null ? "" : loc("ui/parentheses/space", { text = loc(v?[isEnabledKey].get() ? "options/on" : "options/off") })),
        fadedAndMinor))
  return [ mkTextarea(loc(titleLocId), gapAbove) ].extend(bulletedTextComps)
}

function mkPartnerSwitchComp(partner, onManualSwitch = null) {
  let { info, isExpanded, isEnabled, isEnabledLIT, listCfg } = partner
  let { itemToPartnerData, setConsentForVendor, setConsentForVendorLIT } = listCfg
  let { policy, legIntClaim } = itemToPartnerData(info)
  let { id = null, name, purposes = [], specialPurposes = [], features = [], legIntPurposes = [], dataDeclaration = [],
    deviceStorageDisclosureUrl = "", cookieMaxAgeSeconds = 0 } = info
  isEnabled?.subscribe(@(v) setConsentForVendor(id, v))
  isEnabledLIT?.subscribe(@(v) setConsentForVendorLIT(id, v))
  let purposesAll = getPurposesList()
  let purposesSpecialAll = getSpecialPurposesList()
  let featuresAll = getFeaturesList()
  let dataCategoriesAll = getDataCategoiresList()
  return mkExpandableSwitch(name, isEnabled, onManualSwitch, isExpanded, function() {
    let list = [
      mkLink(loc("consent_tcf/partners/policy"), @() openUrl(policy))
    ]
      .extend(mkPurposesBulletedList("consent_tcf/partners/purposes/consent", purposes, purposesAll))
      .extend(mkPurposesBulletedList("consent_tcf/manage/specialPurposes", specialPurposes, purposesSpecialAll))
      .extend(mkPurposesBulletedList("consent_tcf/manage/features", features, featuresAll))
      .append(isEnabledLIT == null && legIntClaim == "" ? null : mkTextarea(nbsp))
      .append(isEnabledLIT == null ? null : mkSwitch(loc("consent_tcf/manage/legitimateInterest"), isEnabledLIT, onManualSwitch))
      .append(legIntClaim == "" ? null : mkLink(loc("consent_tcf/partners/legitimateInterest"), @() openUrl(legIntClaim), gapBelow))
      .extend(mkPurposesBulletedList("consent_tcf/partners/purposes/legitimateInterest", legIntPurposes, purposesAll, "isEnabledLIT"))
      .extend(mkPurposesBulletedList("consent_tcf/partners/data", dataDeclaration, dataCategoriesAll))
      .append(cookieMaxAgeSeconds == 0 ? null : mkTextarea(loc("consent_tcf/partners/storage")))
      .append(cookieMaxAgeSeconds == 0 ? null : mkTextarea(loc("measureUnits/full/days", { n = cookieMaxAgeSeconds / 86400 }), fadedAndMinor))
      .append(deviceStorageDisclosureUrl == "" ? null : mkLink(loc("consent_tcf/partners/device"), @() openUrl(deviceStorageDisclosureUrl)))

    return list
  })
}

let isAllListedPartnersEnabled = @(list) list.findindex(@(p) !(p?.isEnabled.get() ?? true) || !(p?.isEnabledLIT.get() ?? true)) == null

function updatePartnersList(list, v) {
  foreach (p in list) {
    p?.isEnabled.set(v)
    if (v)
      p?.isEnabledLIT.set(v)
  }
}

let mkPartnersExtDesc = @() function() {
  let partnersExtLists = mkPartnersExtLists(vendorsLists.get())
  let partnersExtListFlat = partnersExtLists.reduce(@(res, v) res.extend(v), [])
  let getPartnersAllVal = @() isAllListedPartnersEnabled(partnersExtListFlat)
  let isPartnersAllEnabled = Watched(getPartnersAllVal())
  let onManualPartnersAllSwitch = @(v) updatePartnersList(partnersExtListFlat, v)
  let onManualPartnerSwitch = @(_) isPartnersAllEnabled.set(getPartnersAllVal())

  let list = [
    mkTextarea(loc("consent_tcf/partners/manage/desc"), fadedAndMinor.__merge(gapAboveAndBelow))
    mkSwitch(loc("consent_tcf/partners/consentToAll"), isPartnersAllEnabled, onManualPartnersAllSwitch)
    mkTextarea(nbsp)
  ]
  foreach (idx, vl in partnersExtLists)
    if (vl.len()) {
      let { titleLocId } = vendorsListsCfg[idx]
      list.append(mkTextarea("".concat(loc(titleLocId), colon)), separatorLine)
      foreach (p in vl)
        list.append(mkPartnerSwitchComp(p, onManualPartnerSwitch), separatorLine)
    }
  return {
    watch = vendorsLists
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = list
  }
}

return @() mkContent(loc("consent_tcf/partners/manage"), mkPartnersExtDesc, null, quitPartnersExt)
