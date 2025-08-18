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
const LB_UPDATE_INTERVAL = 10000 

let curLbData = hardPersistWatched("lb.curLbData", null)
let curLbSelfRow = hardPersistWatched("lb.curLbSelfRow", null)
let curLbRequestData = hardPersistWatched("lb.curLbRequestData", null)
let curLbErrName = hardPersistWatched("lb.curLbErrName", null)
let lastRequestTime = Watched(0)
let lastUpdateTime = Watched(0)
let isRequestTimeout = Watched(false)
let isLbRequestInProgress = Computed(@() !isRequestTimeout.get() && lastRequestTime.get() > lastUpdateTime.get())


isLbRequestInProgress.subscribe(function(v) {
  deferOnce(@() isRequestTimeout.set(false))
  if (v)
    resetTimeout(0.001 * LB_REQUEST_TIMEOUT, @() isRequestTimeout.set(true))
})

function mkSelfRequest(requestData) {
  if (requestData == null)
    return null
  let res = clone requestData
  res.start <- LEADERBOARD_NO_START_LIST_INDEX
  res.count <- 0
  return res
}

function setLbRequestData(requestData) {
  if (isEqual(requestData, curLbRequestData.get()))
    return

  if (!isEqual(mkSelfRequest(requestData), mkSelfRequest(curLbRequestData.get())))
    curLbSelfRow(null)
  curLbData(null) 
  curLbErrName(null)
  curLbRequestData(requestData)
}

function requestSelfRow() {
  let requestData = curLbRequestData.get()
  if (requestData == null)
    return

  let selfRequest = mkSelfRequest(requestData)
  contactsRequest("cln_get_leaderboard_json:self", { data = selfRequest }, selfRequest)
}

contactsRegisterHandler("cln_get_leaderboard_json:self", function(result, selfRequest) {
  if (!isEqual(selfRequest, mkSelfRequest(curLbRequestData.get())))
    return

  local newSelfRow = result.findvalue(@(v) v?._id == myUserId.get())
    ?.__merge({ name = myUserName.get() })
  curLbSelfRow(newSelfRow)
})

let canRefresh = @() !isLbRequestInProgress.get()
  && isLoggedIn.get()
  && (!curLbData.get() || (lastUpdateTime.get() + LB_UPDATE_INTERVAL < get_time_msec()))

function refreshLbData() {
  if (!canRefresh())
    return
  let requestData = curLbRequestData.get()
  if (requestData == null) {
    curLbData([])
    curLbErrName(null)
    return
  }
  lastRequestTime.set(get_time_msec())
  contactsRequest("cln_get_leaderboard_json", { data = requestData }, requestData)
}


contactsRegisterHandler("cln_get_leaderboard_json", function(result, requestData) {
  lastUpdateTime.set(get_time_msec())
  if (!isEqual(requestData, curLbRequestData.get())) {
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
    if (data?._id == myUserId.get())
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
  curLbRequestData = Computed(@() curLbRequestData.get())
  curLbErrName = Computed(@() curLbErrName.get())
  isLbRequestInProgress

  setLbRequestData
  refreshLbData
  requestSelfRow
}