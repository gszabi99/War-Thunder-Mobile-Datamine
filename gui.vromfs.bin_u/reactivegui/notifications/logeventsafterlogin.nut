from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "eventbus" import eventbus_send
from "%sqstd/frp.nut" import ComputedImmediate
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/campaign.nut" import isProfileReceived, lastBattles, sharedStats, curCampaign, campaignsList
from "%appGlobals/pServer/profile.nut" import playerLevelInfo
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/battlePass/battlePassObsoleteState.nut" import curStage
from "%rGui/debriefing/debriefingState.nut" import debriefingData
from "%rGui/notifications/logEvents.nut" import sendTelemetryEvent, sendTelemetrySavedEvent, logTikTok
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

function sendEventOnReach(eventId, watch, threshold, sendEvent = sendTelemetryEvent) {
  local prev = watch.get()
  watch.subscribe(function(v) {
    if (prev != null && prev < threshold && v >= threshold)
      sendEvent(eventId)
    prev = v
  })
}

let unitsTotal = keepref(Computed(@() !isProfileReceived.get() ? null
  : (servProfile.get()?.units.len() ?? 0)))
sendEventOnReach("get_units_8", unitsTotal, 8, @(id) sendTelemetrySavedEvent(id, id))

let statsByCampaign = Computed(@() !isProfileReceived.get() ? null
  : (servProfile.get()?.sharedStatsByCampaign ?? {}))

let onlineBattlesTotal = keepref(Computed(@() statsByCampaign.get() == null ? null
  : statsByCampaign.get().reduce(@(res, s) res + (s?.battles ?? 0), 0)))
let onlineBattlesTanks = keepref(Computed(@() statsByCampaign.get() == null ? null
  : (statsByCampaign.get()?.tanks.battles ?? 0)))
let onlineBattlesAir = keepref(Computed(@() statsByCampaign.get() == null ? null
  : (statsByCampaign.get()?.air.battles ?? 0)))

foreach (count in [2, 8, 21])
  sendEventOnReach($"battles_{count}", onlineBattlesTotal, count)

sendEventOnReach("battles_tanks_7", onlineBattlesTanks, 7)
sendEventOnReach("battles_air_7", onlineBattlesAir, 7)
sendEventOnReach("battleNum_01", onlineBattlesTotal, 1, logTikTok)

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

let playerStats = Computed(@() userstatStats.get()?.stats["global"])
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
