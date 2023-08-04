from "%globalsDarg/darg_library.nut" import *
let { send, subscribe } = require("eventbus")
let { ndbTryRead } = require("nestdb")
let charClientEventExt = require("%rGui/charClientEventExt.nut")

let { request, registerHandler, registerExecutor } = charClientEventExt("userStats")

let function mkUserstatWatch(id, defValue = {}) {
  let key = $"userstat.{id}"
  let data = Watched(ndbTryRead(key) ?? defValue) //no need to write to ndb, it will be saved by daguiVm
  subscribe($"userstat.update.{id}", @(_) data(ndbTryRead(key) ?? defValue))
  return data
}

let userstatDescList = mkUserstatWatch("descList")
let userstatUnlocks = mkUserstatWatch("unlocks")
let userstatStats = mkUserstatWatch("stats")

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