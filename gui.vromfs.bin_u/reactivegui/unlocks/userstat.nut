from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { ndbTryRead } = require("nestdb")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let charClientEventExt = require("%rGui/charClientEventExt.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { parseUnixTimeCached } = require("%appGlobals/timeToText.nut")
let { request, registerHandler, registerExecutor } = charClientEventExt("userStats")

let STATS_ACTUAL_TIMEOUT = 900

function mkUserstatWatch(id, defValue = {}) {
  let key = $"userstat.{id}"
  let data = Watched(ndbTryRead(key) ?? defValue) //no need to write to ndb, it will be saved by daguiVm
  eventbus_subscribe($"userstat.update.{id}", @(_) data(ndbTryRead(key) ?? defValue))
  return data
}

let userstatDescList = mkUserstatWatch("descList")
let userstatUnlocks = mkUserstatWatch("unlocks")
let userstatStats = mkUserstatWatch("stats")
let userstatInfoTables = mkUserstatWatch("infoTables")
let statsInProgress = mkWatched(persist, "statsInProgress", {})

let getStatsActualTimeLeft = @() (userstatStats.value?.timestamp ?? 0) + STATS_ACTUAL_TIMEOUT - serverTime.value
let isStatsActualByTime = Watched(getStatsActualTimeLeft() > 0)
userstatStats.subscribe(function(_) {
  let timeLeft = getStatsActualTimeLeft()
  isStatsActualByTime(timeLeft > 0)
  if (timeLeft > 0)
    resetTimeout(timeLeft, @() isStatsActualByTime(false))
})

let isStatsActualByBattle = hardPersistWatched("userstats.actualByBattle", true)
isInBattle.subscribe(@(_) isStatsActualByBattle(false))

let isStatsActual = Computed(@() isStatsActualByTime.value && isStatsActualByBattle.value)

let isUserstatMissingData = Computed(@() userstatUnlocks.value.len() == 0
  || userstatDescList.value.len() == 0
  || userstatStats.value.len() == 0
  || userstatInfoTables.value.len() == 0)

function actualizeStats() {
  if (!isStatsActual.value)
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

function userstatSetStat(mode, stat, value, context = {}) {
  statsInProgress.mutate(@(v) v[stat] <- true)
  request("ClnChangeStats",
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
  seasonIntervals(simplifySeasonsWithActiveStatus)

  if (nextTime != maxTime)
    nextUpdateIntervals({ time = nextTime + 1 })
  else
    nextUpdateIntervals({ time = 0 })
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

return {
  isUserstatMissingData
  userstatInfoTables
  userstatDescList
  userstatUnlocks
  userstatStats
  isStatsActual
  actualizeStats
  forceRefreshDescList = @() eventbus_send($"userstat.descList.forceRefresh", {})
  forceRefreshUnlocks = @() eventbus_send($"userstat.unlocks.forceRefresh", {})
  forceRefreshStats = @() eventbus_send($"userstat.stats.forceRefresh", {})
  forceRefreshInfoTables = @() eventbus_send($"userstat.infoTables.forceRefresh", {})

  userstatRequest = request
  userstatRegisterHandler = registerHandler //main handler for actions
  userstatRegisterExecutor = registerExecutor //custom handler for actions

  userstatSetStat
  statsInProgress
  seasonIntervals
}