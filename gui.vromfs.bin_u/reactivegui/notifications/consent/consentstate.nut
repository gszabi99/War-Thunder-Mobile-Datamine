from "%globalsDarg/darg_library.nut" import *
let logC = log_with_prefix("[consent] ")
let { deferOnce } = require("dagor.workcycle")
let { eventbus_send } = require("eventbus")
let { isConsentAllowLogin, isReadyForConsent, CONSENT_OPTIONS_SAVE_ID } = require("%appGlobals/loginState.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { is_ios, is_android } = require("%appGlobals/clientState/platform.nut")
let { setCollectionEnabled = @(_) null,
      setFirebaseConsent = @(_) null } = is_android ? require("android.firebase.analytics")
    : is_ios ? require("ios.firebase.analytics")
    : {}
let { setAppsFlyerConsent, startAppsFlyer } = require("appsFlyer")
let { object_to_json_string } = require("json")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isIdfaDenied } = require("%rGui/login/stateIDFA.nut")
let { request_firebase_consent_eu_only } = require("%appGlobals/permissions.nut")
let { getCountryCode } = require("auth_wt")


let EU_REGION = ["BE","BG","CZ","DK","DE","EE","IE","GR","EL","ES","FR","HR","HU","IT","CY","LV","LT","LU","MT","NL","AT","PL","PT","RO","SI","SK","FI","SE","GB","UK","LI","NO","IS","CH"]

let configManagePoints = [
  {
    id = "analytics_storage"
    loc = "consentWnd/manage/desc/analytics_storage"
  }
  {
    id = "ad_storage"
    loc = "consentWnd/manage/desc/ad_storage"
  }
  {
    id = "ad_user_data"
    loc = "consentWnd/manage/desc/ad_user_data"
  }
  {
    id = "ad_personalization"
    loc = "consentWnd/manage/desc/ad_personalization"
  }
]

let defaultPointsTable = configManagePoints.reduce(@(res, val) res.$rawset(val.id, true), {})

let savedPoints = mkWatched(persist, "savedPoints", null)
let points = Computed(@() defaultPointsTable.map(@(v, k) savedPoints.get()?[k] ?? v))

let isConsentAcceptedOnce = Computed(@() (savedPoints.get()?.len() ?? 0) != 0)

let consentRequiredForCurrentRegion = Computed(@() !request_firebase_consent_eu_only.get() || EU_REGION.indexof(getCountryCode()) != null)
let needOpenConsentWnd = mkWatched(persist, "consentMainWnd", false)
let isConsentWasAutoSkipped = mkWatched(persist, "isConsentWasAutoSkipped", false)
let needForceOpenConsetnWnd    = Computed(@() savedPoints.get() != null && !isConsentAcceptedOnce.get() && !isIdfaDenied.get())
let needSkipConsentWnd = keepref(Computed(@() savedPoints.get() != null && !isConsentAcceptedOnce.get() && isIdfaDenied.get()))
let needSkipForCurrentRegion = keepref(Computed(@() isReadyForConsent.get() && !consentRequiredForCurrentRegion.get()))

let isOpenedConsentWnd = Computed(@()
  (needOpenConsentWnd.get() || needForceOpenConsetnWnd.get())
  && isReadyForConsent.get() && consentRequiredForCurrentRegion.get())

function setupAnalytics() {
  let v = savedPoints.get()
  logC("analytics starting with consent:", v)
  setFirebaseConsent(object_to_json_string(v))
  setCollectionEnabled(true)
  setAppsFlyerConsent(v?.ad_user_data ?? false, v?.ad_personalization ?? false, !consentRequiredForCurrentRegion.get())
  startAppsFlyer()
}

function autoSkipConsent() {
  if (isConsentAcceptedOnce.get())
    return
  savedPoints(defaultPointsTable.map(@(_) false))
  logC("consent skipped by denied IDFA")
  sendUiBqEvent("ads_consent_firebase", { id = "consent_skip_by_denied_idfa" })
  setupAnalytics()
  isConsentWasAutoSkipped.set(true)
}

function autoAcceptForNonEURegion() {
  if (isConsentAcceptedOnce.get())
    return
  logC("consent auto accepted for non EU region",getCountryCode())
  savedPoints(defaultPointsTable.map(@(_) true))
  sendUiBqEvent("ads_consent_firebase", { id = "consent_skip_by_region" })
  setupAnalytics()
}

needSkipConsentWnd.subscribe(@(v) v ? deferOnce(autoSkipConsent) : null)

needSkipForCurrentRegion.subscribe(@(v) v ? deferOnce(autoAcceptForNonEURegion) : null)

if (needSkipForCurrentRegion.get())
  autoAcceptForNonEURegion()

let function loadPoints(){
  let res = {}
  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk?[CONSENT_OPTIONS_SAVE_ID]
  if(!blk){
    savedPoints({})
    return
  }
  if (isDataBlock(blk))
    eachParam(blk, @(v, id) res[id] <- v)
  savedPoints(res)
  setupAnalytics() 
}

isConsentAcceptedOnce.subscribe(@(v) v ? isConsentAllowLogin.set(true) : null)

if (isConsentAcceptedOnce.get())
  isConsentAllowLogin.set(true)

if (savedPoints.get() == null && isReadyForConsent.get())
  loadPoints()

function onOnlineSettingsNOTAvailable(){
  isConsentAllowLogin.set(false)
  savedPoints(null)
}
isReadyForConsent.subscribe(@(v) v ? loadPoints(): onOnlineSettingsNOTAvailable())

savedPoints.subscribe(@(_) isConsentWasAutoSkipped.set(false))

let isOpenedManage = mkWatched(persist, "consentManage", false)
let isOpenedPartners = mkWatched(persist, "consentPartners", false)

isOpenedConsentWnd.subscribe(function(v){
  if(v){
    logC($"run consent at startup")
    sendUiBqEvent("ads_consent_firebase", { id = "consent_open_at_start" })
  }
})

isOpenedManage.subscribe(function(v) {
  if (v && !isOpenedConsentWnd.get()) {
    logC("run manage consent from privacy")
    sendUiBqEvent("ads_consent_firebase", { id = "consent_open_from_privacy" })
  }
})

function applyConsent(pointsTable, source){
  logC($"consent saved from windows {source.wnd} action {source.action}", pointsTable)
  sendUiBqEvent("ads_consent_firebase", {
    id = "consent_save",
    from = source.wnd,
    status = source.action,
    values = object_to_json_string(pointsTable)
  })
  savedPoints(pointsTable)
  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(CONSENT_OPTIONS_SAVE_ID)
  foreach(k, v in pointsTable){
    blk[k] = v
  }
  eventbus_send("saveProfile", {})
  isOpenedManage(false)
  needOpenConsentWnd(false)

  setupAnalytics()
}

register_command(
  function(){
    let sBlk = get_local_custom_settings_blk()
    sBlk.removeBlock(CONSENT_OPTIONS_SAVE_ID)
    eventbus_send("saveProfile", {})
  },
  "ui.removeConsentUserData")

return {
  CONSENT_OPTIONS_SAVE_ID

  needOpenConsentWnd
  isOpenedConsentWnd
  isOpenedManage
  isOpenedPartners
  isConsentAcceptedOnce
  isConsentWasAutoSkipped
  applyConsent
  setupAnalytics
  consentRequiredForCurrentRegion

  points
  defaultPointsTable
  savedPoints
}