from "%globalsDarg/darg_library.nut" import *
let { is_ios, is_android } = require("%appGlobals/clientState/platform.nut")
let { logEvent, setAppsFlyerCUID } = require("appsFlyer")
let { debriefingData } = require("%rGui/debriefing/debriefingState.nut")
let { firstBattleTutor, tutorialMissions } = require("%rGui/tutorial/tutorialMissions.nut")
let { lastBattles, sharedStats, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { INVALID_USER_ID } = require("matching.errors")
let { json_to_string } = require("json")
let { get_common_local_settings_blk } = require("blkGetters")
let { send } = require("eventbus")
let {
  logFirebaseEvent = @(_) null ,
  logFirebaseEventWithJson = @(_,__) null ,
  setFirebaseUID = @(_) null
}  = is_android ? require_optional ("android.firebase.analytics") : is_ios ? require_optional ("ios.firebase.analytics") : {}

const FIRST_LOGIN_EVENT = "first_login_event"

let function sendEvent(id) {
  log($"[telemetry] send event {id}")
  logEvent($"af_{id}", "")
  //do not use event names from this list https://firebase.google.com/docs/reference/ios/firebaseanalytics/api/reference/Classes/FIRAnalytics#/c:objc(cs)FIRAnalytics(cm)logEventWithName:parameters:
  //standart event names can use optinal parameters https://firebase.google.com/docs/reference/ios/firebaseanalytics/api/reference/Constants#/c:FIREventNames.h
  logFirebaseEvent(id)
}

let tutorialResultEvent = keepref(Computed(function() {
  let mission = tutorialMissions?[firstBattleTutor.value]
  let typeId = curCampaign.value == "ships" ? "ship" : "tank"
  return mission == null || debriefingData.value?.mission != mission ? null
    : (debriefingData.value?.isFinished ?? false) ? $"battle_tutorial_{typeId}_complete"
    : $"battle_tutorial_{typeId}_skip"
}))

tutorialResultEvent.subscribe(function(name) {
  if (name != null) {
    logEvent($"af_{name}", "")
    logFirebaseEvent(name)
  }
})

let function sendEventByValue(eventId, watch, valueToSend, notInitedValue = null) {
  local prev = watch.value
  watch.subscribe(function(v) {
    if (prev != notInitedValue && v == valueToSend)
      sendEvent(eventId)
    prev = v
  })
}

let lastBattlesTotal = keepref(Computed(@() lastBattles.value.len()))
sendEventByValue("played_battles_5", lastBattlesTotal, 5, 0)

let level = keepref(Computed(@() playerLevelInfo.value.level))
sendEventByValue("level_3", level, 3, 1)
sendEventByValue("level_10", level, 10, 1)

isLoggedIn.subscribe(function(v) {
  if (v) {
    logEvent("af_login", "")
    logFirebaseEvent("login")
  }
})

myUserId.subscribe(function(v) {
  if (v != INVALID_USER_ID) {
    let uid = v.tostring()
    setAppsFlyerCUID(uid)
    setFirebaseUID(uid)
    let blk = get_common_local_settings_blk()
    let wasLoginedBefore = blk?[FIRST_LOGIN_EVENT] ?? false
    if (!wasLoginedBefore) {
      logEvent("af_first_login",json_to_string({cuid = uid}, false))
      logFirebaseEventWithJson("first_login",json_to_string({cuid = uid}, false))
      blk[FIRST_LOGIN_EVENT] = true
      send("saveProfile", {})
    }
  }
})

let loginCount = keepref(Computed(@() sharedStats.value?.loginDaysCount ?? 0))
loginCount.subscribe(function(count) {
  if (count != 2)
    return
  let todayFirstLogin = sharedStats.value?.lastLoginDayFirstTime ?? 0
  if (serverTime.value - todayFirstLogin <= 60)
    sendEvent("login_day_2")
})
