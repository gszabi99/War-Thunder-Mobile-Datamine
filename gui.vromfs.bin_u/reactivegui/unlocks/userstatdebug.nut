from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "string" import split_by_chars
from "%sqstd/underscore.nut" import arrayByRows
from "%rGui/unlocks/userstat.nut" import userstatRequest, userstatRegisterHandler, userstatDescList,
  userstatStats, forceRefreshUnlocks, forceRefreshStats, GET_STATS_FILTER


function onChangeStats(result) {
  console_print(result) 
  if (!result?.error) {
    forceRefreshUnlocks()
    forceRefreshStats()
  }
}

userstatRegisterHandler("ChangeStats", onChangeStats)

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
  userstatRequest("ChangeStats",
    { data = stats.reduce(@(res, s) res.$rawset(s, value), {})
        .__update({ ["$mode"] = mode })
    })
}

let addStat = @(stat, mode, amount)
  changeStat(stat, mode, amount, false)
let setStat = @(stat, mode, amount)
  changeStat(stat, mode, amount, true)

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

register_command(@(modeId, stat, value) addStat(stat, modeId, value), $"userstat.addStat")
register_command(@(modeId, stat, value) setStat(stat, modeId, value), $"userstat.setStat")

let customFields = ["ratingSessions", "rerollPrice"].totable()
function registerStatsCommands(uStats) {
  let { stats = null } = uStats
  if (stats == null)
    return
  stats.each(@(tbl)
    tbl.each(function(list, modeId) {
      if (type(list) == "table" && modeId not in customFields)
        registerModCmdOnce(modeId)
    }))
}
registerStatsCommands(userstatStats.get())
userstatStats.subscribe(registerStatsCommands)
