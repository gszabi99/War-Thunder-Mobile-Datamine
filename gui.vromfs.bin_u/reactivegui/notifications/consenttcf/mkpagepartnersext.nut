from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/textButton.nut" import textButtonCommon, textButtonPrimary
from "%rGui/notifications/consentTcf/consentTcfState.nut" import isOpenedPartnersExt,
  doAnswerAllAndClose, doSaveAndClose, vendorsLists, vendorsListsCfg, getPurposesList, getSpecialPurposesList,
  getFeaturesList, getDataCategoiresList, mkPartnersExtLists, debugShowIds
from "%rGui/notifications/consentTcf/consentTcfComps.nut" import mkContent, mkTextarea, mkLink,
  separatorLine, openUrl, gapAbove, gapBelow, fadedAndMinor
from "%rGui/notifications/consentTcf/mkExpandableSwitch.nut" import mkExpandableSwitch, mkSwitch

const BQ_WND_ID = "consentPartners"

let quitPartnersExt = @() isOpenedPartnersExt.set(false)

let bullet = loc("ui/bullet")

function mkPurposesBulletedList(titleLocId, idList, dataList, retention, isEnabledKey, needShowId) {
  if (idList.len() == 0)
    return []
  let bulletedTextComps = dataList
    .filter(@(v) idList.contains(v.info.id))
    .map(function(v) {
        let { id, name } = v.info
        let title = needShowId ? $"[{id}] {name}" : name
        let retentionDays = retention?[id.tostring()]
        let retentionTxt = retentionDays == null ? ""
          : "".concat(loc("consent_tcf/dataRetentionPeriod"), colon, loc("measureUnits/full/days", { n = retentionDays }))
        let isEnabledVal = v?[isEnabledKey].get()
        let enabledTxt = isEnabledVal == null ? "" : loc(isEnabledVal ? "options/on" : "options/off")
        return mkTextarea("".concat(bullet, title,
            retentionTxt == "" ? "" : loc("ui/parentheses/space", { text = retentionTxt }),
            enabledTxt == "" ? "" : loc("ui/parentheses/space", { text = enabledTxt })
          ), fadedAndMinor)
      })
  return [ mkTextarea(loc(titleLocId), gapAbove) ].extend(bulletedTextComps)
}

function mkPartnerSwitchComp(partner, onManualSwitch, needShowId) {
  let { info, isExpanded, isAvailable, isEnabled, isAvailableLIT, isEnabledLIT, listCfg } = partner
  let { itemToPartnerData } = listCfg
  let { policy, legIntClaim } = itemToPartnerData(info)
  let { id = null, name, purposes = [], specialPurposes = [], features = [], legIntPurposes = [], dataDeclaration = [],
    dataRetention = {}, deviceStorageDisclosureUrl = "", cookieMaxAgeSeconds = 0 } = info
  let title = needShowId ? $"[{id}] {name}" : name
  let purposesAll = getPurposesList()
  let purposesSpecialAll = getSpecialPurposesList()
  let purposesRetention = dataRetention?.purposes
  let specialPurposesRetention = dataRetention?.specialPurposes
  let featuresAll = getFeaturesList()
  let dataCategoriesAll = getDataCategoiresList()
  let needDeviceStorageSection = cookieMaxAgeSeconds != 0 || deviceStorageDisclosureUrl != ""
  let emptyLine = mkTextarea(nbsp)
  return mkExpandableSwitch(title, isAvailable, isEnabled, onManualSwitch, isExpanded, function() {
    let list = [
      emptyLine
      mkLink(loc("consent_tcf/partners/policy"), @() openUrl(policy))
    ]
      .extend(mkPurposesBulletedList("consent_tcf/partners/purposes/consent",
        purposes, purposesAll, purposesRetention, "isEnabled", needShowId))
      .extend(mkPurposesBulletedList("consent_tcf/manage/specialPurposes",
        specialPurposes, purposesSpecialAll, specialPurposesRetention, null, needShowId))
      .extend(mkPurposesBulletedList("consent_tcf/manage/features",
        features, featuresAll, null, null, needShowId))
      .append(isEnabledLIT == null && legIntClaim == "" ? null : emptyLine)
      .append(isEnabledLIT == null ? null
        : mkSwitch(loc("consent_tcf/manage/legitimateInterest"), isAvailableLIT, isEnabledLIT, onManualSwitch))
      .append(legIntClaim == "" ? null
        : mkLink(loc("consent_tcf/partners/legitimateInterest"), @() openUrl(legIntClaim), gapBelow))
      .extend(mkPurposesBulletedList("consent_tcf/partners/purposes/legitimateInterest",
        legIntPurposes, purposesAll, null, "isEnabledLIT", needShowId))
      .extend(mkPurposesBulletedList("consent_tcf/partners/data",
        dataDeclaration, dataCategoriesAll, null, null, needShowId))
      .append(!needDeviceStorageSection ? null
        : mkTextarea(loc("consent_tcf/partners/storage"), gapAbove))
      .append(deviceStorageDisclosureUrl == "" ? null
        : mkLink(loc("consent_tcf/partners/device"), @() openUrl(deviceStorageDisclosureUrl)))
      .append(cookieMaxAgeSeconds == 0 ? null
        : mkTextarea("".concat(loc("consent_tcf/maxDataRetentionPeriod"), colon,
            loc("measureUnits/full/days", { n = cookieMaxAgeSeconds / 86400 })), fadedAndMinor))
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
    mkSwitch(loc("consent_tcf/partners/consentToAll"),
      isAvailableAllSwitch, isPartnersAllEnabled, onManualPartnersAllSwitch)
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

let partnersExtButtons = [
  textButtonCommon(utf8ToUpper(loc("consentWnd/manage/acceptChoosen")), @() doSaveAndClose(BQ_WND_ID))
  {size = flex()}
  textButtonPrimary(utf8ToUpper(loc("consentWnd/manage/acceptAll")), @() doAnswerAllAndClose(BQ_WND_ID, true))
]

return @() mkContent(loc("consent_tcf/partners/manage"), mkPartnersExtDesc, partnersExtButtons, quitPartnersExt)
