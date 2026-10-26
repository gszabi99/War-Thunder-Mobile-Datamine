from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%rGui/matching/matchingApi.nut" import mnGenericSubscribe
from "%appGlobals/pServer/pServerApi.nut" import registerHandler, clan_get_logs, clanLogsInProgress
from "%rGui/clans/clanPermissions.nut" import CLAN_GET_LOGS, clanGrades, hasClanPermission
from "%rGui/clans/currentClanState.nut" import NO_CLAN_ID, currentClanId, hasConfirmedClan, myClanGrade,
  isReadyToConnect, mkIsTimePassed


const REQUEST_TIMEOUT_MS = 45000
const ERROR_RETRY_MS = 60000
const CLAN_LOGS_ID = "on_get_clan_logs"
const CLAN_LOGS_MAX_COUNT = 100

let clanLogs = hardPersistWatched("clan.logsList", null)
let isClanLogsOutdated = Watched(false)
let clanLogsErrorTime = Watched(0)
let canRepeatClanLogs = mkIsTimePassed(clanLogsErrorTime, ERROR_RETRY_MS)
let clanLogsRequestTime = Watched(0)
let isClanLogsRequestTimedOut = mkIsTimePassed(clanLogsRequestTime, REQUEST_TIMEOUT_MS)
let canGetClanLogs = Computed(@() hasClanPermission(CLAN_GET_LOGS, clanGrades.get(), myClanGrade.get()))

let needRefreshClanLogs = keepref(Computed(@() isClanLogsOutdated.get() && hasConfirmedClan.get()
  && canGetClanLogs.get() && isReadyToConnect.get() && !clanLogsInProgress.get() && !isInBattle.get()
  && canRepeatClanLogs.get()))

function refreshClanLogs() {
  isClanLogsOutdated.set(false)
  clanLogsRequestTime.set(get_time_msec())
  let clanId = currentClanId.get()
  clan_get_logs(clanId, CLAN_LOGS_MAX_COUNT, "", { id = CLAN_LOGS_ID, clanId })
}

function makeClanLogsList(res) {
  let logs = []
  foreach (entry in res) {
    let oid = entry?._id["$oid"]
    if (oid == null)
      continue

    
    let timestamp = oid.slice(0, 8).tointeger(16)
    foreach (idx, order in (entry?.orders ?? [])) {
      let data = order?.data
      let userId = data?.userId ?? data?.user.userId
      if (userId == null)
        continue
      logs.append({
        timestamp
        key = $"{oid}_{idx}"
        userIdStr = userId.tostring()
        kind = order?.meta.kind
        gradeStr = data?.gradeStr ?? data?.user.gradeStr
      })
    }
  }
  logs.sort(@(a, b) a.timestamp <=> b.timestamp || a.key <=> b.key)
  return logs
}

registerHandler(CLAN_LOGS_ID, function(res, context) {
  clanLogsRequestTime.set(0)
  if (context.clanId != currentClanId.get())
    return
  if (res?.error != null) {
    clanLogsErrorTime.set(get_time_msec())
    isClanLogsOutdated.set(true)
    return
  }
  clanLogsErrorTime.set(0)
  clanLogs.set(makeClanLogsList(res))
})

let invalidateClanLogs = @() currentClanId.get() != NO_CLAN_ID
  ? isClanLogsOutdated.set(true)
  : clanLogs.set(null)

function onClanIdChanged() {
  clanLogs.set(null)
  clanLogsErrorTime.set(0)
  invalidateClanLogs()
}

mnGenericSubscribe("profile", function(event) {
  if (event?.func == "clan_update")
    isClanLogsOutdated.set(true)
})

invalidateClanLogs()
currentClanId.subscribe(@(_) onClanIdChanged())
myClanGrade.subscribe(@(_) invalidateClanLogs())
canGetClanLogs.subscribe(@(v) v ? null : clanLogs.set(null))

isClanLogsRequestTimedOut.subscribe(function(v) {
  if (!v || clanLogsRequestTime.get() <= 0)
    return
  clanLogsRequestTime.set(0)
  isClanLogsOutdated.set(true)
})

if (needRefreshClanLogs.get())
  refreshClanLogs()
needRefreshClanLogs.subscribe(@(v) v ? refreshClanLogs() : null)

return {
  clanLogs
}
