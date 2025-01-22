from "%globalsDarg/darg_library.nut" import *
let { is_ios, is_android } = require("%appGlobals/clientState/platform.nut")
let { logEvent, setAppsFlyerCUID } = require("appsFlyer")
let { logEventFB } = require("android.account.fb")
let { setBillingUUID = @(_) null } = is_ios ? require("ios.billing.appstore") : {}
let { myUserId } = require("%appGlobals/profileStates.nut")
let { INVALID_USER_ID } = require("matching.errors")
let { object_to_json_string } = require("json")
let { get_common_local_settings_blk } = require("blkGetters")
let { eventbus_send } = require("eventbus")
let {
  logFirebaseEvent = @(_) null ,
  logFirebaseEventWithJson = @(_,__) null ,
  setFirebaseUID = @(_) null
}  = is_android ? require_optional ("android.firebase.analytics") : is_ios ? require_optional ("ios.firebase.analytics") : {}

const FIRST_LOGIN_EVENT = "first_login_event"

function sendEvent(id) {
  log($"[telemetry] send event {id}")
  logEvent($"af_{id}", "")
  logEventFB($"fb_{id}")
  //do not use event names from this list https://firebase.google.com/docs/reference/ios/firebaseanalytics/api/reference/Classes/FIRAnalytics#/c:objc(cs)FIRAnalytics(cm)logEventWithName:parameters:
  //standart event names can use optinal parameters https://firebase.google.com/docs/reference/ios/firebaseanalytics/api/reference/Constants#/c:FIREventNames.h
  logFirebaseEvent(id)
}

myUserId.subscribe(function(v) {
  if (v != INVALID_USER_ID) {
    let uid = v.tostring()
    setAppsFlyerCUID(uid)
    setBillingUUID(uid)
    setFirebaseUID(uid)
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

return {
  sendAppsFlyerEvent = sendEvent
  logFirebaseEventWithJson
}