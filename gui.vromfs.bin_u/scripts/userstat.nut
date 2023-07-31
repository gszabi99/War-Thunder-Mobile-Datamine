from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this
let userstat = require("userstat")
let { subscribe } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { register_command } = require("console")
let { split_by_chars } = require("string")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { isProfileReceived } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let charClientEvent = require("charClientEvent.nut")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { mnSubscribe } = require("%appGlobals/matchingNotifications.nut")

const STATS_REQUEST_TIMEOUT = 45000
const STATS_UPDATE_INTERVAL = 60000 //unlocks progress update interval
const FREQUENCY_MISSING_STATS_UPDATE_SEC = 300

let { request, registerHandler } = charClientEvent("userStats", userstat)

let function makeUpdatable(persistName, refreshAction, getHeaders = null, defValue = {}) {
  let data = mkHardWatched($"userstat.{persistName}", defValue)
  let lastTime = mkHardWatched($"userstat.{persistName}_lastTime", { request = 0, update = 0 })
  let isRequestInProgress = @() lastTime.value.request > lastTime.value.update
    && lastTime.value.request + STATS_REQUEST_TIMEOUT > get_time_msec()
  let canRefresh = @() !isRequestInProgress()
    && (!lastTime.value.update || (lastTime.value.update + STATS_UPDATE_INTERVAL < get_time_msec()))

  let function onRefresh(result, context) {
    data(result?.error ? defValue : (result?.response ?? defValue))
    lastTime.mutate(@(v) v.update = get_time_msec())
    if (context?.needPrint)
      console_print(result?.error ? result : result?.response)
  }
  registerHandler(refreshAction, onRefresh)

  let prepareToRequest = @() lastTime.mutate(@(v) v.request = get_time_msec())
  let function refresh(context = null) {
    if (!isProfileReceived.value) {
      onRefresh({ error = "not logged in" }, context)
      return
    }
    if (!canRefresh())
      return

    prepareToRequest()
    request(refreshAction, { headers = getHeaders?() ?? {} }, context)
  }

  let function forceRefresh(context = null) {
    lastTime.mutate(@(v) v.__update({ request = 0, update = 0 }))
    refresh(context)
  }

  isProfileReceived.subscribe(@(v) v ? forceRefresh() : data(defValue))

  if (isProfileReceived.value && lastTime.value.update <= 0 && lastTime.value.request <= 0)
    refresh()

  register_command(@() forceRefresh({ needPrint = true }), $"userstat.get.{persistName}")
  register_command(@() debugTableData(data.value) ?? console_print("Done"), $"userstat.debug.{persistName}")
  subscribe($"userstat.{persistName}.forceRefresh", @(_) forceRefresh())

  return {
    id = persistName
    data
    refresh
    forceRefresh
    lastUpdateTime = Computed(@() lastTime.value.update)
  }
}

let descListUpdatable = makeUpdatable("descList", "GetUserStatDescList",
  @() { language = ::g_language.getCurrentSteamLanguage() })
let statsUpdatable = makeUpdatable("stats", "GetStats")
let unlocksUpdatable = makeUpdatable("unlocks", "GetUnlocks")

let userstatUnlocks = unlocksUpdatable.data
let userstatDescList = descListUpdatable.data
let userstatStats = statsUpdatable.data

let function validateUserstatData() {
  if (unlocksUpdatable.data.value.len() == 0)
    unlocksUpdatable.refresh()
  if (descListUpdatable.data.value.len() == 0)
    descListUpdatable.refresh()
  if (statsUpdatable.data.value.len() == 0)
    statsUpdatable.refresh()
}

let isUserstatMissingData = Computed(@() userstatUnlocks.value.len() == 0
  || userstatDescList.value.len() == 0
  || userstatStats.value.len() == 0)
let needValidateMissingData = keepref(Computed(@()
  isUserstatMissingData.value && isProfileReceived.value && !isInBattle.value))

let function updateValidationTimer(needValidate) {
  if (!needValidate) {
    clearTimer(validateUserstatData)
    return
  }
  validateUserstatData()
  setInterval(FREQUENCY_MISSING_STATS_UPDATE_SEC, validateUserstatData)
}
updateValidationTimer(needValidateMissingData.value)
needValidateMissingData.subscribe(updateValidationTimer)

registerHandler("ChangeStats", function(result) {
  console_print(result)
  if (!result?.error) {
    unlocksUpdatable.forceRefresh()
    statsUpdatable.forceRefresh()
  }
})

let function changeStat(stat, mode, amount, shouldSet) {
  local errorText = null
  if (type(amount) != "integer" && type(amount) != "float")
    errorText = $"Amount must be numeric (current = {amount})"
  else if (userstatDescList.value?.stats[stat] == null) {
    errorText = $"Stat {stat} does not exist."
    let similar = []
    let parts = split_by_chars(stat, "_", true)
    foreach (s, _v in userstatDescList.value?.stats ?? {})
      foreach (part in parts)
        if (s.indexof(part) != null) {
          similar.append(s)
          break
        }
    let statsText = "\n      ".join(["  Similar stats:"].extend(arrayByRows(similar, 8).map(@(v) ", ".join(v))))
    errorText = "\n  ".join([errorText, statsText], true)
  }

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

mnSubscribe("userStat", function(ev) {
  if (ev?.func == "changed")
    unlocksUpdatable.forceRefresh()
})

let registered = {}
let function registerOnce(func, id) {
  if (id in registered)
    return
  register_command(func, id)
  registered[id] <- true
}

let function registerStatsCommands(uStats) {
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
