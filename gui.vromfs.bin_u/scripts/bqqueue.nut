from "%scripts/dagui_library.nut" import *
let { APP_ID } = require("app")
let { subscribe } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, defer } = require("dagor.workcycle")
let { request, HTTP_SUCCESS } = require("dagor.http")
let { json_to_string } = require("json")
let { getPlayerToken } = require("auth_wt")
let { get_cur_circuit_block } = require("blkGetters")
let logBQ = log_with_prefix("[BQ] ")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { disableNetwork } = require("%appGlobals/clientState/initialState.nut")

const MIN_TIME_BETWEEN_MSEC = 5000 //not send events more often than once per 5 sec
const RETRY_MSEC = 300000 //retry send on error
const MAX_COUNT_MSG_IN_ONE_SEND = 150
const RESPONSE_EVENT = "bq.requestResponse"
let queueByUserId = hardPersistWatched("bqQueue.queueByUserId", {})
let queue = Computed(@() queueByUserId.value?[myUserId.value] ?? [])
let nextCanSendMsec = hardPersistWatched("bqQueue.nextCanSendMsec", -1)
let errorsInARow = hardPersistWatched("bqQueue.errorsInARow", 0)

let function sendAll() {
  if (queue.value.len() == 0)
    return

  let list = {}
  let remainingMsg = []
  let sendedMsg = []
  local count = 0
  foreach(msg in queue.value) {
    let { tableId = null, data = null } = msg
    if (type(tableId) != "string" || type(data) != "table") {
      logerr($"[BQ] Bad type of tableId or data for event: tableId = {tableId}, type of data = {type(data)}")
      continue
    }
    if (count >= MAX_COUNT_MSG_IN_ONE_SEND) {
      remainingMsg.append(msg)
      continue
    }
    if (tableId not in list)
      list[tableId] <- []
    list[tableId].append(data)
    sendedMsg.append(msg)
    count++
  }

  queueByUserId.mutate(@(v) v[myUserId.value] <- remainingMsg)
  if (count == 0)
    return

  let url = get_cur_circuit_block()?.cloud_server.servers.url ?? ""
  if (url == "") {
    nextCanSendMsec(get_time_msec() + RETRY_MSEC)
    logerr("[BQ] Miss bqServer url")
    return
  }

  nextCanSendMsec(max(nextCanSendMsec.value, get_time_msec() + MIN_TIME_BETWEEN_MSEC))

  let token = getPlayerToken()
  let headers = {
    action = token == "" ? "noa_bigquery_client_noauth" : "cln_bq_put_batch_json"
    appid  = APP_ID
    token
    withAppid = true
    withCircuit = true
  }

  let remainingCount = remainingMsg.len()
  logBQ($"Request BQ events (total = {count}, remainig = {remainingCount})")
  if (remainingCount > 0)
    logerr($"[BQ] Too many events piled up to send to BQ. More then {MAX_COUNT_MSG_IN_ONE_SEND}.")

  request({
    url
    headers
    waitable = true
    data = json_to_string(list)
    respEventId = RESPONSE_EVENT
    context = {
      userId = myUserId.value
      list = sendedMsg
      isAllSent = remainingCount == 0
    }
  })
}

let function startSendTimer() {
  if (queue.value.len() == 0)
    return
  let timeLeft = nextCanSendMsec.value - get_time_msec()
  if (timeLeft > 0)
    resetTimeout(0.001 * timeLeft, sendAll)
  else
    defer(sendAll)
}
startSendTimer()

subscribe(RESPONSE_EVENT, function(res) {
  let { status = -1, http_code = -1, context = null } = res
  if (status == HTTP_SUCCESS && http_code >= 200 && http_code < 300) {
    logBQ($"Success send {context?.list.len()} events")
    errorsInARow(0)
    if (!(context?.isAllSent ?? true))
      startSendTimer()
    return
  }

  logBQ($"Failed to send {context?.list.len()} events to BQ. status = {status}, http_code = {http_code}. Retry after {0.001 * RETRY_MSEC} sec")
  if (context != null) {
    let { userId, list } = context
    queueByUserId.mutate(@(v) v[userId] <- (clone list).extend(v?[userId] ?? []))
  }
  nextCanSendMsec(get_time_msec() + RETRY_MSEC)
  errorsInARow(errorsInARow.value + 1)
  if (errorsInARow.value == 3)
    logerr("[BQ] Failed to send data 3 times in a row.")
})

local wasQueueLen = queue.value.len()
queue.subscribe(function(v) {
  if (wasQueueLen == 0 && v.len() != 0)
    startSendTimer()
  wasQueueLen = v.len()
})

if (!disableNetwork) {
  subscribe("sendBqEvent", @(msg) queueByUserId.mutate(
    @(v) v[myUserId.value] <- (clone (v?[myUserId.value] ?? [])).append(msg)))

  subscribe("app.shutdown", @(_) sendAll())
}

return {
  forceSendBqQueue = sendAll
}