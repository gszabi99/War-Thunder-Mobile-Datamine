from "%globalsDarg/darg_library.nut" import *
from "%sqstd/frp.nut" import ComputedImmediate
let { eventbus_send } = require("eventbus")
let { sendAppsFlyerEvent } = require("logEvents.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { lastBattles, sharedStats, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { debriefingData } = require("%rGui/debriefing/debriefingState.nut")
let { firstBattleTutor, tutorialMissions } = require("%rGui/tutorial/tutorialMissions.nut")
let { isUserstatMissingData, userstatStats } = require("%rGui/unlocks/userstat.nut")
let { curStage } = require("%rGui/battlePass/battlePassState.nut")


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

let lastBattlesTotal = keepref(Computed(@() lastBattles.get().len()))
sendEventByValue("played_battles_5", lastBattlesTotal, 5, 0)

let LAST_SUBMITTED_COUNT_OF_BATTLES = "lastSubmittedCountOfBattles"
let battlesListCountToSend = [50, 100, 500, 1000, 1100, 1200, 1300, 1400, 1500, 1800, 2000]

function findClosestOrEqualLowerValue(list, target) {
  local res = null

  foreach (value in list)
    if (value <= target)
      if (res == null || value > res)
        res = value

  return res
}

function saveAndSendBattlesCount() {
  let savedCount = get_local_custom_settings_blk()?[LAST_SUBMITTED_COUNT_OF_BATTLES] ?? 0
  if (savedCount < lastBattlesTotal.get()) {
    let closestCount = findClosestOrEqualLowerValue(battlesListCountToSend, lastBattlesTotal.get())
    if (closestCount == null || closestCount <= savedCount)
      return
    get_local_custom_settings_blk()[LAST_SUBMITTED_COUNT_OF_BATTLES] = closestCount
    eventbus_send("saveProfile", {})
    sendAppsFlyerEvent($"battles_{closestCount}_1")
  }
}
lastBattlesTotal.subscribe(@(v) battlesListCountToSend.contains(v) ? saveAndSendBattlesCount() : null)

let level = keepref(Computed(@() playerLevelInfo.value.level))
sendEventByValue("level_3", level, 3, 1)
sendEventByValue("level_10", level, 10, 1)

isLoggedIn.subscribe(function(v) {
  if (v) {
    sendAppsFlyerEvent("login")
    saveAndSendBattlesCount()
  }
})

let loginCount = keepref(Computed(@() sharedStats.value?.loginDaysCount ?? 0))
loginCount.subscribe(function(count) {
  if (count != 2)
    return
  let todayFirstLogin = sharedStats.value?.lastLoginDayFirstTime ?? 0
  if (serverTime.value - todayFirstLogin <= 60)
    sendAppsFlyerEvent("login_day_2")
})

let bpLevelsUserstat = ComputedImmediate(@()
  userstatStats.get()?.stats["global"].meta_common.battlepass_stage_progress ?? 0)
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
