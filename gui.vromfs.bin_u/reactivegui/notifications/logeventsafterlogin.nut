from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "eventbus" import eventbus_send
from "%sqstd/frp.nut" import ComputedImmediate
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/campaign.nut" import lastBattles, sharedStats, curCampaign, campaignsList
from "%appGlobals/pServer/profile.nut" import playerLevelInfo
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/battlePass/battlePassState.nut" import curStage
from "%rGui/debriefing/debriefingState.nut" import debriefingData
from "%rGui/notifications/logEvents.nut" import sendTelemetryEvent
from "%rGui/tutorial/tutorialMissions.nut" import firstBattleTutor, tutorialMissions
from "%rGui/unlocks/userstat.nut" import isUserstatMissingData, userstatStats


let tutorialResultEvent = keepref(Computed(function() {
  let mission = tutorialMissions.get()?[firstBattleTutor.get()]
  let typeId = curCampaign.get() == "ships" ? "ship" : "tank"
  return mission == null || debriefingData.get()?.mission != mission ? null
    : (debriefingData.get()?.isFinished ?? false) ? $"battle_tutorial_{typeId}_complete"
    : $"battle_tutorial_{typeId}_skip"
}))

tutorialResultEvent.subscribe(function(name) {
  if (name != null)
    sendTelemetryEvent(name)
})

function sendEventByValue(eventId, watch, valueToSend, notInitedValue = null) {
  local prev = watch.get()
  watch.subscribe(function(v) {
    if (prev != notInitedValue && v == valueToSend)
      sendTelemetryEvent(eventId)
    prev = v
  })
}

let lastBattlesTotal = keepref(Computed(@() lastBattles.get().len()))
sendEventByValue("played_battles_5", lastBattlesTotal, 5, 0)

const LAST_SUBMITTED_COUNT_OF_BATTLES = "lastSubmittedCountOfBattles"
let battlesListCountToSend = [50, 100, 500, 1000, 1100, 1200, 1300, 1400, 1500, 1800, 2000]

function findClosestOrEqualLowerValue(list, target) {
  local res = null

  foreach (value in list)
    if (value <= target)
      if (res == null || value > res)
        res = value

  return res
}

let playerStats = ComputedImmediate(@() userstatStats.get()?.stats["global"])
let totalProfileBattles = keepref(Computed(function() {
  let res = {}
  foreach (campaign in campaignsList.get())
    res[campaign] <- playerStats.get()?[campaign].battles ?? 0
  return res.reduce(@(acc, count) count + acc, 0)
}))

function saveAndSendBattlesCount() {
  let savedCount = get_local_custom_settings_blk()?[LAST_SUBMITTED_COUNT_OF_BATTLES] ?? 0
  if (savedCount < totalProfileBattles.get()) {
    let closestCount = findClosestOrEqualLowerValue(battlesListCountToSend, totalProfileBattles.get())
    if (closestCount == null || closestCount <= savedCount)
      return
    get_local_custom_settings_blk()[LAST_SUBMITTED_COUNT_OF_BATTLES] = closestCount
    eventbus_send("saveProfile", {})
    sendTelemetryEvent($"battles_{closestCount}_1")
  }
}
totalProfileBattles.subscribe(@(_) saveAndSendBattlesCount())

let level = keepref(Computed(@() playerLevelInfo.get().level))
sendEventByValue("level_3", level, 3, 1)
sendEventByValue("level_10", level, 10, 1)

isLoggedIn.subscribe(@(v) v ? sendTelemetryEvent("login") : null)

let loginCount = keepref(Computed(@() sharedStats.get()?.loginDaysCount ?? 0))
loginCount.subscribe(function(count) {
  if (count != 2)
    return
  let todayFirstLogin = sharedStats.get()?.lastLoginDayFirstTime ?? 0
  if (serverTime.get() - todayFirstLogin <= 60)
    sendTelemetryEvent("login_day_2")
})

let bpLevelsUserstat = ComputedImmediate(@() playerStats.get()?.meta_common.battlepass_stage_progress ?? 0)
let bpNewLevels = hardPersistWatched("logEvents.bpNewLevels", 0)

isUserstatMissingData.subscribe(@(_) bpNewLevels.set(0))
bpLevelsUserstat.subscribe(@(_) bpNewLevels.set(0))

local lastStage = isUserstatMissingData.get() ? null : curStage.get()
curStage.subscribe(function(v) {
  if (isUserstatMissingData.get()) {
    lastStage = null
    return
  }
  if (lastStage != null && v > lastStage)
    bpNewLevels.set(bpNewLevels.get() + v - lastStage)
  lastStage = v
})

let bpLevels = keepref(Computed(@() isUserstatMissingData.get() ? null
  : (bpLevelsUserstat.get() + bpNewLevels.get())))
foreach(l in [4, 5, 7, 11, 23])
  sendEventByValue($"bplevel_{l}", bpLevels, l)
