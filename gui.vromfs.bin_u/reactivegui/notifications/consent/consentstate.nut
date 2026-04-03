from "%globalsDarg/darg_library.nut" import *
let logC = log_with_prefix("[consent] ")
let { deferOnce } = require("dagor.workcycle")
let { eventbus_send } = require("eventbus")
let { isConsentAllowLogin, isReadyForConsent, CONSENT_OPTIONS_SAVE_ID } = require("%appGlobals/loginState.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { is_ios, is_android } = require("%sqstd/platform.nut")
let { setCollectionEnabled = @(_) null,
      setFirebaseConsent = @(_) null } = is_android ? require("android.firebase.analytics")
    : is_ios ? require("ios.firebase.analytics")
    : {}
let { setAppsFlyerConsent, startAppsFlyer, enableTCFCollection = @(_) null } = require("appsFlyer")
let { object_to_json_string } = require("json")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isIdfaDenied } = require("%rGui/login/stateIDFA.nut")
let { request_firebase_consent_eu_only, tcf_consent_enabled } = require("%appGlobals/permissions.nut")
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

let isEnabled = keepref(Computed(@() !tcf_consent_enabled.get()))
let isConsentAcceptedOnce = Computed(@() (savedPoints.get()?.len() ?? 0) != 0)
let consentRequiredForCurrentRegion = Computed(@() !request_firebase_consent_eu_only.get() || EU_REGION.indexof(getCountryCode()) != null)
let needOpenConsentWnd = mkWatched(persist, "consentMainWnd", false)
let isConsentWasAutoSkipped = mkWatched(persist, "isConsentWasAutoSkipped", false)
let needForceOpenConsetnWnd    = Computed(@() savedPoints.get() != null && !isConsentAcceptedOnce.get() && !isIdfaDenied.get())
let needSkipConsentWnd = keepref(Computed(@() savedPoints.get() != null && !isConsentAcceptedOnce.get() && isIdfaDenied.get()))
let needSkipForCurrentRegion = keepref(Computed(@() isReadyForConsent.get() && !consentRequiredForCurrentRegion.get()))

let isOpenedConsentWnd = Computed(@()
  isEnabled.get()
  && (needOpenConsentWnd.get() || needForceOpenConsetnWnd.get())
  && isReadyForConsent.get() && consentRequiredForCurrentRegion.get())

function setupAnalytics() {
  if (!isEnabled.get())
    return
  let v = savedPoints.get()
  enableTCFCollection(false)
  logC("Firebase consent, analytics starting:", v)
  setFirebaseConsent(object_to_json_string(v))
  setCollectionEnabled(true)
  setAppsFlyerConsent(v?.ad_user_data ?? false, v?.ad_personalization ?? false, true)
  startAppsFlyer()
}

function autoSkipConsent() {
  if (!isEnabled.get() || isConsentAcceptedOnce.get())
    return
  savedPoints.set(defaultPointsTable.map(@(_) false))
  isConsentWasAutoSkipped.set(true)
  logC("Firebase consent skipped by denied IDFA")
  sendUiBqEvent("ads_consent_firebase", { id = "consent_skip_by_denied_idfa" })
  setupAnalytics()
}

function autoAcceptForNonEURegion() {
  if (!isEnabled.get() || isConsentAcceptedOnce.get())
    return
  logC($"Firebase consent auto accepted for non EU region: {getCountryCode()}")
  savedPoints.set(defaultPointsTable.map(@(_) true))
  sendUiBqEvent("ads_consent_firebase", { id = "consent_skip_by_region" })
  setupAnalytics()
}

needSkipConsentWnd.subscribe(@(v) v ? deferOnce(autoSkipConsent) : null)

needSkipForCurrentRegion.subscribe(@(v) v ? deferOnce(autoAcceptForNonEURegion) : null)
if (needSkipForCurrentRegion.get())
  autoAcceptForNonEURegion()

let function loadPoints() {
  if (!isEnabled.get())
    return
  let res = {}
  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk?[CONSENT_OPTIONS_SAVE_ID]
  if (!blk) {
    savedPoints.set({})
    return
  }
  if (isDataBlock(blk))
    eachParam(blk, @(v, id) res[id] <- v)
  savedPoints.set(res)
  setupAnalytics() 
}

isConsentAcceptedOnce.subscribe(@(v) v ? isConsentAllowLogin.set(true) : null)
if (isConsentAcceptedOnce.get())
  isConsentAllowLogin.set(true)

if (savedPoints.get() == null && isReadyForConsent.get())
  loadPoints()

function onOnlineSettingsNOTAvailable() {
  isConsentAllowLogin.set(false)
  savedPoints.set(null)
  isConsentWasAutoSkipped.set(false)
}
isReadyForConsent.subscribe(function(isReady) {
  if (!isEnabled.get()) {
    if (isReady) {
      logC("Firebase consent disabled")
      isConsentAllowLogin.set(true)
    }
    return
  }

  
  this_subscriber_call_may_take_up_to_usec(3 * get_slow_subscriber_threshold_usec())
  if (isReady)
    loadPoints()
  else
    onOnlineSettingsNOTAvailable()
})

let isOpenedManage = mkWatched(persist, "consentManage", false)
let isOpenedPartners = mkWatched(persist, "consentPartners", false)

isOpenedConsentWnd.subscribe(function(v){
  if (v) {
    let isAtStartup = !isConsentAllowLogin.get()
    logC(isAtStartup ? "Firebase consent run at startup" : "Firebase consent run from menu")
    sendUiBqEvent("ads_consent_firebase", { id = isAtStartup ? "consent_open_at_start" : "consent_open_from_privacy" })
  }
})

isOpenedManage.subscribe(function(v) {
  if (v && !isOpenedConsentWnd.get()) {
    logC("Firebase consent run manage from privacy")
    sendUiBqEvent("ads_consent_firebase", { id = "consent_open_from_privacy" })
  }
})

function applyConsent(pointsTable, source){
  logC($"Firebase consent saved from windows {source.wnd} action {source.action}", pointsTable)
  sendUiBqEvent("ads_consent_firebase", {
    id = "consent_save",
    from = source.wnd,
    status = source.action,
    values = object_to_json_string(pointsTable)
  })
  savedPoints.set(pointsTable)
  isConsentWasAutoSkipped.set(false)
  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(CONSENT_OPTIONS_SAVE_ID)
  foreach(k, v in pointsTable){
    blk[k] = v
  }
  eventbus_send("saveProfile", {})
  isOpenedManage.set(false)
  needOpenConsentWnd.set(false)

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