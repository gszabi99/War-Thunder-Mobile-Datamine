from "%scripts/dagui_library.nut" import *
let { ndbWrite, ndbRead, ndbExists } = require("nestdb")
let { split_by_chars } = require("string")
let { frnd } = require("dagor.random")
let { getCurrentSteamLanguage } = require("%scripts/language.nut")
let userstat = require("userstat")
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { setInterval, clearTimer, resetTimeout } = require("dagor.workcycle")
let { register_command } = require("console")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { isProfileReceived, isMatchingConnected } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let charClientEvent = require("charClientEvent.nut")
let { mnGenericSubscribe } = require("%appGlobals/matching_api.nut")

const STATS_REQUEST_TIMEOUT = 45000
const STATS_UPDATE_INTERVAL = 60000 
const FREQUENCY_MISSING_STATS_UPDATE_SEC = 300
const MAX_CONFIGS_UPDATE_DELAY = 10 

const GET_STATS_FILTER = {
  tables = ["global", "daily", "ships_event_leaderboard", "tanks_event_leaderboard", "air_event_leaderboard", "wp_event_leaderboard"],
  modes = ["meta_common", "battle_common", "ships", "tanks", "air"],
}


let isReadyToConnect = Computed(@() isProfileReceived.get() && isMatchingConnected.get())
let needConfigsUpdate = mkWatched(persist, "needConfigsUpdate", false)
let hasStatsFilter = mkWatched(persist, "hasStatsFilter", true)

let { request, registerHandler } = charClientEvent("userStats", userstat)

function mkDataWatched(key, defValue = null, evtName = null) {
  local val = defValue
  if (ndbExists(key))
    val = ndbRead(key)
  else
    ndbWrite(key, val)
  let res = Watched(val)
  res.subscribe(function(v) {
    ndbWrite(key, v)
    if (evtName != null)
      eventbus_send(evtName, {})
  })
  return res
}

