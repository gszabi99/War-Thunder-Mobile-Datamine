from "%globalsDarg/darg_library.nut" import *
let { logEvent, setAppsFlyerCUID = @(_) null } = require("appsFlyer")
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

const FIRST_LOGIN_EVENT = "first_login_event"

let function sendEvent(id) {
  log($"[appsFlyer] send event {id}")
  logEvent(id, "")
}

let tutorialResultEvent = keepref(Computed(function() {
  let mission = tutorialMissions?[firstBattleTutor.value]
  let typeId = curCampaign.value == "ships" ? "ship" : "tank"
  return mission == null || debriefingData.value?.mission != mission ? null
    : (debriefingData.value?.isFinished ?? false) ? $"af_battle_tutorial_{typeId}_complete"
    : $"af_battle_tutorial_{typeId}_skip"
}))

tutorialResultEvent.subscribe(function(name) {
  if (name != null)
    sendEvent(name)
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
sendEventByValue("af_played_battles_5", lastBattlesTotal, 5, 0)

let level = keepref(Computed(@() playerLevelInfo.value.level))
sendEventByValue("af_level_3", level, 3, 1)
sendEventByValue("af_level_10", level, 10, 1)

isLoggedIn.subscribe(function(v) {
  if (v)
    sendEvent("af_login");
})

myUserId.subscribe(function(v) {
  if (v != INVALID_USER_ID) {
    setAppsFlyerCUID(v.tostring())
    let blk = get_common_local_settings_blk()
    let wasLoginedBefore = blk?[FIRST_LOGIN_EVENT] ?? false
    if (!wasLoginedBefore) {
      logEvent("af_first_login",json_to_string({cuid = v.tostring()}, false))
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
    sendEvent("af_login_day_2")
})
