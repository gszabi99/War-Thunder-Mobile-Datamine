

from "%globalsDarg/darg_library.nut" import *
from "json" import parse_json
from "eventbus" import eventbus_send, eventbus_subscribe
from "console" import register_command
from "dagor.workcycle" import resetTimeout
from "appsFlyer" import startAppsFlyer
from "auth_wt" import getCountryCode
from "blkGetters" import get_local_custom_settings_blk
from "consent" import isConsentInited, initConsent, isConsentGiven, isVendorDataLoaded, loadVendorData, unloadVendorData,
  getAllIABVendors, getAllGoogleVendors, setConsentForAll, saveConsentData, getAllPurposes, getAllSpecialPurposes,
  getAllFeatures, hasConsentForPurpose, hasPurposeLIT, getVendorListByPurposeId, getVendorListBySpecialPurposeId,
  getVendorListByFeatureId, hasConsentForIABVendor, setConsentForIABVendor, hasConsentForGoogleVendor, setConsentForGoogleVendor,
  hasVendorLIT, setVendorLIT, getAllDataCategories
from "%appGlobals/loginState.nut" import isReadyForTcfConsent, isTcfConsentAllowLogin, isLoggedIn, TCF_CONSENT_ACCEPTED_SAVE_ID
from "%appGlobals/permissions.nut" import tcf_consent_enabled, request_firebase_consent_eu_only
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent
from "%rGui/login/stateIDFA.nut" import isIdfaDenied
from "%rGui/style/stdAnimations.nut" import WND_REVEAL
let logC = log_with_prefix("[consent] ")

let { getAllCustomVendors = @() "[]" } = require("consent")


let TCF_CONSENT_COUNTRIES = ["AT","BE","BG","CH","CY","CZ","DE","DK","EE","EL","ES","FI","FR","GB","GR",
  "HR","HU","IE","IS","IT","LI","LT","LU","LV","MT","NL","NO","PL","PT","RO","SE","SI","SK","UK"]
let isTcfConsentRequiredForCountry = Computed(@() !request_firebase_consent_eu_only.get() || TCF_CONSENT_COUNTRIES.contains(getCountryCode()))

let PURPOSES_WITH_LEGITIMATE_INTEREST = [
  2,  
  7,  
  8,  
  9,  
  10, 
  11, 
]

let isOpenForProfileWnd = mkWatched(persist, "isOpenForProfileWnd", false)
let needSkipIntroPage = isOpenForProfileWnd
let isTcfConsentAutoSkipped = mkWatched(persist, "isTcfConsentAutoSkipped", false)
let isConsentInitializing = mkWatched(persist, "isConsentInitializing", false)
let isVendorDataLoading = mkWatched(persist, "isVendorDataLoading", false)
let isLoadError = mkWatched(persist, "isLoadError", false)
let needSaveChoices = mkWatched(persist, "needSaveChoices", false)
let isOpenedConsentTcfWnd = mkWatched(persist, "isOpenedConsentTcfWnd", false)
let isOpenedPartners = mkWatched(persist, "isOpenedPartners", false)
let isOpenedPartnersExt = mkWatched(persist, "isOpenedPartnersExt", false)
let isOpenedManage = mkWatched(persist, "isOpenedManage", false)
let showPurposeInfo = mkWatched(persist, "showPurposeInfo", null)
let vendorsLists = mkWatched(persist, "vendorsLists", [])
let totalPartners = Computed(@() vendorsLists.get().reduce(@(res, v) res + v.len(), 0))

let userLangId = loc("current_lang")

let dataCache = {}

