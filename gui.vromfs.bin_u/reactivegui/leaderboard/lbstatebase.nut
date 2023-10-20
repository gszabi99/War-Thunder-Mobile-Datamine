from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { myUserName, myUserId } = require("%appGlobals/profileStates.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { contactsRequest, contactsRegisterHandler } = require("%rGui/contacts/contactsClient.nut")

const LEADERBOARD_NO_START_LIST_INDEX = 0x7FFFFFFF
const LB_REQUEST_TIMEOUT = 45000
const LB_UPDATE_INTERVAL = 10000 //same lb update time

let curLbData = hardPersistWatched("lb.curLbData", null)
let curLbSelfRow = hardPersistWatched("lb.curLbSelfRow", null)
let curLbRequestData = hardPersistWatched("lb.curLbRequestData", null)
let curLbErrName = hardPersistWatched("lb.curLbErrName", null)
let lastRequestTime = Watched(0)
let lastUpdateTime = Watched(0)
let isRequestTimeout = Watched(false)
let isLbRequestInProgress = Computed(@() !isRequestTimeout.value && lastRequestTime.value > lastUpdateTime.value)


isLbRequestInProgress.subscribe(function(v) {
  deferOnce(@() isRequestTimeout(false))
  if (v)
    resetTimeout(0.001 * LB_REQUEST_TIMEOUT, @() isRequestTimeout(true))
})

let function mkSelfRequest(requestData) {
  if (requestData == null)
    return null
  let res = clone requestData
  res.start <- LEADERBOARD_NO_START_LIST_INDEX
  res.count <- 0
  return res
}

let function setLbRequestData(requestData) {
  if (isEqual(requestData, curLbRequestData.value))
    return

  if (!isEqual(mkSelfRequest(requestData), mkSelfRequest(curLbRequestData.value)))
    curLbSelfRow(null)
  curLbData(null) //should to nullify it before curLbRequestData subscribers receive event
  curLbErrName(null)
  curLbRequestData(requestData)
}

let function requestSelfRow() {
  let requestData = curLbRequestData.value
  if (requestData == null)
    return

  let selfRequest = mkSelfRequest(requestData)
  contactsRequest("cln_get_leaderboard_json:self", { data = selfRequest }, selfRequest)
}

contactsRegisterHandler("cln_get_leaderboard_json:self", function(result, selfRequest) {
  if (!isEqual(selfRequest, mkSelfRequest(curLbRequestData.value)))
    return

  local newSelfRow = result.findvalue(@(v) v?._id == myUserId.value)
    ?.__merge({ name = myUserName.value })
  curLbSelfRow(newSelfRow)
})

let canRefresh = @() !isLbRequestInProgress.value
  && isLoggedIn.value
  && (!curLbData.value || (lastUpdateTime.value + LB_UPDATE_INTERVAL < get_time_msec()))

let function refreshLbData() {
  if (!canRefresh())
    return
  let requestData = curLbRequestData.value
  if (requestData == null) {
    curLbData([])
    curLbErrName(null)
    return
  }
  lastRequestTime(get_time_msec())
  contactsRequest("cln_get_leaderboard_json", { data = requestData }, requestData)
}


contactsRegisterHandler("cln_get_leaderboard_json", function(result, requestData) {
  lastUpdateTime(get_time_msec())
  if (!isEqual(requestData, curLbRequestData.value)) {
    refreshLbData()
    return
  }

  curLbErrName(result?.result.error)

  let isSuccess = result?.result.success ?? true
  let lbTbl = isSuccess ? result : {}
  local selfRow = null
  let newLbData = []
  foreach (name, data in lbTbl) {
    if (typeof data != "table")
      continue
    newLbData.append(data.__merge({ name }))
    if (data?._id == myUserId.value)
      selfRow = newLbData.top()
  }
  newLbData.sort(@(a, b)
    (b?.idx ?? -1) >= 0 <=> (a?.idx ?? -1) >= 0
    || (a?.idx ?? -1) <=> (b?.idx ?? -1))

  if (selfRow)
    curLbSelfRow(selfRow)
  curLbData(newLbData)
})

return {
  curLbData
  curLbSelfRow
  curLbRequestData = Computed(@() curLbRequestData.value)
  curLbErrName = Computed(@() curLbErrName.value)
  isLbRequestInProgress

  setLbRequestData
  refreshLbData
  requestSelfRow
}