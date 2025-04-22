from "%scripts/dagui_library.nut" import *
let logBQ = log_with_prefix("[BQ] ")
let { APP_ID } = require("app")
let { eventbus_subscribe } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, defer } = require("dagor.workcycle")
let { httpRequest, HTTP_SUCCESS } = require("dagor.http")
let { object_to_json_string } = require("json")
let { getPlayerToken } = require("auth_wt")
let { get_cur_circuit_block } = require("blkGetters")
let DataBlock = require("DataBlock")
let { INVALID_USER_ID } = require("matching.errors")
let { shuffle } = require("%sqStdLibs/helpers/u.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { disableNetwork } = require("%appGlobals/clientState/initialState.nut")
let { hasConnection } = require("%appGlobals/clientState/connectionStatus.nut")
let { getServerTimeAt, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")


const MIN_TIME_BETWEEN_MSEC = 5000 
const RETRY_MSEC = 300000 
const RETRY_ON_URL_ERROR_MSEC = 3000
const LOGERR_MIN_ERROR_LOOPS = 3
const MAX_COUNT_MSG_IN_ONE_SEND = 150
const RESPONSE_EVENT = "bq.requestResponse"
const FILL_SERVER_TIME = "$fillServerTime"
let queueByUserId = hardPersistWatched("bqQueue.queueByUserId", {})
let queueByUserIdDelayed = hardPersistWatched("bqQueue.queueByUserIdDelayed", {})
let queue = Computed(@() queueByUserId.value?[myUserId.value] ?? [])
let queueBeforeLogin = Computed(@() queueByUserId.value?[INVALID_USER_ID] ?? [])
let hasEventsToSend = Computed(@() queue.get().len() != 0 || queueBeforeLogin.get().len() != 0)
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
  if (!hasEventsToSend.get() || !hasConnection.get())
    return

  local userId = myUserId.get()
  local queueList = queue.get()
  if (queueList.len() == 0) {
    userId = INVALID_USER_ID
    queueList = queueBeforeLogin.get()
  }

  let list = {}
  let remainingMsg = []
  let sendedMsg = []
  local count = 0
  foreach(msg in queueList) {
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

  queueByUserId.mutate(@(v) v[userId] <- remainingMsg)
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
  }

  let remainingCount = remainingMsg.len()
  logBQ($"Request BQ events (total = {count}, remainig = {remainingCount}, userId = {userId})")
  if (remainingCount > 0)
    logerr($"[BQ] Too many events piled up to send to BQ. More then {MAX_COUNT_MSG_IN_ONE_SEND}.")

  httpRequest({
    url = url.get()
    headers
    waitable = true
    data = object_to_json_string(list)
    respEventId = RESPONSE_EVENT
    context = {
      userId
      list = sendedMsg
      isAllSent = remainingCount == 0
    }
  })
}

function startSendTimer() {
  if (!hasEventsToSend.get() || !hasConnection.get())
    return
  let timeLeft = nextCanSendMsec.value - get_time_msec()
  if (timeLeft > 0)
    resetTimeout(0.001 * timeLeft, sendAll)
  else
    defer(sendAll)
}
startSendTimer()
hasConnection.subscribe(@(_) startSendTimer())
hasEventsToSend.subscribe(@(v) v ? startSendTimer() : null)

eventbus_subscribe(RESPONSE_EVENT, function(res) {
  let { status = -1, http_code = -1, context = null } = res
  if (status == HTTP_SUCCESS && http_code >= 200 && http_code < 300) {
    logBQ($"Success send {context?.list.len()} events")
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
  startSendTimer()
})

let appendEvent = @(qByUserIdWatch, userId, event)
  qByUserIdWatch.mutate(@(v) v[userId] <- (clone (v?[userId] ?? [])).append(event))

let applyDelayedEvents = @(delayedByUserId)
  queueByUserId.mutate(function(v) {
    foreach(userId, list in delayedByUserId) {
      v[userId] <- clone (v?[userId] ?? [])
      foreach(event in list) {
        let data = clone event.data
        let { key, timeMsec } = data[FILL_SERVER_TIME]
        data.$rawdelete(FILL_SERVER_TIME)
        data[key] <- getServerTimeAt(timeMsec)
        v[userId].append(event.__merge({ data }))
      }
    }
  })

function applyCurDelayedEvents() {
  if (queueByUserIdDelayed.get().len() == 0)
    return
  applyDelayedEvents(queueByUserIdDelayed.get())
  queueByUserIdDelayed.set({})
}

if (!disableNetwork) {
  if (isServerTimeValid.get())
    applyCurDelayedEvents()
  isServerTimeValid.subscribe(@(v) v ? applyCurDelayedEvents() : null)

  eventbus_subscribe("sendBqEvent",
    function(event) {
      let userId = myUserId.get()
      if (FILL_SERVER_TIME not in event?.data)
        appendEvent(queueByUserId, userId, event)
      else if (!isServerTimeValid.get())
        appendEvent(queueByUserIdDelayed, userId, event)
      else
        applyDelayedEvents({ [userId] = [event] })
    })

  eventbus_subscribe("app.shutdown", function(_) {
    applyCurDelayedEvents()
    sendAll()
  })
}

return {
  forceSendBqQueue = sendAll
}