let vendorsListsCfg = [
  {
    getInfo = @() parse_json(getAllIABVendors())
    hasConsentForVendor = hasConsentForIABVendor
    setConsentForVendor = setConsentForIABVendor
    hasConsentForVendorLIT = hasVendorLIT
    setConsentForVendorLIT = setVendorLIT
    shouldHavePurposesList = true
    titleLocId = "consent_tcf/partners/iab"
    itemToPartnerData = @(v) {
      id = v.id
      name = v.name
      policy = (v.urls.findvalue(@(u) u.langId == userLangId) ?? v.urls.findvalue(@(u) u.langId == "en") ?? v.urls.findvalue(@(_) true))?.privacy ?? ""
      legIntClaim = (v.urls.findvalue(@(u) u.langId == userLangId) ?? v.urls.findvalue(@(u) u.langId == "en") ?? v.urls.findvalue(@(_) true))?.legIntClaim ?? ""
    }
  }
  {
    getInfo = @() parse_json(getAllGoogleVendors())
    hasConsentForVendor = hasConsentForGoogleVendor
    setConsentForVendor = setConsentForGoogleVendor
    hasConsentForVendorLIT = null
    setConsentForVendorLIT = null
    shouldHavePurposesList = false
    titleLocId = "consent_tcf/partners/google"
    itemToPartnerData = @(v) v.__merge({ legIntClaim = "" })
  }
  {
    getInfo = @() parse_json(getAllCustomVendors())
    hasConsentForVendor = null
    setConsentForVendor = null
    hasConsentForVendorLIT = null
    setConsentForVendorLIT = null
    shouldHavePurposesList = false
    titleLocId = "consent_tcf/partners/other"
    itemToPartnerData = @(v) v.__merge({ legIntClaim = "" })
  }
]

tcf_consent_enabled.subscribe(@(v) v ? null : isOpenedConsentTcfWnd.set(false))

const CONTINUE_LOGIN = "doContinueLogin"
let doOnceOnFinishCbId = mkWatched(persist, "doOnceOnFinishCbId", "")
let onFinishCbById = {
  [CONTINUE_LOGIN] = @() isTcfConsentAllowLogin.set(true)
}

function setupAnalytics() {
  logC("TCF Consent, analytics starting")
  startAppsFlyer()
}

function saveToLocalStorage() {
  local res = false
  foreach (p in parse_json(getAllPurposes()))
    if (hasConsentForPurpose(p.id) || hasPurposeLIT(p.id)) {
      res = true
      break
    }
  get_local_custom_settings_blk()[TCF_CONSENT_ACCEPTED_SAVE_ID] <- res
  eventbus_send("saveProfile", {})
}

function onConsentDataSaved() {
  if (isVendorDataLoaded()) {
    unloadVendorData()
    logC("TCF Consent vendors unloaded")
  }
  vendorsLists.set([])
  dataCache.clear()
}

eventbus_subscribe("consent.onSaveConsentData", function(p) {
  logC($"TCF Consent onSaveConsentData ({p.success})")
  onConsentDataSaved()
})

function doOnFinish() {
  onFinishCbById?[doOnceOnFinishCbId.get()]?()
  doOnceOnFinishCbId.set("")
  isOpenForProfileWnd.set(false)
  isOpenedPartners.set(false)
  isOpenedPartnersExt.set(false)
  isOpenedManage.set(false)
  showPurposeInfo.set(null)
  setupAnalytics()
  if (needSaveChoices.get()) {
    logC($"TCF Consent saving... (isVendorDataLoaded() = {isVendorDataLoaded()})")
    needSaveChoices.set(false)
    saveConsentData()
    isTcfConsentAutoSkipped.set(false)
    saveToLocalStorage()
  }
  else
    onConsentDataSaved()
}

isOpenedConsentTcfWnd.subscribe(function(v) {
  if (v) {
    let isStartup = !isOpenForProfileWnd.get()
    logC(isStartup ? "TCF Consent opened at startup" : "TCF Consent opened from Privacy")
    sendUiBqEvent("ads_consent_tcf", { id = isStartup ? "consent_open_at_start" : "consent_open_from_privacy" })
  }
  else {
    doOnFinish()
    isLoadError.set(false)
  }
})

