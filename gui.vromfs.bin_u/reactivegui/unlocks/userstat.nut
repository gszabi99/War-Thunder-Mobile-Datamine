from "%globalsDarg/darg_library.nut" import *
let { send, subscribe } = require("eventbus")
let { ndbTryRead } = require("nestdb")
let { resetTimeout } = require("dagor.workcycle")
let charClientEventExt = require("%rGui/charClientEventExt.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let { request, registerHandler, registerExecutor } = charClientEventExt("userStats")

let STATS_ACTUAL_TIMEOUT = 900

let function mkUserstatWatch(id, defValue = {}) {
  let key = $"userstat.{id}"
  let data = Watched(ndbTryRead(key) ?? defValue) //no need to write to ndb, it will be saved by daguiVm
  subscribe($"userstat.update.{id}", @(_) data(ndbTryRead(key) ?? defValue))
  return data
}

let userstatDescList = mkUserstatWatch("descList")
let userstatUnlocks = mkUserstatWatch("unlocks")
let userstatStats = mkUserstatWatch("stats")

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
  || userstatStats.value.len() == 0)

let function actualizeStats() {
  if (!isStatsActual.value)
    send($"userstat.stats.refresh", {})
}

return {
  isUserstatMissingData
  userstatDescList
  userstatUnlocks
  userstatStats
  isStatsActual
  actualizeStats
  forceRefreshDescList = @() send($"userstat.descList.forceRefresh", {})
  forceRefreshUnlocks = @() send($"userstat.unlocks.forceRefresh", {})
  forceRefreshStats = @() send($"userstat.stats.forceRefresh", {})

  userstatRequest = request
  userstatRegisterHandler = registerHandler //main handler for actions
  userstatRegisterExecutor = registerExecutor //custom handler for actions
}