from "%globalsDarg/darg_library.nut" import *
from "%rGui/notifications/consentTcf/consentTcfState.nut" import isOpenedPartnersExt, vendorsLists, vendorsListsCfg,
  getPurposesList, getSpecialPurposesList, getFeaturesList, getDataCategoiresList, mkPartnersExtLists, debugShowIds
from "%rGui/notifications/consentTcf/consentTcfComps.nut" import mkContent, mkTextarea, mkLink,
  separatorLine, openUrl, gapAbove, gapBelow, fadedAndMinor
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

function mkPartnerSwitchComp(partner, onManualSwitch, needShowId) {
  let { info, isExpanded, isAvailable, isEnabled, isAvailableLIT, isEnabledLIT, listCfg } = partner
  let { itemToPartnerData } = listCfg
  let { policy, legIntClaim } = itemToPartnerData(info)
  let { id = null, name, purposes = [], specialPurposes = [], features = [], legIntPurposes = [], dataDeclaration = [],
    deviceStorageDisclosureUrl = "", cookieMaxAgeSeconds = 0 } = info
  let title = needShowId ? $"[{id}] {name}" : name
  let purposesAll = getPurposesList()
  let purposesSpecialAll = getSpecialPurposesList()
  let featuresAll = getFeaturesList()
  let dataCategoriesAll = getDataCategoiresList()
  let emptyLine = mkTextarea(nbsp)
  return mkExpandableSwitch(title, isAvailable, isEnabled, onManualSwitch, isExpanded, function() {
    let list = [
      mkLink(loc("consent_tcf/partners/policy"), @() openUrl(policy))
    ]
      .extend(mkPurposesBulletedList("consent_tcf/partners/purposes/consent", purposes, purposesAll))
      .extend(mkPurposesBulletedList("consent_tcf/manage/specialPurposes", specialPurposes, purposesSpecialAll))
      .extend(mkPurposesBulletedList("consent_tcf/manage/features", features, featuresAll))
      .append(isEnabledLIT == null && legIntClaim == "" ? null : emptyLine)
      .append(isEnabledLIT == null ? null : mkSwitch(loc("consent_tcf/manage/legitimateInterest"), isAvailableLIT, isEnabledLIT, onManualSwitch))
      .append(legIntClaim == "" ? null : mkLink(loc("consent_tcf/partners/legitimateInterest"), @() openUrl(legIntClaim), gapBelow))
      .extend(mkPurposesBulletedList("consent_tcf/partners/purposes/legitimateInterest", legIntPurposes, purposesAll, "isEnabledLIT"))
      .extend(mkPurposesBulletedList("consent_tcf/partners/data", dataDeclaration, dataCategoriesAll))
      .append(cookieMaxAgeSeconds == 0 ? null : mkTextarea(loc("consent_tcf/partners/storage"), gapAbove))
      .append(cookieMaxAgeSeconds == 0 ? null : mkTextarea(loc("measureUnits/full/days", { n = cookieMaxAgeSeconds / 86400 }), fadedAndMinor))
      .extend(deviceStorageDisclosureUrl == "" ? [] : [ emptyLine, mkLink(loc("consent_tcf/partners/device"), @() openUrl(deviceStorageDisclosureUrl)) ])
      .append(emptyLine)

    return list
  })
}

let isAnyPartnerConsentSwitchesAvailable = @(list) list.findindex(@(p) p?.isAvailable.get() ?? false) != null

let isAllPartnerConsentSwitchesEnabled = @(list) list.findindex(@(p) p?.isAvailable.get() ?? false) != null
  && list.findindex(@(p) (p?.isAvailable.get() ?? false) && !(p?.isEnabled.get() ?? true)) == null

function updatePartnersList(list, v) {
  foreach (p in list)
    if (p?.isAvailable.get() ?? false)
      p?.isEnabled.set(v)
}

let mkPartnersExtDesc = @() function() {
  let partnersExtLists = mkPartnersExtLists(vendorsLists.get())
  let partnersExtListFlat = partnersExtLists.reduce(@(res, v) res.extend(v), [])
  let isAvailableAllSwitch = Watched(isAnyPartnerConsentSwitchesAvailable(partnersExtListFlat))
  let getPartnersAllVal = @() isAllPartnerConsentSwitchesEnabled(partnersExtListFlat)
  let isPartnersAllEnabled = Watched(getPartnersAllVal())
  let onManualPartnersAllSwitch = @(v) updatePartnersList(partnersExtListFlat, v)
  let onManualPartnerSwitch = @(_) isPartnersAllEnabled.set(getPartnersAllVal())

  let list = [
    mkTextarea(loc("consent_tcf/partners/manage/desc"), fadedAndMinor.__merge(gapBelow))
    mkSwitch(loc("consent_tcf/partners/consentToAll"), isAvailableAllSwitch, isPartnersAllEnabled, onManualPartnersAllSwitch)
    mkTextarea(nbsp)
  ]
  foreach (idx, vl in partnersExtLists)
    if (vl.len()) {
      let { titleLocId } = vendorsListsCfg[idx]
      list.append(mkTextarea("".concat(loc(titleLocId), colon)), separatorLine)
      foreach (p in vl)
        list.append(mkPartnerSwitchComp(p, onManualPartnerSwitch, debugShowIds.get()), separatorLine)
    }
  return {
    watch = [vendorsLists, debugShowIds]
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = list
  }
}

return @() mkContent(loc("consent_tcf/partners/manage"), mkPartnersExtDesc, null, quitPartnersExt)
