from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { userstatRequest, userstatRegisterHandler } = require("%rGui/unlocks/userstat.nut")
let { APP_ID } = require("app")
let { getPlayerToken } = require("auth_wt")

let AGEING_TIME_MSEC = 600000
let allUserStatInfo = hardPersistWatched("allUserStatInfo", {})
let inProgressUids = Watched({})

let isNeedUpdate = @(info) info == null
  || info.receiveTime + AGEING_TIME_MSEC <= get_time_msec()

function refreshUserStats(userId) {
  if (isNeedUpdate(allUserStatInfo.get()?[userId])
      && userId not in inProgressUids.get()) {
    inProgressUids.mutate(@(v) v[userId] <- true)
    userstatRequest("AnoGetStats", {
      data = {}
      headers = {
        appid = APP_ID,
        token = getPlayerToken()
        userId
      }},
      { userId })
  }
}

userstatRegisterHandler("AnoGetStats", function(result, context) {
  let { userId = 0 } = context
  if (inProgressUids.get()?[userId])
    inProgressUids.mutate(@(v) v.$rawdelete(userId))
  if ("error" in result) {
    log("AnoGetStats result: ", result)
    return
  }
  let timeUpd = { receiveTime = get_time_msec() }
  allUserStatInfo.mutate(@(v) v[userId] <- (result?.response ?? {}).__merge(timeUpd))
  log("AnoGetStats result success: ", result, context)
})

let mkStatsInfo = @(userId)
  Computed(@() allUserStatInfo.get()?[userId])

let mkIsStatsWait = @(userId)
  Computed(@() userId in inProgressUids.get())

return {
  mkStatsInfo
  mkIsStatsWait
  refreshUserStats
}