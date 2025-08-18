from "%globalsDarg/darg_library.nut" import *
let logU = log_with_prefix("[userstat] ")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { ndbTryRead } = require("nestdb")
let { register_command } = require("console")
let { resetTimeout, clearTimer, setTimeout } = require("dagor.workcycle")
let { rnd_float, frnd } = require("dagor.random")
let { isEqual } = require("%sqstd/underscore.nut")
let charClientEventExt = require("%rGui/charClientEventExt.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { parseUnixTimeCached } = require("%appGlobals/timeToText.nut")
let { request, registerHandler, registerExecutor } = charClientEventExt("userStats")

let STATS_ACTUAL_TIMEOUT = 900
const MAX_TABLES_UPDATE_DELAY = 10 

function mkUserstatWatch(id, defValue = {}) {
  let key = $"userstat.{id}"
  let data = Watched(ndbTryRead(key) ?? defValue) 
  eventbus_subscribe($"userstat.update.{id}", @(_) data.set(ndbTryRead(key) ?? defValue))
  return data
}

let userstatDescList = mkUserstatWatch("descList")
let userstatUnlocks = mkUserstatWatch("unlocks")
let userstatStats = mkUserstatWatch("stats")
let userstatInfoTables = mkUserstatWatch("infoTables")
let statsInProgress = mkWatched(persist, "statsInProgress", {})
let tablesActivityOvr = Watched({}) 

let getStatsActualTimeLeft = @() (userstatStats.value?.timestamp ?? 0) + STATS_ACTUAL_TIMEOUT - serverTime.get()
let isStatsActualByTime = Watched(getStatsActualTimeLeft() > 0)
userstatStats.subscribe(function(_) {
  let timeLeft = getStatsActualTimeLeft()
  isStatsActualByTime.set(timeLeft > 0)
  if (timeLeft > 0)
    resetTimeout(timeLeft, @() isStatsActualByTime.set(false))
})

let isStatsActualByBattle = hardPersistWatched("userstats.actualByBattle", true)
isInBattle.subscribe(@(_) isStatsActualByBattle(false))

let isStatsActual = Computed(@() isStatsActualByTime.get() && isStatsActualByBattle.get())

let isUserstatMissingData = Computed(@() userstatUnlocks.value.len() == 0
  || userstatDescList.value.len() == 0
  || userstatStats.value.len() == 0
  || userstatInfoTables.value.len() == 0)

function actualizeStats() {
  if (isStatsActual.get())
    return
  logU("request stats refresh")
  eventbus_send($"userstat.stats.refresh", {})
}

registerHandler("ClnChangeStats", function(result, context) {
  let { mode, stat } = context
  if (stat in statsInProgress.get())
    statsInProgress.mutate(@(v) v.$rawdelete(stat))
  if (!result?.error)
    return

  log("ClnChangeStats result = ", result)
  logerr($"Failed to change stat {mode}/{stat}")
})

let debugDelay = keepref(hardPersistWatched("userstat.debugDelay", 0.0))

local requestExt = request
let updateDebugDelay = @() requestExt = (debugDelay.get() <= 0) ? request
  : @(a, p, c) setTimeout(max(0.2, frnd()) * debugDelay.get(), @() request(a, p, c))

function userstatSetStat(mode, stat, value, context = {}) {
  statsInProgress.mutate(@(v) v[stat] <- true)
  requestExt("ClnChangeStats",
    {
      data = {
        [stat] = { ["$set"] = value },
        ["$mode"] = mode
      }
    },
    context.__merge({ mode, stat, value }))
}

let seasonIntervals = Watched({})
let nextUpdateIntervals = Watched({ time = 0 })
let maxTime = 0x7FFFFFFFFFFFFFFF

let parseTimeOnce = @(timeRange) {
  start = parseUnixTimeCached(timeRange.start) ?? 0,
  end = parseUnixTimeCached(timeRange.end) ?? 0
}

let isTimeInRange = @(timeRange, time)
  time >= timeRange.start && time <= timeRange.end

function updateActualSeasonsIntervals() {
  if (!isServerTimeValid.get())
    return
  let curTime = serverTime.get()
  let seasonsIntervalsData = userstatInfoTables.get()?.tables ?? {}
  local nextTime = maxTime
  let simplifySeasonsWithActiveStatus = seasonsIntervalsData
    .map(@(season) season.map(function(interval) {
      let parsedTime = parseTimeOnce(interval)
      if (parsedTime.start > curTime && parsedTime.start < nextTime)
        nextTime = parsedTime.start
      if (parsedTime.end > curTime && parsedTime.end < nextTime)
        nextTime = parsedTime.end
      return {
        index = interval.index,
        isActive = isTimeInRange(parsedTime, curTime)
      }
    })
  )
  seasonIntervals.set(simplifySeasonsWithActiveStatus)

  if (nextTime != maxTime)
    nextUpdateIntervals.set({ time = nextTime + 1 })
  else
    nextUpdateIntervals.set({ time = 0 })
}

updateActualSeasonsIntervals()
userstatInfoTables.subscribe(@(_) updateActualSeasonsIntervals())
isServerTimeValid.subscribe(@(_) updateActualSeasonsIntervals())

function resetUpdateTimer() {
  let { time } = nextUpdateIntervals.get()
  let left = time - serverTime.get()
  if (left <= 0)
    clearTimer(updateActualSeasonsIntervals)
  else
    resetTimeout(left, updateActualSeasonsIntervals)
}
resetUpdateTimer()
nextUpdateIntervals.subscribe(@(_) resetUpdateTimer())


function updateTableActivityTimer() {
  if (!isServerTimeValid.get())
    return
  let stats = userstatStats.get()
  let curTime = serverTime.get()
  local nextTime = null
  local needRefreshStats = false
  let activityOvr = {}
  foreach (tblId, tbl in stats?.stats ?? {}) {
    let time = tbl?["$endsAt"] ?? 0
    if (time <= 0)
      continue
    if (time <= curTime) {
      activityOvr[tblId] <- false
      needRefreshStats = true
    }
    else
      nextTime = min(nextTime ?? time, time)
  }
  foreach (tblId, tbl in stats?.inactiveTables ?? {}) {
    let start = tbl?["$startsAt"] ?? 0
    let end = tbl?["$endsAt"] ?? 0
    if (start > curTime)
      nextTime = min(nextTime ?? start, start)
    else if (end > curTime) {
      activityOvr[tblId] <- true
      needRefreshStats = true
    }
  }

  if (nextTime != null && nextTime - curTime > 0)
    resetTimeout(nextTime - curTime, updateTableActivityTimer)
  if (!isEqual(tablesActivityOvr.get(), activityOvr))
    tablesActivityOvr.set(activityOvr)
  if (needRefreshStats) {
    logU("Deactualize stats by tables time range")
    isStatsActualByTime.set(false)
    resetTimeout(rnd_float(0.001, 1.0) * MAX_TABLES_UPDATE_DELAY, actualizeStats)
  }
}
updateTableActivityTimer()
isServerTimeValid.subscribe(@(_) updateTableActivityTimer())
userstatStats.subscribe(@(_) updateTableActivityTimer())
updateDebugDelay()
debugDelay.subscribe(@(_) updateDebugDelay())

register_command(@(delay) debugDelay.set(delay), "userstat.delay_requests")

return {
  isUserstatMissingData
  userstatInfoTables
  userstatDescList
  userstatUnlocks
  userstatStats
  tablesActivityOvr
  isStatsActual
  actualizeStats
  forceRefreshDescList = @() eventbus_send($"userstat.descList.forceRefresh", {})
  forceRefreshUnlocks = @() eventbus_send($"userstat.unlocks.forceRefresh", {})
  forceRefreshStats = @() eventbus_send($"userstat.stats.forceRefresh", {})
  forceRefreshInfoTables = @() eventbus_send($"userstat.infoTables.forceRefresh", {})

  userstatRequest = requestExt
  userstatRegisterHandler = registerHandler 
  userstatRegisterExecutor = registerExecutor 

  userstatSetStat
  statsInProgress
  seasonIntervals
}