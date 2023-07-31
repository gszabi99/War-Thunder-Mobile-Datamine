from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { ndbRead, ndbExists } = require("nestdb")
let charClientEventExt = require("%rGui/charClientEventExt.nut")

let { request, registerHandler, registerExecutor } = charClientEventExt("userStats")

let function mkUserstatWatch(id, refreshAction, defValue = {}) {
  let key = $"userstat.{id}"
  let data = Watched(ndbExists(key) ? ndbRead(key) : defValue) //no need to write to ndb, it will be saved by daguiVm
  registerHandler(refreshAction, @(result) data(result?.error ? defValue : (result?.response ?? defValue)))
  return data
}

let userstatDescList = mkUserstatWatch("descList", "GetUserStatDescList")
let userstatUnlocks = mkUserstatWatch("unlocks", "GetUnlocks")
let userstatStats = mkUserstatWatch("stats", "GetStats")

let isUserstatMissingData = Computed(@() userstatUnlocks.value.len() == 0
  || userstatDescList.value.len() == 0
  || userstatStats.value.len() == 0)

return {
  isUserstatMissingData
  userstatDescList
  userstatUnlocks
  userstatStats
  forceRefreshDescList = @() send($"userstat.descList.forceRefresh", {})
  forceRefreshUnlocks = @() send($"userstat.unlocks.forceRefresh", {})
  forceRefreshStats = @() send($"userstat.stats.forceRefresh", {})

  userstatRequest = request
  userstatRegisterHandler = registerHandler //main handler for actions
  userstatRegisterExecutor = registerExecutor //custom handler for actions
}