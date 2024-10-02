from "%globalsDarg/darg_library.nut" import *
let { sendAppsFlyerEvent } = require("logEvents.nut")
let { debriefingData } = require("%rGui/debriefing/debriefingState.nut")
let { firstBattleTutor, tutorialMissions } = require("%rGui/tutorial/tutorialMissions.nut")
let { lastBattles, sharedStats, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")


let tutorialResultEvent = keepref(Computed(function() {
  let mission = tutorialMissions.value?[firstBattleTutor.value]
  let typeId = curCampaign.value == "ships" ? "ship" : "tank"
  return mission == null || debriefingData.value?.mission != mission ? null
    : (debriefingData.value?.isFinished ?? false) ? $"battle_tutorial_{typeId}_complete"
    : $"battle_tutorial_{typeId}_skip"
}))

tutorialResultEvent.subscribe(function(name) {
  if (name != null)
    sendAppsFlyerEvent(name)
})

function sendEventByValue(eventId, watch, valueToSend, notInitedValue = null) {
  local prev = watch.value
  watch.subscribe(function(v) {
    if (prev != notInitedValue && v == valueToSend)
      sendAppsFlyerEvent(eventId)
    prev = v
  })
}

let lastBattlesTotal = keepref(Computed(@() lastBattles.value.len()))
sendEventByValue("played_battles_5", lastBattlesTotal, 5, 0)

let level = keepref(Computed(@() playerLevelInfo.value.level))
sendEventByValue("level_3", level, 3, 1)
sendEventByValue("level_10", level, 10, 1)

isLoggedIn.subscribe(function(v) {
  if (v)
    sendAppsFlyerEvent("login")
})

let loginCount = keepref(Computed(@() sharedStats.value?.loginDaysCount ?? 0))
loginCount.subscribe(function(count) {
  if (count != 2)
    return
  let todayFirstLogin = sharedStats.value?.lastLoginDayFirstTime ?? 0
  if (serverTime.value - todayFirstLogin <= 60)
    sendAppsFlyerEvent("login_day_2")
})
