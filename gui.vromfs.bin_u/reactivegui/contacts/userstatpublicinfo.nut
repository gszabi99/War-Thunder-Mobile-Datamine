from "%globalsDarg/darg_library.nut" import *
from "app" import APP_ID
from "auth_wt" import getPlayerTokenGlobal
from "dagor.time" import get_time_msec
from "%sqstd/globalState.nut" import hardPersistWatched
from "%rGui/unlocks/userstat.nut" import userstatRequest, userstatRegisterHandler


const AGEING_TIME_MSEC = 600000
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
        token = getPlayerTokenGlobal()
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