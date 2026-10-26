from "%globalsDarg/darg_library.nut" import *
from "adjust" import logAdjustEvent
from "mobile.facebook" import logEventFB
from "app" import get_cur_circuit_name
from "blkGetters" import get_common_local_settings_blk, get_local_custom_settings_blk
from "console" import register_command
from "eventbus" import eventbus_send, eventbus_subscribe
from "json" import object_to_json_string
from "matching.errors" import INVALID_USER_ID
from "platform" import get_platform_string_id
import "regexp2" as regexp2
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/platform.nut" import is_ios, is_android
from "%appGlobals/pServer/bqClient.nut" import sendCustomBqEvent
from "%appGlobals/profileStates.nut" import myUserId
from "%rGui/account/resetProfileDetector.nut" import subscribeResetProfile
from "tikTok" import logTikTokEvent

let logT = log_with_prefix("[TELEMETRY] ")

let { logEvent, setAppsFlyerCUID, setUserEmail = @(_) null } = require("appsFlyer")
let { setBillingUUID = @(_) null } = is_ios ? require("ios.billing.appstore") : {}
let { getLogin = @() "" } = require("auth_wt")
let { sha256 = @(_) "" } =  require("hash")
let {
  logFirebaseEvent = @(_) null ,
  logFirebaseEventWithJson = @(_,__) null ,
  setFirebaseUID = @(_) null
  getFirebaseAppInstanceId = @() null
}  = is_android ? require_optional ("android.firebase.analytics") : is_ios ? require_optional ("ios.firebase.analytics") : {}

const FIRST_LOGIN_EVENT = "first_login_event"
const STATS_SENT = "statsSent"

let firebaseAppInstanceId = mkWatched(persist, "firebaseAppInstanceId", getFirebaseAppInstanceId())
let storedUserIdForFirebase = hardPersistWatched("storedUserIdForUserId", null)
let readySendFirebaseBq = keepref(Computed(@() firebaseAppInstanceId.get()!=null
  && myUserId.get() != INVALID_USER_ID
  && storedUserIdForFirebase.get() != myUserId.get()))

function convertToSha256Email(login) {
  
  
  
  let emailReg = regexp2(@"((\w+)(\.{1}\w+)*@(\w+)(\.\w+)+)")
  if (!emailReg.match(login))
    return ""

  let emailNoDots = regexp2(@"(\.)(?=.*@(gmail\.com||googlemail\.com)$)")
  login = sha256(emailNoDots.replace("", login).tolower().replace(" ", ""))
  return login
}

function sendFirebaseAppInstanceBq() {
  if (myUserId.get() != storedUserIdForFirebase.get()) {
    storedUserIdForFirebase.set(myUserId.get())
    sendCustomBqEvent("firebase_info_1", {
      appInstanceId = firebaseAppInstanceId.get(),
      email = convertToSha256Email(getLogin())
    })
  }
}

if (readySendFirebaseBq.get()) {
  sendFirebaseAppInstanceBq()
}

readySendFirebaseBq.subscribe(function(v) {
  if (v)
    sendFirebaseAppInstanceBq()
})

eventbus_subscribe(is_ios ? "ios.firebase.analytics.onReceiveAppId" : "android.firebase.analytics.onReceiveAppId",
  @(params) firebaseAppInstanceId.set(params.firebaseAppInstanceId))







let adjustEventsMap = {
  login = "gqaopf"
  purchase = "8ozmgw"
  played_battles_5 = "tynngg"
  level_10 = "yvanyk"
  bplevel_4 = "bk5fpu"
  bplevel_11 = "exszrp"
}


function logAdjust(eventType, eventValue, needLocalLog = true) {
  let eventId = adjustEventsMap?[eventType]
  if (eventId == null)
    return
  if (needLocalLog)
    logT($"Send Adjust event {eventType}")
  logAdjustEvent(eventId, eventValue)
}

eventbus_subscribe("adjust.onGetAdjustAdId", function(p) {
  sendCustomBqEvent("adjust_ids", {
    adid = p.adid
    circuit = get_cur_circuit_name()
    platform = get_platform_string_id()
    idfa = is_ios ? (p?.idfa ?? "") : ""
    idfv = is_ios ? (p?.idfv ?? "") : ""
    gps_adid = is_android ? (p?.gps_adid ?? "") : ""
  })
})

let tikTokEvents = [ "first_login", "bplevel_23", "battleNum_01", "get_units_8" ]

function logTikTok(id, jsonStrValues = "", needLocalLog = true) {
  if (!tikTokEvents.contains(id))
    return
  if (needLocalLog)
    logT($"Send TikTok event {id}")
  logTikTokEvent(id, jsonStrValues)
}

function sendTelemetryEvent(id) {
  logT($"Send common event {id}")
  logEvent($"af_{id}", "")
  logEventFB($"fb_{id}")
  logAdjust(id, "", false)
  logTikTok(id, "", false)
  
  
  logFirebaseEvent(id)
}

myUserId.subscribe(function(v) {
  if (v != INVALID_USER_ID) {
    this_subscriber_call_may_take_up_to_usec(10 * get_slow_subscriber_threshold_usec())
    let uid = v.tostring()
    setAppsFlyerCUID(uid)
    setBillingUUID(uid)
    setFirebaseUID(uid)
    setUserEmail(getLogin()) 
    let blk = get_common_local_settings_blk()
    let wasLoginedBefore = blk?[FIRST_LOGIN_EVENT] ?? false
    if (!wasLoginedBefore) {
      logT("Send first login events")
      let id_json = object_to_json_string({cuid = uid}, false)
      logEvent("af_first_login", id_json)
      logEventFB("fb_first_login")
      logTikTok("first_login", id_json, false)
      logFirebaseEventWithJson("first_login", id_json)
      blk[FIRST_LOGIN_EVENT] = true
      eventbus_send("saveProfile", {})
    }
  }
})

function sendTelemetrySavedEvent(eventId, saveId) {
  let blk = get_local_custom_settings_blk().addBlock(STATS_SENT)
  if (!blk?[saveId]) {
    blk[saveId] = true
    eventbus_send("saveProfile", {})
    sendTelemetryEvent(eventId)
  }
}

function resetStatsSentEvents() {
  get_local_custom_settings_blk().removeBlock(STATS_SENT)
  eventbus_send("saveProfile", {})
}

subscribeResetProfile(resetStatsSentEvents)
register_command(resetStatsSentEvents, "debug.reset_stats_sent_events")

return {
  sendTelemetryEvent
  sendTelemetrySavedEvent
  logFirebaseEventWithJson
  logAdjust
  logTikTok
}