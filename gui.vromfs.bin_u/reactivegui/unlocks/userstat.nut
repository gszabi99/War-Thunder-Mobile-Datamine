from "%globalsDarg/darg_library.nut" import *
let logU = log_with_prefix("[userstat] ")
let { register_command } = require("console")
let { clearTimer, setTimeout, setInterval, resetTimeout } = require("dagor.workcycle")
let { rnd_float, frnd } = require("dagor.random")
let { get_time_msec } = require("dagor.time")
let { isEqual } = require("%sqstd/underscore.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { addPublisherToHeaders } = require("%appGlobals/curCircuitOverride.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { parseUnixTimeCached } = require("%appGlobals/timeToText.nut")
let { currentSteamLanguage } = require("%appGlobals/clientState/languageState.nut")
let { isProfileReceived, isMatchingConnected } = require("%appGlobals/loginState.nut")
let { mnGenericSubscribe } = require("%appGlobals/matching_api.nut")
let { resetExtTimeout, clearExtTimer } = require("%appGlobals/timeoutExt.nut")
let charClientEventExt = require("%rGui/charClientEventExt.nut")
let { scenesOrder } = require("%rGui/navState.nut")

const STATS_REQUEST_TIMEOUT = 45000
const STATS_UPDATE_INTERVAL = 60000 
const STATS_REPEAT_AFTER_ERROR_TIMEOUT = 60000
const FREQUENCY_MISSING_STATS_UPDATE_SEC = 300
const MAX_CONFIGS_UPDATE_DELAY = 10 
const STATS_ACTUAL_TIMEOUT = 900
const MAX_TIME = 0x7FFFFFFFFFFFFFFF

const GET_STATS_FILTER = {
  tables = ["global", "daily", "ships_event_leaderboard", "tanks_event_leaderboard", "air_event_leaderboard", "wp_event_leaderboard"],
  modes = ["meta_common", "battle_common", "ships", "tanks", "air"],
}

let { request, registerHandler, registerExecutor, registerBeforeHandler } = charClientEventExt("userStats")


let isReadyToConnect = Computed(@() isProfileReceived.get() && isMatchingConnected.get())
let hasStatsFilter = hardPersistWatched("userstats.hasStatsFilter", true)
let statsInProgress = hardPersistWatched("statsInProgress", {})
let isStatsActualByBattle = hardPersistWatched("userstats.actualByBattle", true)
let unlocksUpdaters = Watched({})
let unlocksScenes = Watched({})
let hasUnlockUpdater = Computed(@() unlocksUpdaters.get().len() > 0
  || scenesOrder.get()?[scenesOrder.get().len() - 1] in unlocksScenes.get())

isInBattle.subscribe(@(_) isStatsActualByBattle.set(false))

function mkIsTimePassed(timeComp, timeAdd = 0, calcTime = @(v) v) {
  let res = Watched(false)
  function update() {
    let time = calcTime(timeComp.get())
    let timeLeft = time <= 0 ? 0 : time + timeAdd - get_time_msec()
    res.set(timeLeft <= 0)
    if (timeLeft > 0)
      resetTimeout(0.001 * timeLeft, update)
  }
  update()
  timeComp.subscribe(@(_) update())
  return res
}

function makeUpdatable(persistName, refreshAction, getRefreshParams = null, customRefreshRequests = [], initData = @(v) v) {
  let defValue = {}
  let data = hardPersistWatched($"userstat.{persistName}", defValue, true)
  let lastTime = hardPersistWatched($"userstat.{persistName}_lastTime", { request = 0, update = 0 })
  let changeEventTime = hardPersistWatched($"userstats.{persistName}.changeEventTime", 0)
  let lastErrorTime = hardPersistWatched($"userstats.{persistName}.lastErrorTime", 0)
  let canRepeatAfterError = mkIsTimePassed(lastErrorTime, STATS_REPEAT_AFTER_ERROR_TIMEOUT)
  lastErrorTime.setDeferred(false) 
  let isTimeoutAfterRequest = mkIsTimePassed(lastTime, STATS_REQUEST_TIMEOUT, @(v) v.request)
  let isRequestInProgress = Computed(@() lastTime.get().request > lastTime.get().update && !isTimeoutAfterRequest.get())

  let canRefresh = @() !isRequestInProgress.get()
    && (!lastTime.get().update || (lastTime.get().update + STATS_UPDATE_INTERVAL < get_time_msec()))

  function onRefresh(result, context) {
    data.set(initData(result?.error ? defValue : (result?.response ?? defValue)))
    lastTime.mutate(@(v) v.update = get_time_msec())
    lastErrorTime.set(result?.error ? get_time_msec() : 0)
    if (context?.needPrint)
      console_print(result?.error ? result : result?.response) 
  }
  registerHandler(refreshAction, onRefresh)

  foreach(actionId in customRefreshRequests)
    registerBeforeHandler(actionId, function(result, _) {
      if (result?.error || result?.response == null)
        return
      data.set(initData(result.response))
      lastTime.mutate(@(v) v.update = get_time_msec())
      lastErrorTime.set(0)
    })

  let prepareToRequest = @() lastTime.mutate(@(v) v.request = get_time_msec())
  function refresh(context = null) {
    if (!isReadyToConnect.get()) {
      onRefresh({ error = "not logged in" }, context)
      return
    }
    if (!canRefresh())
      return

    prepareToRequest()
    request(refreshAction, getRefreshParams?() ?? {}, context)
  }

  function forceRefresh(context = null) {
    lastTime.mutate(@(v) v.__update({ request = 0, update = 0 }))
    refresh(context)
  }

  isReadyToConnect.subscribe(function(v) {
    if (v)
      forceRefresh()
    else {
      this_subscriber_call_may_take_up_to_usec(10 * get_slow_subscriber_threshold_usec())
      data.set(defValue)
    }
  })

  if (isReadyToConnect.get() && lastTime.get().update <= 0 && lastTime.get().request <= 0)
    refresh()

  let isActual = Computed(@() lastTime.get().update > changeEventTime.get() && data.get().len() != 0)
  let shouldUpdate = Computed(@() !isInBattle.get() && hasUnlockUpdater.get()
    && !isActual.get() && !isRequestInProgress.get() && canRepeatAfterError.get())
  shouldUpdate.subscribe(@(v) v ? forceRefresh() : null)

  register_command(@() forceRefresh({ needPrint = true }), $"userstat.get.{persistName}")
  register_command(@() debugTableData(data.get()) ?? console_print("Done"), $"userstat.debug.{persistName}") 

  return {
    id = persistName
    data
    refresh
    forceRefresh
    lastUpdateTime = Computed(@() lastTime.get().update)
    changeEventTime
    shouldUpdate
  }
}

let descListUpdatable = makeUpdatable("descList", "GetUserStatDescList",
  @() { headers = { language = currentSteamLanguage.get() } },
  [],
  @(descList) "unlocks" not in descList ? descList
    : descList.__merge({
        unlocks = descList.unlocks.map(@(u) u.__merge({
          stages = (u?.stages ?? []).map(@(stage) stage.__merge({ progress = (stage?.progress ?? 1).tointeger() }))
        }))
      }))
let unlocksUpdatable = makeUpdatable("unlocks", "GetUnlocks",
  @() { headers = addPublisherToHeaders({}) },
  ["GrantRewards", "BuyUnlock", "BuyUnlockReroll", "OpenNextUnlockStage"])
let statsUpdatable = makeUpdatable("stats", "GetStats",
  @() { data = hasStatsFilter.get() ? GET_STATS_FILTER : {} })
let statsTablesUpdatable = makeUpdatable("statsTables", "GetStats:tables", @() { data = { skip = "allStats" } })
let infoTablesUpdatable = makeUpdatable("infoTables", "GetTablesInfo")

let userstatDescList = descListUpdatable.data
let userstatUnlocks = unlocksUpdatable.data
let userstatStats = statsUpdatable.data
let userstatStatsTables = statsTablesUpdatable.data
let userstatInfoTables = infoTablesUpdatable.data


function validateUserstatData() {
  if (descListUpdatable.data.get().len() == 0)
    descListUpdatable.refresh()
  if (unlocksUpdatable.data.get().len() == 0)
    unlocksUpdatable.refresh()
  if (statsUpdatable.data.get().len() == 0)
    statsUpdatable.refresh()
  if (statsTablesUpdatable.data.get().len() == 0)
    statsTablesUpdatable.refresh()
  if (infoTablesUpdatable.data.get().len() == 0)
    infoTablesUpdatable.refresh()
}

let isUserstatMissingData = Computed(@() userstatDescList.get().len() == 0
  || userstatUnlocks.get().len() == 0
  || userstatStats.get().len() == 0
  || userstatStatsTables.get().len() == 0
  || userstatInfoTables.get().len() == 0)
let needValidateMissingData = keepref(Computed(@()
  isUserstatMissingData.get() && isReadyToConnect.get() && !isInBattle.get()))

function updateValidationTimer(needValidate) {
  if (!needValidate) {
    clearTimer(validateUserstatData)
    return
  }
  validateUserstatData()
  setInterval(FREQUENCY_MISSING_STATS_UPDATE_SEC, validateUserstatData)
}
updateValidationTimer(needValidateMissingData.get())
needValidateMissingData.subscribe(updateValidationTimer)

mnGenericSubscribe("userStat", function(ev) {
  let time = get_time_msec()
  if (ev?.func == "changed") {
    unlocksUpdatable.changeEventTime.set(time)
    statsTablesUpdatable.changeEventTime.set(time)
  }
  else if (ev?.func == "updateConfig") {
    descListUpdatable.changeEventTime.set(time)
    unlocksUpdatable.changeEventTime.set(time)
    statsTablesUpdatable.changeEventTime.set(time)
    infoTablesUpdatable.changeEventTime.set(time)
  }
})

let tablesActivityOvr = Watched({}) 

let getStatsActualTimeLeft = @() (userstatStats.get()?.timestamp ?? 0) + STATS_ACTUAL_TIMEOUT - serverTime.get()
let isStatsActualByTime = Watched(getStatsActualTimeLeft() > 0)
userstatStats.subscribe(function(_) {
  let timeLeft = getStatsActualTimeLeft()
  isStatsActualByTime.set(timeLeft > 0)
  if (timeLeft > 0)
    resetExtTimeout(timeLeft, @() isStatsActualByTime.set(false))
})

let isStatsActual = Computed(@() isStatsActualByTime.get() && isStatsActualByBattle.get())

function actualizeStats() {
  if (isStatsActual.get())
    return
  logU("request stats refresh")
  statsUpdatable.refresh()
}

registerHandler("ClnChangeStats", function(result, context) {
  let { mode, stat } = context
  if (stat in statsInProgress.get())
    statsInProgress.mutate(@(v) v.$rawdelete(stat))

  if (!result?.error) {
    unlocksUpdatable.forceRefresh()
    statsUpdatable.forceRefresh()
    return
  }

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

let seasonIntervalsToListen = Watched({})
let seasonIntervals = Watched({}) 
let nextUpdateIntervals = Watched({ time = 0 })

let parseTimeOnce = @(timeRange) {
  start = parseUnixTimeCached(timeRange.start) ?? 0,
  end = parseUnixTimeCached(timeRange.end) ?? 0
}

let isTimeInRange = @(timeRange, time)
  time >= timeRange.start && time <= timeRange.end

function updateActualSeasonsIntervals() {
  if (!isServerTimeValid.get() || seasonIntervalsToListen.get().len() == 0)
    return
  let curTime = serverTime.get()
  let seasonsIntervalsData = userstatInfoTables.get()?.tables ?? {}
  local nextTime = MAX_TIME
  let simplifySeasonsWithActiveStatus = seasonIntervalsToListen.get()
    .map(@(_, sId)
      seasonsIntervalsData?[sId]?.map(function(interval) {
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
      ?? {})
  seasonIntervals.set(simplifySeasonsWithActiveStatus)

  if (nextTime != MAX_TIME)
    nextUpdateIntervals.set({ time = nextTime + 1 })
  else
    nextUpdateIntervals.set({ time = 0 })
}

updateActualSeasonsIntervals()
seasonIntervalsToListen.subscribe(@(_) updateActualSeasonsIntervals())
userstatInfoTables.subscribe(@(_) updateActualSeasonsIntervals())
isServerTimeValid.subscribe(@(_) updateActualSeasonsIntervals())

function mkSeasonInterval(tableIdW) {
  let res = Computed(@() seasonIntervals.get()?[tableIdW.get() ?? ""])
  if (res.get() == null)
    seasonIntervalsToListen.mutate(@(v) v.$rawset(tableIdW.get() ?? "", true))
  res.subscribe(function(r) {
    if (r == null)
      seasonIntervalsToListen.mutate(@(v) v.$rawset(tableIdW.get() ?? "", true))
  })
  return res
}

function resetUpdateTimer() {
  let { time } = nextUpdateIntervals.get()
  let left = time - serverTime.get()
  if (left <= 0)
    clearExtTimer(updateActualSeasonsIntervals)
  else
    resetExtTimeout(left, updateActualSeasonsIntervals)
}
resetUpdateTimer()
nextUpdateIntervals.subscribe(@(_) resetUpdateTimer())


function updateTableActivityTimer() {
  if (!isServerTimeValid.get())
    return
  let stats = userstatStatsTables.get()
  let curTime = serverTime.get()
  local nextTime = null
  local needRefreshStats = false
  let activityOvr = {}
  foreach (tblId, tbl in stats?.stats ?? {}) {
    let time = tbl?["$endsAt"] ?? 0
    if (time <= 0)
      continue
    if (time <= curTime) {
      activityOvr[tblId] <- -1
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
      activityOvr[tblId] <- 10000000 
      needRefreshStats = true
    }
  }

  if (nextTime != null && nextTime - curTime > 0)
    resetExtTimeout(nextTime - curTime, updateTableActivityTimer)
  if (!isEqual(tablesActivityOvr.get(), activityOvr))
    tablesActivityOvr.set(activityOvr)
  if (needRefreshStats) {
    logU("Deactualize stats by tables time range")
    isStatsActualByTime.set(false)
    resetExtTimeout(rnd_float(0.001, 1.0) * MAX_CONFIGS_UPDATE_DELAY,
      function() {
        statsTablesUpdatable.changeEventTime.set(get_time_msec())
        descListUpdatable.changeEventTime.set(get_time_msec())
      })
  }
}
updateTableActivityTimer()
isServerTimeValid.subscribe(@(_) updateTableActivityTimer())
userstatStatsTables.subscribe(@(_) updateTableActivityTimer())
updateDebugDelay()
debugDelay.subscribe(@(_) updateDebugDelay())

register_command(@(delay) debugDelay.set(delay), "userstat.delay_requests")

register_command(function() {
    hasStatsFilter.set(!hasStatsFilter.get())
    console_print($"Stats filter {hasStatsFilter.get() ? "on" : "off"}") 
    statsUpdatable.forceRefresh()
  },
  $"userstat.toggleStatsFilter")

return {
  isUserstatMissingData
  userstatInfoTables
  userstatDescList
  userstatUnlocks
  userstatStats
  userstatStatsTables
  tablesActivityOvr
  isStatsActual
  actualizeStats
  forceRefreshDescList = descListUpdatable.forceRefresh
  forceRefreshUnlocks = unlocksUpdatable.forceRefresh
  forceRefreshStats = statsUpdatable.forceRefresh

  userstatRequest = requestExt
  userstatRegisterHandler = registerHandler 
  userstatRegisterExecutor = registerExecutor 
  addUnlocksUpdater = @(id) unlocksUpdaters.mutate(@(v) v.$rawset(id, true))
  removeUnlocksUpdater = @(id) unlocksUpdaters.mutate(@(v) v.$rawdelete(id))
  registerUnlocksSceneToUpdate = @(sceneId) unlocksScenes.mutate(@(v) v.$rawset(sceneId, true))

  userstatSetStat
  statsInProgress
  mkSeasonInterval

  GET_STATS_FILTER
}