function onVendorDataLoaded(isSuccess) {
  isLoadError.set(!isSuccess)
  if (!isSuccess && !isOpenForProfileWnd.get())
    sendUiBqEvent("ads_consent_tcf", { id = "consent_failed", from = "loadVendorData", status = getCountryCode() })
  let isGiven = isConsentGiven()
  if (!isSuccess || (isGiven && !isOpenForProfileWnd.get())) {
    isVendorDataLoading.set(false)
    doOnFinish()
    return
  }

  if (!isGiven && !isTcfConsentRequiredForCountry.get()) {
    logC($"TCF Consent auto accepted for country {getCountryCode()}")
    sendUiBqEvent("ads_consent_tcf", { id = "consent_accept_by_region" })
    setConsentForAll(true)
    needSaveChoices.set(true)
    doOnFinish()
    return
  }

  vendorsLists.set(vendorsListsCfg.map(@(v) v.getInfo()))
  isVendorDataLoading.set(false)
  isOpenedConsentTcfWnd.set(true)
  if (needSkipIntroPage.get())
    isOpenedManage.set(true)
}

function onInited(isSuccess) {
  isConsentInitializing.set(false)
  isLoadError.set(!isSuccess)
  if (!isSuccess && !isOpenForProfileWnd.get())
    sendUiBqEvent("ads_consent_tcf", { id = "consent_failed", from = "initConsent", status = getCountryCode() })
  let isGiven = isConsentGiven()

  if (!isSuccess || (isGiven && !isOpenForProfileWnd.get())) {
    doOnFinish()
    return
  }

  if (!isGiven && isIdfaDenied.get()) {
    logC("TCF Consent auto skipped by denied IDFA")
    sendUiBqEvent("ads_consent_tcf", { id = "consent_skip_by_denied_idfa" })
    isTcfConsentAutoSkipped.set(true) 
    doOnFinish()
    return
  }

  isVendorDataLoading.set(true)
  if (!isVendorDataLoaded())
    loadVendorData(userLangId)
  else
    onVendorDataLoaded(true)
}
eventbus_subscribe("consent.onLoadVendorData", function(p) {
  logC($"TCF Consent onLoadVendorData ({p.success})")
  onVendorDataLoaded(p.success)
})

function startInit(onCloseOrErrorCbId, isForProfileWnd) {
  isOpenForProfileWnd.set(isForProfileWnd)
  doOnceOnFinishCbId.set(onCloseOrErrorCbId)
  if (!isConsentInited()) {
    isConsentInitializing.set(true)
    initConsent()
  }
  else
    onInited(true)
}
eventbus_subscribe("consent.onInit", function(p) {
  logC($"TCF Consent onInit ({p.success})")
  onInited(p.success)
})

function onReadyTcf(isReady) {
  if (!isReady)
    return
  if (isLoggedIn.get()) {
    onFinishCbById[CONTINUE_LOGIN]()
    return
  }
  if (!tcf_consent_enabled.get()) {
    logC("TCF Consent disabled")
    onFinishCbById[CONTINUE_LOGIN]()
    return
  }
  startInit(CONTINUE_LOGIN, false)
}
onReadyTcf(isReadyForTcfConsent.get())
isReadyForTcfConsent.subscribe(onReadyTcf)

function openTcfConsentWnd() {
  
  isOpenForProfileWnd.set(true)
  isOpenedConsentTcfWnd.set(true)
  resetTimeout(WND_REVEAL, @() startInit(null, true))
}

function doSkipClose() {
  logC("TCF Consent skipped")
  if (!isOpenForProfileWnd.get())
    sendUiBqEvent("ads_consent_tcf", { id = "consent_skip" })
  isOpenedConsentTcfWnd.set(false)
}

function doSaveAndClose(src) {
  if (!tcf_consent_enabled.get())
    return isOpenedConsentTcfWnd.set(false)
  let from = "/".concat(isOpenForProfileWnd.get() ? "profile" : "login", src)
  logC($"TCF Consent saved from {from} action accept_chosen")
  sendUiBqEvent("ads_consent_tcf", { id = "consent_save", from, status = "accept_chosen" })
  needSaveChoices.set(true)
  isOpenedConsentTcfWnd.set(false)
}

