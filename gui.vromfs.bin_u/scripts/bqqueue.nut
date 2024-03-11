from "%scripts/dagui_library.nut" import *
let logBQ = log_with_prefix("[BQ] ")
let { APP_ID } = require("app")
let { eventbus_subscribe } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, defer } = require("dagor.workcycle")
let { httpRequest, HTTP_SUCCESS } = require("dagor.http")
let { json_to_string } = require("json")
let { getPlayerToken } = require("auth_wt")
let { get_cur_circuit_block } = require("blkGetters")
let DataBlock = require("DataBlock")
let { shuffle } = require("%sqStdLibs/helpers/u.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { disableNetwork } = require("%appGlobals/clientState/initialState.nut")
let { hasConnection } = require("%appGlobals/clientState/connectionStatus.nut")


const MIN_TIME_BETWEEN_MSEC = 5000 //not send events more often than once per 5 sec
const RETRY_MSEC = 300000 //retry send on error
const RETRY_ON_URL_ERROR_MSEC = 3000
const LOGERR_MIN_ERROR_LOOPS = 3
const MAX_COUNT_MSG_IN_ONE_SEND = 150
const RESPONSE_EVENT = "bq.requestResponse"
let queueByUserId = hardPersistWatched("bqQueue.queueByUserId", {})
let queue = Computed(@() queueByUserId.value?[myUserId.value] ?? [])
let nextCanSendMsec = hardPersistWatched("bqQueue.nextCanSendMsec", -1)
let currentUrlIndex = hardPersistWatched("bqQueue.currentUrlIndex", 0)
let allUrlsFailsCount = hardPersistWatched("bqQueue.allUrlsFailsCount", 0)

let urls = Watched([])
let url = Computed(@() urls.get()?[currentUrlIndex.get()] ?? urls.get()?[0])

function initUrl() {
  urls(shuffle((get_cur_circuit_block()?.cloud_server.servers ?? DataBlock()) % "url"))
  currentUrlIndex(0)
}

initUrl()

let changeUrl = @() currentUrlIndex((currentUrlIndex.get() + 1) % max(urls.get().len(), 1))

function sendAll() {
  if (queue.get().len() == 0 || !hasConnection.get())
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

  if (url.get() == null) {
    nextCanSendMsec(get_time_msec() + RETRY_MSEC)
    logerr("[BQ] Miss bqServer url")
    initUrl()
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
  logBQ($"Request BQ events (total = {count}, remainig = {remainingCount}, userId = {myUserId.get()})")
  if (remainingCount > 0)
    logerr($"[BQ] Too many events piled up to send to BQ. More then {MAX_COUNT_MSG_IN_ONE_SEND}.")

  httpRequest({
    url = url.get()
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

function startSendTimer() {
  if (queue.get().len() == 0 || !hasConnection.get())
    return
  let timeLeft = nextCanSendMsec.value - get_time_msec()
  if (timeLeft > 0)
    resetTimeout(0.001 * timeLeft, sendAll)
  else
    defer(sendAll)
}
startSendTimer()
hasConnection.subscribe(@(_) startSendTimer())

local wasQueueLen = queue.value.len()
queue.subscribe(function(v) {
  if (wasQueueLen == 0 && v.len() != 0)
    startSendTimer()
  wasQueueLen = v.len()
})

eventbus_subscribe(RESPONSE_EVENT, function(res) {
  let { status = -1, http_code = -1, context = null } = res
  if (status == HTTP_SUCCESS && http_code >= 200 && http_code < 300) {
    logBQ($"Success send {context?.list.len()} events")
    if (!(context?.isAllSent ?? true))
      startSendTimer()
    return
  }

  if (hasConnection.get())
    changeUrl()

  if (!hasConnection.get()) {
    logBQ($"(No connection) Failed to send {context?.list.len()} events to BQ. status = {status}, http_code = {http_code}. Retry after {0.001 * RETRY_ON_URL_ERROR_MSEC} sec")
    nextCanSendMsec(get_time_msec() + RETRY_ON_URL_ERROR_MSEC)
  }
  else if (currentUrlIndex.value == 0) {
    logBQ($"Failed to send {context?.list.len()} events to BQ. status = {status}, http_code = {http_code}. Retry after {0.001 * RETRY_MSEC} sec")
    allUrlsFailsCount.set(allUrlsFailsCount.get() + 1)
    if (allUrlsFailsCount.get() == LOGERR_MIN_ERROR_LOOPS)
      logerr($"[BQ] Failed to send data. All servers down {LOGERR_MIN_ERROR_LOOPS} times.")
    nextCanSendMsec(get_time_msec() + RETRY_MSEC)
    initUrl()
  }
  else {
    logBQ($"Failed to send {context?.list.len()} events to BQ. status = {status}, http_code = {http_code}. Retry after {0.001 * RETRY_ON_URL_ERROR_MSEC} sec")
    nextCanSendMsec(get_time_msec() + RETRY_ON_URL_ERROR_MSEC)
  }

  if (context != null) {
    let { userId, list } = context
    queueByUserId.mutate(@(v) v[userId] <- (clone list).extend(v?[userId] ?? []))
  }
})

if (!disableNetwork) {
  eventbus_subscribe("sendBqEvent", @(msg) queueByUserId.mutate(
    @(v) v[myUserId.value] <- (clone (v?[myUserId.value] ?? [])).append(msg)))

  eventbus_subscribe("app.shutdown", @(_) sendAll())
}

return {
  forceSendBqQueue = sendAll
}