from "%scripts/dagui_library.nut" import *
let { ndbWrite, ndbRead, ndbExists } = require("nestdb")
let { split_by_chars, startswith } = require("string")
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


let isReadyToConnect = Computed(@() isProfileReceived.value && isMatchingConnected.value)
let needConfigsUpdate = mkWatched(persist, "needConfigsUpdate", false)

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

function makeUpdatable(persistName, refreshAction, getHeaders = null, customRefreshRequests = []) {
  let defValue = {}
  let data = mkDataWatched($"userstat.{persistName}", defValue, $"userstat.update.{persistName}")
  let lastTime = mkDataWatched($"userstat.{persistName}_lastTime", { request = 0, update = 0 })
  let isRequestInProgress = @() lastTime.value.request > lastTime.value.update
    && lastTime.value.request + STATS_REQUEST_TIMEOUT > get_time_msec()
  let canRefresh = @() !isRequestInProgress()
    && (!lastTime.value.update || (lastTime.value.update + STATS_UPDATE_INTERVAL < get_time_msec()))

  function onRefresh(result, context) {
    data(result?.error ? defValue : (result?.response ?? defValue))
    lastTime.mutate(@(v) v.update = get_time_msec())
    if (context?.needPrint)
      console_print(result?.error ? result : result?.response)
  }
  registerHandler(refreshAction, onRefresh)

  foreach(actionId in customRefreshRequests)
    registerHandler(actionId, function(result, _) {
      if (result?.error || result?.response == null)
        return
      data(result.response)
      lastTime.mutate(@(v) v.update = get_time_msec())
    })

  let prepareToRequest = @() lastTime.mutate(@(v) v.request = get_time_msec())
  function refresh(context = null) {
    if (!isReadyToConnect.value) {
      onRefresh({ error = "not logged in" }, context)
      return
    }
    if (!canRefresh())
      return

    prepareToRequest()
    request(refreshAction, { headers = getHeaders?() ?? {} }, context)
  }

  function forceRefresh(context = null) {
    lastTime.mutate(@(v) v.__update({ request = 0, update = 0 }))
    refresh(context)
  }

  isReadyToConnect.subscribe(@(v) v ? forceRefresh() : data(defValue))

  if (isReadyToConnect.value && lastTime.value.update <= 0 && lastTime.value.request <= 0)
    refresh()

  register_command(@() forceRefresh({ needPrint = true }), $"userstat.get.{persistName}")
  register_command(@() debugTableData(data.value) ?? console_print("Done"), $"userstat.debug.{persistName}")
  eventbus_subscribe($"userstat.{persistName}.forceRefresh", @(_) forceRefresh())
  eventbus_subscribe($"userstat.{persistName}.refresh", @(_) refresh())

  return {
    id = persistName
    data
    refresh
    forceRefresh
    lastUpdateTime = Computed(@() lastTime.value.update)
  }
}

let descListUpdatable = makeUpdatable("descList", "GetUserStatDescList",
  @() { language = getCurrentSteamLanguage() })
let statsUpdatable = makeUpdatable("stats", "GetStats")
let unlocksUpdatable = makeUpdatable("unlocks", "GetUnlocks", null, ["GrantRewards"])
let infoTablesUpdatable = makeUpdatable("infoTables", "GetTablesInfo")

let userstatUnlocks = unlocksUpdatable.data
let userstatDescList = descListUpdatable.data
let userstatStats = statsUpdatable.data
let userstatInfoTables = infoTablesUpdatable.data

function validateUserstatData() {
  if (unlocksUpdatable.data.value.len() == 0)
    unlocksUpdatable.refresh()
  if (descListUpdatable.data.value.len() == 0)
    descListUpdatable.refresh()
  if (statsUpdatable.data.value.len() == 0)
    statsUpdatable.refresh()
  if (infoTablesUpdatable.data.get().len() == 0)
    infoTablesUpdatable.refresh()
}

let isUserstatMissingData = Computed(@() userstatUnlocks.value.len() == 0
  || userstatDescList.value.len() == 0
  || userstatStats.value.len() == 0
  || userstatInfoTables.get().len() == 0)
let needValidateMissingData = keepref(Computed(@()
  isUserstatMissingData.value && isReadyToConnect.value && !isInBattle.get()))

function updateValidationTimer(needValidate) {
  if (!needValidate) {
    clearTimer(validateUserstatData)
    return
  }
  validateUserstatData()
  setInterval(FREQUENCY_MISSING_STATS_UPDATE_SEC, validateUserstatData)
}
updateValidationTimer(needValidateMissingData.value)
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
  foreach (s, _v in userstatDescList.value?.stats ?? {})
    foreach (part in parts)
      if (s.indexof(part) != null) {
        similar.append(s)
        break
      }
  return "\n      ".join(["  Similar stats:"].extend(arrayByRows(similar, 8).map(@(v) ", ".join(v))))
}

function changeStat(stat, mode, amount, shouldSet) {
  local errorText = null
  if (type(amount) != "integer" && type(amount) != "float")
    errorText = $"Amount must be numeric (current = {amount})"
  else if (userstatDescList.value?.stats[stat] == null)
    errorText = $"Stat {stat} does not exist.\n  {getDebugSimilarStatsText(stat)}"

  if (errorText != null) {
    console_print({ error = errorText })
    return
  }

  request("ChangeStats",
    { data = {
      [stat] = shouldSet ? { "$set" : amount } : amount,
      ["$mode"] = mode
    } })
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
}
updateConfigsIfNeed()
needConfigsUpdate.subscribe(@(_) isInBattle.get() ? null
  : resetTimeout(frnd() * MAX_CONFIGS_UPDATE_DELAY, updateConfigsIfNeed))
isInBattle.subscribe(@(v) v ? updateConfigsIfNeed() : null)


function debugStatValues(stat) {
  if (userstatDescList.value?.stats[stat] == null)
    return console_print($"Stat {stat} does not exist.\n  {getDebugSimilarStatsText(stat)}")

  let rows = []
  foreach(tblId, tbl in userstatStats.value?.stats ?? {})
    foreach(modeId, mode in tbl)
      if (!startswith(modeId, "$"))
        rows.append($"{tblId}/{modeId} = {mode?[stat]}")

  return console_print("\n".join(rows))
}

register_command(debugStatValues, $"userstat.debugStatValues")

let registered = {}
function registerOnce(func, id) {
  if (id in registered)
    return
  register_command(func, id)
  registered[id] <- true
}

function registerStatsCommands(uStats) {
  let { stats = null } = uStats
  if (stats == null)
    return
  stats.each(@(tbl, tblId)
    tbl.each(function(list, modeId) {
      if (type(list) != "table")
        return
      registerOnce(@() console_print(userstatStats.value?.stats[tblId][modeId]), $"userstat.stats.{tblId}.{modeId}.get")
      registerOnce(@(stat, value) addStat(stat, modeId, value), $"userstat.addStat.{modeId}")
      registerOnce(@(stat, value) setStat(stat, modeId, value), $"userstat.setStat.{modeId}")
    }))
}
registerStatsCommands(userstatStats.value)
userstatStats.subscribe(registerStatsCommands)
