from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, clearTimer
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/pServerJwt.nut" import decodeJwtAndHandleErrors
from "%appGlobals/queueState.nut" import jwtUserstat
from "%appGlobals/userstats/serverTime.nut" import getServerTime
from "%rGui/unlocks/userstat.nut" import userstatRequest, userstatRegisterHandler


let logU = log_with_prefix("[BATTLE_USERSTATS] ")


const tokenActiveTime = 60 * 60 * 2
const oldStatSendTime = 5.0

const GET_STATS_ACTION = "GetStats:battle"
let GET_STATS_AVG_SCORE_FILTER = {
  tables = ["global"],
  modes = ["ships", "tanks", "air"],
  stats = ["m_avg_score"],
  sign = true
}

let isStatsActual = mkWatched(persist, "isStatsActual", false)
let allowSendOldStats = mkWatched(persist, "allowSendOldStats", false)

let needRequestStats = keepref(Computed(@() isLoggedIn.get() && !isInBattle.get() && !isStatsActual.get()))

isInBattle.subscribe(function(v) {
  if (v)
    return
  isStatsActual.set(false)
  allowSendOldStats.set(false)
})

let actualizeStats = @() userstatRequest(GET_STATS_ACTION, { data = GET_STATS_AVG_SCORE_FILTER })
function resetToken() {
  jwtUserstat.set(null)
  isStatsActual.set(false)
  allowSendOldStats.set(false)
  clearTimer(resetToken)
}

needRequestStats.subscribe(function(v) {
  if (!v)
    return
  actualizeStats()
  resetTimeout(oldStatSendTime, @() jwtUserstat.get() != null ? allowSendOldStats.set(!isStatsActual.get()) : null)
})

userstatRegisterHandler(GET_STATS_ACTION, function(result) {
  if (result?.error || "jwt" not in result?.response) {
    if (jwtUserstat.get() != null)
      allowSendOldStats.set(true)
    logU("Get stats error: ", result?.error)
    return
  }
  logU("Get stats success")
  jwtUserstat.set(result.response.jwt)
  allowSendOldStats.set(false)
  isStatsActual.set(true)
  let tokenAge = getServerTime() - decodeJwtAndHandleErrors({ jwt = jwtUserstat.get() }).payload.timestamp
  resetTimeout(tokenActiveTime - tokenAge, resetToken)
})

isLoggedIn.subscribe(@(v) !v ? resetToken() : null)


return { isStatsActual, actualizeStats, oldStatSendTime, allowSendOldStats }
