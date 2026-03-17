from "%scripts/dagui_library.nut" import *
import "%globalScripts/ecs.nut" as ecs
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { is_multiplayer } = require("%scripts/util.nut")
let { splitStringBySize } = require("%sqstd/string.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { mkCmdSetUserstatJwtStats } = require("%appGlobals/sqevents.nut")
let { getServerTime } = require("%appGlobals/userstats/serverTime.nut")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")
let { decodeJwtAndHandleErrors } = require("%appGlobals/pServer/pServerJwt.nut")
let { userstatRequest, userstatRegisterHandler } = require("%scripts/userstat.nut")


let tokenActiveTime = 60 * 60 * 2
let oldStatSendTime = 20.0

let GET_STATS_ACTION = "GetStats:battle"
let GET_STATS_AVG_SCORE_FILTER = {
  tables = ["global"],
  modes = ["battle_common", "ships", "tanks", "air"],
  stats = ["m_avg_score"],
  sign = true
}

let isUserstatStatsReceived = mkWatched(persist, "isUserstatStatsReceived", false)
let serverPlayerEid = mkWatched(persist, "serverPlayerEid", null)
let jwtUserstat = mkWatched(persist, "jwtUserstat", null)
let needSendStat = mkWatched(persist, "needSendStat", false)

let canRequestUserstat = Computed(@() !isUserstatStatsReceived.get() && isInMpSession.get())
let canSendStat = Computed(@() canRequestUserstat.get()
  && jwtUserstat.get() != null
  && serverPlayerEid.get() != null)
let shouldSendStat = keepref(Computed(@() canSendStat.get() && needSendStat.get()))

canRequestUserstat.subscribe(function(v) {
  if (!v)
    return
  userstatRequest(GET_STATS_ACTION, { data = GET_STATS_AVG_SCORE_FILTER })
  resetTimeout(oldStatSendTime, @() needSendStat.set(true))
})

userstatRegisterHandler(GET_STATS_ACTION, function(result) {
  jwtUserstat.set(result?.response.jwt)
  needSendStat.set(true)
})

let sendJwt = @() deferOnce(function() {
  if (!shouldSendStat.get())
    return
  let { payload, jwt } = decodeJwtAndHandleErrors({ jwt = jwtUserstat.get() })
  let { userid = null, timestamp } = payload
  ecs.client_request_unicast_net_sqevent(serverPlayerEid.get(),
    mkCmdSetUserstatJwtStats({ jwtList = splitStringBySize(jwt, 4096) }))
  if (myUserId.get() != userid) {
    logerr($"[USERSTAT_STATS] token userId ({userid}) does not same with my user id ({myUserId.get()}). Will be ignored on dedicated.")
    jwtUserstat.set(null)
  }
  let tokenAge = getServerTime() - timestamp
  if (tokenActiveTime <= tokenAge) {
    logerr($"[USERSTAT_STATS] token is old. Will be ignored on dedicated.")
    jwtUserstat.set(null)
  }
  needSendStat.set(false)
})

function onInit(eid, comp) {
  let userId = comp.server_player__userId
  if (userId != myUserId.get() || !is_multiplayer())
    return
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
