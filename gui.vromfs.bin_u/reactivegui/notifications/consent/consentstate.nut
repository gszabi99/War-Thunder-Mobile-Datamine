from "%globalsDarg/darg_library.nut" import *
let logC = log_with_prefix("[consent] ")
let { deferOnce } = require("dagor.workcycle")
let { eventbus_send } = require("eventbus")
let { isConsentAllowLogin, isReadyForConsent } = require("%appGlobals/loginState.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { is_ios, is_android } = require("%appGlobals/clientState/platform.nut")
let { setFirebaseConsent = @(_) null  } = is_android ? require("android.firebase.analytics")
        : is_ios ? require("ios.firebase.analytics")
        : {}
let { setAppsFlyerConsent, startAppsFlyer } = require("appsFlyer")
let { object_to_json_string } = require("json")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isIdfaDenied } = require("%rGui/login/stateIDFA.nut")


let CONSENT_OPTIONS_SAVE_ID = "consentManageOptions"

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

let needOpenConsentWnd = mkWatched(persist, "consentMainWnd", false)
let needForceOpenConsetnWnd    = Computed(@() savedPoints.get() != null && !isConsentAcceptedOnce.get() && !isIdfaDenied.get())
let needSkipConsentWnd = keepref(Computed(@() savedPoints.get() != null && !isConsentAcceptedOnce.get() && isIdfaDenied.get()))

let isOpenedConsentWnd = Computed(@()
  (needOpenConsentWnd.get() || needForceOpenConsetnWnd.get())
  && isReadyForConsent.get())

function setupAnalytics() {
  let v = savedPoints.get()
  logC("analytics starting with consent:", v)
  setFirebaseConsent(object_to_json_string(v))
  setAppsFlyerConsent(v?.ad_user_data ?? false, v?.ad_personalization ?? false, true)
  startAppsFlyer()
}

function autoSkipConsent() {
  if (isConsentAcceptedOnce.get())
    return
  savedPoints(defaultPointsTable.map(@(_) false))// dont need to save to online storage so that the window can open again at the next login
  logC("consent skipped by denied IDFA")
  sendUiBqEvent("consent", { id = "consent_skip_by_denied_idfa" })
  setupAnalytics()
}

needSkipConsentWnd.subscribe(@(v) v ? deferOnce(autoSkipConsent) : null)

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
  setupAnalytics() //run analytics when user already accepted in previous session
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

let isOpenedManage = mkWatched(persist, "consentManage", false)
let isOpenedPartners = mkWatched(persist, "consentPartners", false)

isOpenedConsentWnd.subscribe(function(v){
  if(v){
    logC($"run consent at startup")
    sendUiBqEvent("consent", { id = "consent_open_at_start" })
  }
})

isOpenedManage.subscribe(function(v) {
  if (v && !isOpenedConsentWnd.get()) {
    logC("run manage consent from privacy")
    sendUiBqEvent("consent", { id = "consent_open_from_privacy" })
  }
})

function applyConsent(pointsTable, source){
  logC($"consent saved from windows {source.wnd} action {source.action}", pointsTable)
  sendUiBqEvent("consent", {
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
  applyConsent
  setupAnalytics

  points
  defaultPointsTable
  savedPoints
}