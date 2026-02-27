from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/legal.nut" import PRIVACY_POLICY_URL
from "%rGui/components/textButton.nut" import textButtonCommon, textButtonPrimary
from "%rGui/notifications/consentTcf/consentTcfState.nut" import showPurposeInfo, isOpenedManage, isOpenedPartnersExt,
  doAnswerAllAndClose, doSaveAndClose, getPurposesList, getSpecialPurposesList, getFeaturesList,
  debugShowIds, PRIVACY_CHOICES_SAVED_MONTHS
from "%rGui/notifications/consentTcf/consentTcfComps.nut" import mkContent, mkStatusContent, mkTextarea,
  mkTextareaWithLinks, mkLink, openUrl, separatorLine, gapAbove, gapBelow, fadedAndMinor, fontMinor
from "%rGui/notifications/consentTcf/mkExpandableSwitch.nut" import mkExpandableSwitch, mkSwitch, mkExpandable

const BQ_WND_ID = "consentManage"

let quitManage = @() isOpenedManage.set(false)

function mkPurposeSwitchComp(purpose, onManualSwitch, needShowId) {
  let { info, getVendorList, isExpanded, isEnabled, isEnabledLIT } = purpose
  let { id, name, description } = info
  let title = needShowId ? $"[{id}] {name}" : name
  return mkExpandableSwitch(title, null, isEnabled, onManualSwitch, isExpanded, @() [
    mkTextarea(description, fadedAndMinor),
    mkLink(loc("readMore"), @() showPurposeInfo.set({ info, getVendorList })),
    isEnabledLIT == null ? null : mkSwitch(loc("consent_tcf/manage/legitimateInterest"), null, isEnabledLIT, onManualSwitch)
  ])
}

function mkFeatureComp(feature) {
  let { info, getVendorList, isExpanded } = feature
  let { name, description } = info
  return mkExpandable(name, isExpanded, @() [
    mkTextarea(description, fadedAndMinor),
    mkLink(loc("readMore"), @() showPurposeInfo.set({ info, getVendorList })),
  ])
}

let isPurposesOtherExpanded = Watched(false)

let isAllListedPurposesEnabled = @(list) list.findindex(@(p) !p.isEnabled.get()) == null

function updatePurposesList(list, v) {
  foreach (p in list)
    p.isEnabled.set(v)
}

let mkManageDesc = @() function() {
  let purposesAll = getPurposesList()
  if (purposesAll.len() == 0)
    return mkStatusContent(loc("ui/empty"))

  let purposeFirst = purposesAll[0]
  let purposesOther = purposesAll.slice(1)

  local purOtherTitle = loc("consent_tcf/manage/purposes/other")
  if (debugShowIds.get()) {
    let idsTxt = ",".join(purposesOther.map(@(v) v.info.id))
    purOtherTitle = $"[{idsTxt}] {purOtherTitle}"
  }

  let getPurAllVal = @() isAllListedPurposesEnabled(purposesAll)
  let isPurAllEnabled = Watched(getPurAllVal())
  let getPurOtherVal = @() isAllListedPurposesEnabled(purposesOther)
  let isPurOtherEnabled = Watched(getPurOtherVal())

  let updateHeadPurAll = @() isPurAllEnabled.set(getPurAllVal())
  let updateHeadPurOther = @() isPurOtherEnabled.set(getPurOtherVal())

  function onManualPurOtherSwitchHead(v) {
    updatePurposesList(purposesOther, v)
    updateHeadPurAll()
  }

  function onManualPurAllSwitchHead(v) {
    updatePurposesList(purposesAll, v)
    updateHeadPurOther()
  }

  function onManualPurposeSwitch(_) {
    updateHeadPurAll()
    updateHeadPurOther()
  }

  let specPurposes = []
  foreach (v in getSpecialPurposesList())
    specPurposes.append(separatorLine, mkFeatureComp(v))
  specPurposes.append(separatorLine)

  let features = []
  foreach (v in getFeaturesList())
    features.append(separatorLine, mkFeatureComp(v))
  features.append(separatorLine)

  let children = [
    mkTextarea(loc("consent_tcf/manage/desc/p1"), fadedAndMinor.__merge(gapBelow))
    mkTextarea(loc("consent_tcf/manage/desc/p2"), fadedAndMinor.__merge(gapBelow))
    mkTextarea(loc("consent_tcf/manage/desc/p3v2"), fadedAndMinor.__merge(gapBelow))
    mkTextareaWithLinks(loc("consent_tcf/manage/desc/p4", { monthsCount = PRIVACY_CHOICES_SAVED_MONTHS }), {
      ["{privacyPolicyLink}"] = mkLink(loc("consent_tcf/manage/desc/p4/privacyPolicyLink"), 
        @() openUrl(PRIVACY_POLICY_URL), fontMinor)
    }, fadedAndMinor)
    mkTextarea(nbsp)
    mkSwitch(loc("consent_tcf/manage/consentToAll"), null, isPurAllEnabled, onManualPurAllSwitchHead)
    mkTextarea("".concat(loc("consent_tcf/manage/purposes"), colon), gapAbove)
    separatorLine
    mkPurposeSwitchComp(purposeFirst, onManualPurposeSwitch, debugShowIds.get())
    separatorLine
    mkExpandableSwitch(purOtherTitle, null, isPurOtherEnabled, onManualPurOtherSwitchHead,
        isPurposesOtherExpanded, function() {
      let subList = []
      foreach (v in purposesOther)
        subList.append(separatorLine, mkPurposeSwitchComp(v, onManualPurposeSwitch, debugShowIds.get()))
      return subList
    })
    separatorLine
    mkTextarea("".concat(loc("consent_tcf/manage/specialPurposes"), colon), gapAbove)
  ]
    .extend(specPurposes)
    .append(mkTextarea("".concat(loc("consent_tcf/manage/features"), colon), gapAbove))
    .extend(features)
    .append(mkTextarea("".concat(loc("consent_tcf/partners"), colon), gapAbove),
      mkLink(loc("consent_tcf/partners/manage"), @() isOpenedPartnersExt.set(true)))

  return {
    watch = debugShowIds
    size = FLEX_H
    flow = FLOW_VERTICAL
    children
  }
}

let manageButtons = [
  textButtonCommon(utf8ToUpper(loc("consentWnd/manage/acceptChoosen")), @() doSaveAndClose(BQ_WND_ID))
  {size = flex()}
  textButtonPrimary(utf8ToUpper(loc("consentWnd/manage/acceptAll")), @() doAnswerAllAndClose(BQ_WND_ID, true))
]

let lastScrollPosY = Watched(0)
isOpenedManage.subscribe(@(v) v ? lastScrollPosY.set(0) : null)

return @() mkContent(loc("consent_tcf/intro/managePreferences"), mkManageDesc, manageButtons, quitManage, lastScrollPosY)
