from "%scripts/dagui_library.nut" import *
import "%globalScripts/ecs.nut" as ecs
let logU = log_with_prefix("[BATTLE_USERSTATS] ")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { splitStringBySize } = require("%sqstd/string.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { mkCmdSetUserstatJwtStats } = require("%appGlobals/sqevents.nut")
let { getServerTime } = require("%appGlobals/userstats/serverTime.nut")
let { decodeJwtAndHandleErrors } = require("%appGlobals/pServer/pServerJwt.nut")
let { userstatRequest, userstatRegisterHandler } = require("%scripts/userstat.nut")


let tokenActiveTime = 60 * 60 * 2
let oldStatSendTime = 10.0

let GET_STATS_ACTION = "GetStats:battle"
let GET_STATS_AVG_SCORE_FILTER = {
  tables = ["global"],
  modes = ["ships", "tanks", "air"],
  stats = ["m_avg_score"],
  sign = true
}

let isUserstatStatsReceived = mkWatched(persist, "isUserstatStatsReceived", false)
let serverPlayerEid = mkWatched(persist, "serverPlayerEid", null)
let jwtUserstat = mkWatched(persist, "jwtUserstat", null)
let isStatsActual = mkWatched(persist, "isStatsActual", false)
let allowSendOldStats = mkWatched(persist, "allowSendOldStats", false)

let needSendStats = Computed(@() !isUserstatStatsReceived.get() && serverPlayerEid.get() != null)
let needRequestStats = keepref(Computed(@() needSendStats.get() && !isStatsActual.get()))
let shouldSendStat = keepref(Computed(@() needSendStats.get() && (isStatsActual.get() || allowSendOldStats.get())))

serverPlayerEid.subscribe(function(v) {
  if (v != null)
    return
  isStatsActual.set(false)
  allowSendOldStats.set(false)
})

needRequestStats.subscribe(function(v) {
  if (!v)
    return
  userstatRequest(GET_STATS_ACTION, { data = GET_STATS_AVG_SCORE_FILTER })
  if (jwtUserstat.get() != null)
    resetTimeout(oldStatSendTime, @() allowSendOldStats.set(!isStatsActual.get() && serverPlayerEid.get() != null))
})

userstatRegisterHandler(GET_STATS_ACTION, function(result) {
  if (result?.error || "jwt" not in result?.response) {
    logU("Get stats error: ", result?.error)
    return
  }
  logU("Get stats success")
  jwtUserstat.set(result.response.jwt)
  isStatsActual.set(true)
})

let sendJwt = @() deferOnce(function() {
  if (!shouldSendStat.get())
    return
  logU("Send stats")
  let { payload, jwt } = decodeJwtAndHandleErrors({ jwt = jwtUserstat.get() })
  let { userid = null, timestamp } = payload
  ecs.client_request_unicast_net_sqevent(serverPlayerEid.get(),
    mkCmdSetUserstatJwtStats({ jwtList = splitStringBySize(jwt, 4096) }))
  if (myUserId.get() != userid) {
    logerr($"[BATTLE_USERSTATS] token userId ({userid}) does not same with my user id ({myUserId.get()}). Will be ignored on dedicated.")
    jwtUserstat.set(null)
  }
  let tokenAge = getServerTime() - timestamp
  if (tokenActiveTime <= tokenAge) {
    logerr($"[BATTLE_USERSTATS] token is old. Will be ignored on dedicated.")
    jwtUserstat.set(null)
  }
})

function onInit(eid, comp) {
  let userId = comp.server_player__userId
  if (userId != myUserId.get())
    return
  logU($"isUserstatStatsReceived = {comp.isUserstatStatsReceived} (eid = {eid})")
  isUserstatStatsReceived.set(comp.isUserstatStatsReceived)
  serverPlayerEid.set(eid)
}

function onDestroy(_eid, comp) {
  let userId = comp.server_player__userId
  if (userId != myUserId.get())
    return
  isUserstatStatsReceived.set(false)
  serverPlayerEid.set(null)
}

ecs.register_es("player_userstat_stats_es",
  {
    [["onInit", "onChange"]] = onInit,
    onDestroy = onDestroy,
  },
  {
    comps_ro = [["server_player__userId", ecs.TYPE_UINT64]]
    comps_track = [["isUserstatStatsReceived", ecs.TYPE_BOOL]]
  })

sendJwt()
shouldSendStat.subscribe(@(v) v ? sendJwt() : null)
