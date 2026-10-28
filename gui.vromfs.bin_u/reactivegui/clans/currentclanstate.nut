from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "dagor.workcycle" import resetTimeout
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/clientState/initialState.nut" import projectId
from "%appGlobals/loginState.nut" import isProfileReceived, isMatchingConnected
from "%rGui/matching/matchingApi.nut" import mnGenericSubscribe
from "%appGlobals/pServer/pServerApi.nut" import get_user_clan_info, get_clan_info, registerHandler,
  clan_join_list, clan_update_login_timestamp, refresh_clan_public_info
from "%appGlobals/permissions.nut" import allow_clans
from "%appGlobals/profileStates.nut" import myUserId
from "%rGui/clans/clanPermissions.nut" import CLAN_JOIN_LIST, clanGrades, hasClanPermission
from "%rGui/clans/clanPublicInfo.nut" import updateClanPublicInfo, removeUserClan


const REQUEST_TIMEOUT_MS = 45000
const ERROR_RETRY_MS = 60000
const JOIN_LIST_ID = "on_clan_join_list"
const NO_CLAN_ID = -1
const CLAN_INFO_LIFETIME_MS = 1800000 

let isReadyToConnect = Computed(@() isProfileReceived.get() && isMatchingConnected.get() && allow_clans.get())

let isClanProfileChanged = hardPersistWatched("currentClan.isClanProfileChanged", false)
let currentClan = hardPersistWatched("currentClan.data", null)
let currentClanId = hardPersistWatched("currentClan.clanId", NO_CLAN_ID)
let isClanActual = hardPersistWatched("currentClan.isClanActual", true)
let lastUserClanInfoReqId = hardPersistWatched("currentClan.lastUserClanInfoReqId", 0)
let myClanGrade = hardPersistWatched("currentClan.myClanGrade", null)
let lastTime = hardPersistWatched("currentClan.lastTime", { request = 0, update = 0 })
let lastErrorTime = hardPersistWatched("currentClan.lastErrorTime", 0)
let lastStatusUpdateErrorTime = hardPersistWatched("currentClan.lastStatusUpdateErrorTime", 0)
let shouldRefreshPublicInfo = hardPersistWatched("currentClan.shouldRefreshPublicInfo", true)
let shouldUpdateUserRequests = hardPersistWatched("currentClan.shouldUpdateUserRequests", false)
let needUpdateUserRequests = Computed(@() isReadyToConnect.get() && shouldUpdateUserRequests.get())
let hasConfirmedClan = Computed(@() currentClanId.get() != NO_CLAN_ID && isClanActual.get())

lastErrorTime.setImmediate(true)
lastStatusUpdateErrorTime.setImmediate(true)
function mkIsTimePassed(timeComp, addMs, calcTime = @(v) v) {
  let res = Watched(false)
  function update() {
    let t = calcTime(timeComp.get())
    let left = t <= 0 ? 0 : t + addMs - get_time_msec()
    res.set(left <= 0)
    if (left > 0)
      resetTimeout(0.001 * left, update)
  }
  update()
  timeComp.subscribe(@(_) update())
  return res
}

let canRepeatAfterError = mkIsTimePassed(lastErrorTime, ERROR_RETRY_MS)
let shouldRepeatStatusUpdate = mkIsTimePassed(lastStatusUpdateErrorTime, ERROR_RETRY_MS)
let isTimeoutAfterRequest = mkIsTimePassed(lastTime, REQUEST_TIMEOUT_MS, @(v) v.request)
let isRequestInProgress = Computed(@() lastTime.get().request > lastTime.get().update && !isTimeoutAfterRequest.get())
let isClanInfoTimeExpired = mkIsTimePassed(lastTime, CLAN_INFO_LIFETIME_MS, @(v) isRequestInProgress.get() ? get_time_msec() : v.update)
let isTimeExpired = Computed(@() currentClanId.get() != NO_CLAN_ID && isClanInfoTimeExpired.get())

let canRefresh = @() !isRequestInProgress.get() && !isInBattle.get()

function sendOnlineStatusUpdate(clanId) {
  lastStatusUpdateErrorTime.set(0)
  clan_update_login_timestamp(clanId, { id = "player_status_update" })
}

registerHandler("player_status_update", function(res) {
  if (res?.error != null)
    lastStatusUpdateErrorTime.set(get_time_msec())
})

let shouldTriggerStatusUpdate = keepref(Computed(@() lastStatusUpdateErrorTime.get() != 0
  && isReadyToConnect.get()
  && !isInBattle.get()
  && currentClanId.get() != NO_CLAN_ID
  && shouldRepeatStatusUpdate.get()
))