function doAnswerAllAndClose(src, isAccept) {
  if (!tcf_consent_enabled.get())
    return isOpenedConsentTcfWnd.set(false)
  let status = isAccept ? "accept_all" : "accept_none"
  let from = "/".concat(isOpenForProfileWnd.get() ? "profile" : "login", src)
  logC($"TCF Consent saved from {from} action {status}")
  sendUiBqEvent("ads_consent_tcf", { id = "consent_save", from, status })
  setConsentForAll(isAccept)
  needSaveChoices.set(true)
  isOpenedConsentTcfWnd.set(false)
}

function mkPurposeCfg(purposeiInfo) {
  let { id } = purposeiInfo
  return {
    info = purposeiInfo
    getVendorList = @() parse_json(getVendorListByPurposeId(id))
    isEnabled = Watched(hasConsentForPurpose(id))
    isEnabledLIT = !PURPOSES_WITH_LEGITIMATE_INTEREST.contains(id) ? null : Watched(hasPurposeLIT(id))
    isExpanded = Watched(false)
  }
}

function mkSpecPurposeCfg(specPurposeInfo) {
  let { id } = specPurposeInfo
  return {
    info = specPurposeInfo
    getVendorList = @() parse_json(getVendorListBySpecialPurposeId(id))
    isExpanded = Watched(false)
  }
}

function mkFeatureCfg(featureInfo) {
  let { id } = featureInfo
  return {
    info = featureInfo
    getVendorList = @() parse_json(getVendorListByFeatureId(id))
    isExpanded = Watched(false)
  }
}

function mkPartnerExtCfg(partnerInfo, partnersListIdx) {
  let { id = null, purposes = [], legIntPurposes = [] } = partnerInfo
  let listCfg = vendorsListsCfg[partnersListIdx]
  let { shouldHavePurposesList, hasConsentForVendor, hasConsentForVendorLIT } = listCfg
  return {
    info = partnerInfo
    isEnabled = ((!shouldHavePurposesList || purposes.len()) && hasConsentForVendor != null)
      ? Watched(hasConsentForVendor(id))
      : null
    isEnabledLIT = legIntPurposes.len() ? Watched(hasConsentForVendorLIT(id)) : null
    isExpanded = Watched(false)
    listCfg
  }
}

function getPurposesList() {
  if (dataCache?.purposesList == null)
    dataCache.purposesList <- parse_json(getAllPurposes()).map(mkPurposeCfg)
  return dataCache.purposesList
}

function getSpecialPurposesList() {
  if (dataCache?.specialPurposesList == null)
    dataCache.specialPurposesList <- parse_json(getAllSpecialPurposes()).map(mkSpecPurposeCfg)
  return dataCache.specialPurposesList
}

function getFeaturesList() {
  if (dataCache?.featuresList == null)
    dataCache.featuresList <- parse_json(getAllFeatures()).map(mkFeatureCfg)
  return dataCache.featuresList
}

let mkPartnersExtLists = @(vendorsListsVal) vendorsListsVal.map(@(l, lIdx) l.map(@(v) mkPartnerExtCfg(v, lIdx)))

function getDataCategoiresList() {
  if (dataCache?.dataCategoriesList == null)
    dataCache.dataCategoriesList <- { info = parse_json(getAllDataCategories()) }
  return dataCache.dataCategoriesList
}

register_command(function() {
  get_local_custom_settings_blk()[TCF_CONSENT_ACCEPTED_SAVE_ID] <- null
  eventbus_send("saveProfile", {})
}, "ui.tcf_consent_saved_status.reset")

return {
  isTcfConsentRequiredForCountry
  openTcfConsentWnd
  needSkipIntroPage
  isTcfConsentAutoSkipped

  isOpenedConsentTcfWnd
  isConsentInitializing
  isVendorDataLoading
  isLoadError

  userLangId
  isOpenedPartners
  isOpenedPartnersExt
  isOpenedManage
  showPurposeInfo

  vendorsListsCfg
  vendorsLists
  totalPartners
  getPurposesList
  getSpecialPurposesList
  getFeaturesList
  getDataCategoiresList
  mkPartnersExtLists

  doAnswerAllAndClose
  doSaveAndClose
  doSkipClose
}
