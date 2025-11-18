from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { is_ios, is_android } = require("%appGlobals/clientState/platform.nut")
let { logEvent, setAppsFlyerCUID, setUserEmail = @(_) null } = require("appsFlyer")
let { logEventFB } = require("android.account.fb")
let { setBillingUUID = @(_) null } = is_ios ? require("ios.billing.appstore") : {}
let { INVALID_USER_ID } = require("matching.errors")
let { object_to_json_string } = require("json")
let { get_common_local_settings_blk, get_local_custom_settings_blk } = require("blkGetters")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { getLogin = @() "" } = require("auth_wt")
let { sha256 = @(_) "" } =  require("hash")
let regexp2 = require("regexp2")
let {
  logFirebaseEvent = @(_) null ,
  logFirebaseEventWithJson = @(_,__) null ,
  setFirebaseUID = @(_) null
  getFirebaseAppInstanceId = @() null
}  = is_android ? require_optional ("android.firebase.analytics") : is_ios ? require_optional ("ios.firebase.analytics") : {}
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { subscribeResetProfile } = require("%rGui/account/resetProfileDetector.nut")

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

let function sendFirebaseAppInstanceBq() {
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

function sendEvent(id) {
  log($"[telemetry] send event {id}")
  logEvent($"af_{id}", "")
  logEventFB($"fb_{id}")
  
  
  logFirebaseEvent(id)
}

myUserId.subscribe(function(v) {
  if (v != INVALID_USER_ID) {
    let uid = v.tostring()
    setAppsFlyerCUID(uid)
    setBillingUUID(uid)
    setFirebaseUID(uid)
    setUserEmail(getLogin()) 
    let blk = get_common_local_settings_blk()
    let wasLoginedBefore = blk?[FIRST_LOGIN_EVENT] ?? false
    if (!wasLoginedBefore) {
      logEvent("af_first_login",object_to_json_string({cuid = uid}, false))
      logEventFB("fb_first_login")
      logFirebaseEventWithJson("first_login",object_to_json_string({cuid = uid}, false))
      blk[FIRST_LOGIN_EVENT] = true
      eventbus_send("saveProfile", {})
    }
  }
})

function sendAppsFlyerSavedEvent(eventId, saveId) {
  let blk = get_local_custom_settings_blk().addBlock(STATS_SENT)
  if (!blk?[saveId]) {
    blk[saveId] = true
    eventbus_send("saveProfile", {})
    sendEvent(eventId)
  }
}

function resetStatsSentEvents() {
  get_local_custom_settings_blk().removeBlock(STATS_SENT)
  eventbus_send("saveProfile", {})
}

subscribeResetProfile(resetStatsSentEvents)
register_command(resetStatsSentEvents, "debug.reset_stats_sent_events")

return {
  sendAppsFlyerEvent = sendEvent
  sendAppsFlyerSavedEvent
  logFirebaseEventWithJson
}