shouldTriggerStatusUpdate.subscribe(function(v) {
  if (v)
    sendOnlineStatusUpdate(currentClanId.get())
})

registerHandler("on_user_clan_info", function(res, context) {
  if (context?.reqId != lastUserClanInfoReqId.get())
    return
  if (res?.error != null) {
    lastTime.mutate(@(v) v.update = get_time_msec())
    lastErrorTime.set(get_time_msec())
    return
  }
  let clanId = res?.clanId ?? NO_CLAN_ID
  currentClanId.set(clanId)
  isClanActual.set(true)
  myClanGrade.set(res?.gradeStr)
  shouldUpdateUserRequests.set(true)
  if (clanId == NO_CLAN_ID) {
    shouldRefreshPublicInfo.set(false)
    currentClan.set(null)
    removeUserClan(myUserId.get())
    lastTime.mutate(@(v) v.update = get_time_msec())
    lastErrorTime.set(0)
    return
  }
  if (isReadyToConnect.get()) {
    get_clan_info(clanId, { id = "on_clan_info", clanId })
    sendOnlineStatusUpdate(clanId)
    if (shouldRefreshPublicInfo.get()) {
      shouldRefreshPublicInfo.set(false)
      refresh_clan_public_info(projectId)
    }
    if (hasClanPermission(CLAN_JOIN_LIST, clanGrades.get(), res?.gradeStr))
      clan_join_list(clanId, { id = JOIN_LIST_ID, clanId })
  }
})

registerHandler("on_clan_info", function(res, context) {
  let { clanId } = context
  if (clanId != currentClanId.get())
    return
  lastTime.mutate(@(v) v.update = get_time_msec())
  if (res?.error != null) {
    lastErrorTime.set(get_time_msec())
    return
  }
  currentClan.set(res.__merge({ clanId }))
  updateClanPublicInfo(currentClan.get())
  lastErrorTime.set(0)
})

function refresh() {
  if (!isReadyToConnect.get() || !canRefresh())
    return
  lastTime.mutate(@(v) v.request = get_time_msec())
  lastUserClanInfoReqId.modify(@(v) v + 1)
  get_user_clan_info(myUserId.get(), { id = "on_user_clan_info", reqId = lastUserClanInfoReqId.get() })
}

function resetCurrentClanInfo() {
  currentClan.set(null)
  currentClanId.set(NO_CLAN_ID)
  isClanActual.set(true)
  myClanGrade.set(null)
}

function forceRefresh() {
  lastTime.mutate(@(v) v.__update({ request = 0, update = 0 }))
  refresh()
}

function onClanInfoChanged() {
  isClanActual.set(false)
  if (isInBattle.get()) {
    isClanProfileChanged.set(true)
    return
  }
  forceRefresh()
}

isInBattle.subscribe(function(inBattle) {
  if (!inBattle && isClanProfileChanged.get()) {
    isClanProfileChanged.set(false)
    forceRefresh()
  }
})

isReadyToConnect.subscribe(function(v) {
  if (v) {
    shouldRefreshPublicInfo.set(true)
    forceRefresh()
  }
  else {
    resetCurrentClanInfo()
  }
})
if (isReadyToConnect.get() && lastTime.get().update <= 0)
  refresh()

let isActual = Computed(@() lastErrorTime.get() == 0
  && lastTime.get().update > 0
  && !isTimeExpired.get()
)
let shouldUpdate = keepref(Computed(@() !isActual.get()
  && !isRequestInProgress.get()
  && canRepeatAfterError.get()
  && !isInBattle.get()))
shouldUpdate.subscribe(@(v) v ? forceRefresh() : null)

let myClanJoinTime = Computed(function() {
  let myId = myUserId.get()
  return currentClan.get()?.users.findvalue(@(u) u.userId == myId)?.joinedTimestamp
})
let myClanFastProgressAccess = Computed(@() currentClan.get()?.fastProgressAccess ?? false)

mnGenericSubscribe("profile", function(event) {
  if (event?.func == "clan_update")
    onClanInfoChanged()
  if (event?.func == "clan_requests_decline")
    shouldUpdateUserRequests.set(true)
})

return {
  JOIN_LIST_ID
  NO_CLAN_ID
  currentClan
  currentClanId
  hasConfirmedClan
  myClanGrade
  myClanJoinTime
  myClanFastProgressAccess
  forceRefreshCurrentClan = forceRefresh
  isCurrentClanRefreshing = isRequestInProgress
  resetCurrentClanInfo
  shouldUpdateUserRequests
  needUpdateUserRequests
  isReadyToConnect
  mkIsTimePassed
}