function makeUpdatable(persistName, refreshAction, getRefreshParams = null, customRefreshRequests = []) {
  let defValue = {}
  let data = mkDataWatched($"userstat.{persistName}", defValue, $"userstat.update.{persistName}")
  let lastTime = mkDataWatched($"userstat.{persistName}_lastTime", { request = 0, update = 0 })
  let isRequestInProgress = @() lastTime.get().request > lastTime.get().update
    && lastTime.get().request + STATS_REQUEST_TIMEOUT > get_time_msec()
  let canRefresh = @() !isRequestInProgress()
    && (!lastTime.get().update || (lastTime.get().update + STATS_UPDATE_INTERVAL < get_time_msec()))

  function onRefresh(result, context) {
    data.set(result?.error ? defValue : (result?.response ?? defValue))
    lastTime.mutate(@(v) v.update = get_time_msec())
    if (context?.needPrint)
      console_print(result?.error ? result : result?.response)
  }
  registerHandler(refreshAction, onRefresh)

  foreach(actionId in customRefreshRequests)
    registerHandler(actionId, function(result, _) {
      if (result?.error || result?.response == null)
        return
      data.set(result.response)
      lastTime.mutate(@(v) v.update = get_time_msec())
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

  isReadyToConnect.subscribe(@(v) v ? forceRefresh() : data.set(defValue))

  if (isReadyToConnect.get() && lastTime.get().update <= 0 && lastTime.get().request <= 0)
    refresh()

  register_command(@() forceRefresh({ needPrint = true }), $"userstat.get.{persistName}")
  register_command(@() debugTableData(data.get()) ?? console_print("Done"), $"userstat.debug.{persistName}")
  eventbus_subscribe($"userstat.{persistName}.forceRefresh", @(_) forceRefresh())
  eventbus_subscribe($"userstat.{persistName}.refresh", @(_) refresh())

  return {
    id = persistName
    data
    refresh
    forceRefresh
    lastUpdateTime = Computed(@() lastTime.get().update)
  }
}

let descListUpdatable = makeUpdatable("descList", "GetUserStatDescList",
  @() { headers = { language = getCurrentSteamLanguage() } })
let statsUpdatable = makeUpdatable("stats", "GetStats",
  @() { data = hasStatsFilter.get() ? GET_STATS_FILTER : {} })
let statsTablesUpdatable = makeUpdatable("statsTables", "GetStats:tables", @() { data = { skip = "allStats" } })
let unlocksUpdatable = makeUpdatable("unlocks", "GetUnlocks", null, ["GrantRewards", "BuyUnlockReroll"])
let infoTablesUpdatable = makeUpdatable("infoTables", "GetTablesInfo")

let userstatUnlocks = unlocksUpdatable.data
let userstatDescList = descListUpdatable.data
let userstatStats = statsUpdatable.data
let userstatInfoTables = infoTablesUpdatable.data

function validateUserstatData() {
  if (unlocksUpdatable.data.get().len() == 0)
    unlocksUpdatable.refresh()
  if (descListUpdatable.data.get().len() == 0)
    descListUpdatable.refresh()
  if (statsUpdatable.data.get().len() == 0)
    statsUpdatable.refresh()
  if (statsTablesUpdatable.data.get().len() == 0)
    statsTablesUpdatable.refresh()
  if (infoTablesUpdatable.data.get().len() == 0)
    infoTablesUpdatable.refresh()
}

let isUserstatMissingData = Computed(@() userstatUnlocks.get().len() == 0
  || userstatDescList.get().len() == 0
  || userstatStats.get().len() == 0
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

function onChangeStats(result) {
  console_print(result)
  if (!result?.error) {
    unlocksUpdatable.forceRefresh()
    statsUpdatable.forceRefresh()
  }
}

registerHandler("ChangeStats", onChangeStats)
registerHandler("ClnChangeStats", onChangeStats)

function getDebugSimilarStatsText(stat) {
  let similar = []
  let parts = split_by_chars(stat, "_", true)
  foreach (s, _v in userstatDescList.get()?.stats ?? {})
    foreach (part in parts)
      if (s.indexof(part) != null) {
        similar.append(s)
        break
      }
  return "\n      ".join(["  Similar stats:"].extend(arrayByRows(similar, 8).map(@(v) ", ".join(v))))
}

function changeStat(stat, mode, amount, shouldSet) {
  let stats = stat.split(";")
  let missingStat = stats.findvalue(@(s) userstatDescList.get()?.stats[s] == null)
  local errorText = stats.len() == 0 ? "Empty stat"
    : (type(amount) != "integer" && type(amount) != "float")
      ? $"Amount must be numeric (current = {amount})"
    : missingStat != null ? $"Stat {missingStat} does not exist.\n  {getDebugSimilarStatsText(missingStat)}"
    : ""
  if (errorText != "") {
    console_print({ error = errorText })
    return
  }

  let value = shouldSet ? { "$set" : amount } : amount
  request("ChangeStats",
    { data = stats.reduce(@(res, s) res.$rawset(s, value), {})
        .__update({ ["$mode"] = mode })
    })
}

let addStat = @(stat, mode, amount)
  changeStat(stat, mode, amount, false)
let setStat = @(stat, mode, amount)
  changeStat(stat, mode, amount, true)

mnGenericSubscribe("userStat", function(ev) {
  if (ev?.func == "changed")
    unlocksUpdatable.forceRefresh()
  else if (ev?.func == "updateConfig")
    needConfigsUpdate.set(true)
})

function updateConfigsIfNeed() {
  if (!needConfigsUpdate.get() || isInBattle.get())
    return
  needConfigsUpdate.set(false)
  descListUpdatable.forceRefresh()
  unlocksUpdatable.forceRefresh()
  infoTablesUpdatable.forceRefresh()
  statsTablesUpdatable.forceRefresh()
}
updateConfigsIfNeed()
needConfigsUpdate.subscribe(@(_) isInBattle.get() ? null
  : resetTimeout(frnd() * MAX_CONFIGS_UPDATE_DELAY, updateConfigsIfNeed))
isInBattle.subscribe(@(v) v ? updateConfigsIfNeed() : null)


function debugStatValues(stat) {
  if (userstatDescList.get()?.stats[stat] == null)
    return console_print($"Stat {stat} does not exist.\n  {getDebugSimilarStatsText(stat)}")

  let rows = []
  foreach(tblId, tbl in userstatStats.get()?.stats ?? {})
    foreach(modeId, mode in tbl)
      if (type(mode) == "table" && modeId != "ratingSessions")
        rows.append($"{tblId}/{modeId} = {mode?[stat]}")

  return console_print("\n".join(rows))
}

register_command(debugStatValues, $"userstat.debugStatValues")

let registeredMods = {}
function registerModCmdOnce(modeId) {
  if (modeId in registeredMods)
    return
  registeredMods[modeId] <- true
  register_command(@(stat, value) addStat(stat, modeId, value), $"userstat.addStat.{modeId}")
  register_command(@(stat, value) setStat(stat, modeId, value), $"userstat.setStat.{modeId}")
}
foreach (modeId in GET_STATS_FILTER.modes)
  registerModCmdOnce(modeId)

function registerStatsCommands(uStats) {
  let { stats = null } = uStats
  if (stats == null)
    return
  stats.each(@(tbl)
    tbl.each(function(list, modeId) {
      if (type(list) != "table" || modeId == "ratingSessions")
        return
      registerModCmdOnce(modeId)
    }))
}
registerStatsCommands(userstatStats.get())
userstatStats.subscribe(registerStatsCommands)

register_command(function() {
    hasStatsFilter.set(!hasStatsFilter.get())
    console_print($"Stats filter {hasStatsFilter.get() ? "on" : "off"}")
    statsUpdatable.forceRefresh()
  },
  $"userstat.toggleStatsFilter")
