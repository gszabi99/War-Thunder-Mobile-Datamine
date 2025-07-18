from "%scripts/dagui_library.nut" import *
let logPSC = log_with_prefix("[profileServerClient] ")
let { object_to_json_string } = require("json")
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let profile = require("profile_server")
let { frnd } = require("dagor.random")
let { defer, deferOnce, setTimeout, resetTimeout } = require("dagor.workcycle")
let { isAuthAndUpdated } = require("%appGlobals/loginState.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let serverTimeUpdate = require("%appGlobals/userstats/serverTimeUpdate.nut")
let { get_time_msec } = require("dagor.time")
let { register_command } = require("console")
let { APP_ID } = require("%appGlobals/gameIdentifiers.nut")
let { offlineActions } = require("offlineMenuProfile.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { startRelogin } = require("%scripts/login/loginStart.nut")

const MAX_REQUESTS_HISTORY = 20
const PROGRESS_TIMEOUT_SEC = 90 
const RESULT_ID = "pserver.requestResult"
let debugDelay = hardPersistWatched("pserver.debugDelay", 0.0)
let lastRequests = hardPersistWatched("pserver.lastRequests", [])
let progressTimeouts = hardPersistWatched("pserver.inProgress", {}) 
let nextTimeout = keepref(Computed(@() progressTimeouts.value
  .reduce(@(res, v) res <= 0 ? v.timeout : min(res, v.timeout), 0)))

let sendProgress = @(id, value, isInProgress) eventbus_send($"profile_srv.progressChange", { id, value, isInProgress })
let get_time_sec = @() (get_time_msec() * 0.001).tointeger()

let noNeedLogerrOnErrors = {
  ["Couldn't connect to server"] = true,
  ["Timeout was reached"] = true,
  RETRY_LIMIT_EXCEED = true,
  unknownDeeplinkReward = true,
  notAllowedDeeplinkReward = true,
  NO_TOKEN = true
}

let retryErrId = " RETRY"
let MAX_RETRIES = 2
local debugError = null

let retryActionsCounter = {}

function startProgress(id, value) {
  if (id == null)
    return
  progressTimeouts.mutate(@(v) v[id] <- {
    value
    timeout = get_time_sec() + PROGRESS_TIMEOUT_SEC
  })
  sendProgress(id, value, true)
}

function stopProgress(id) {
  if (id not in progressTimeouts.value)
    return
  let { value } = progressTimeouts.value[id]
  progressTimeouts.mutate(@(v) v.$rawdelete(id))
  sendProgress(id, value, false)
}

function sendResult(resData, id, progressId, method) {
  stopProgress(progressId)
  eventbus_send("profile_srv.response", { data = resData, id, method })
}

function collectLastRequestResult(id, data) {
  local reqTime = 0
  lastRequests.mutate(function(v) {
    local req = v.findvalue(@(d) d.id == id)
    if (req == null) {
      req = { id, action = "unknown" }
      if (v.len() >= MAX_REQUESTS_HISTORY)
        v.remove(0)
      v.append(req)
    }
    if (data?.result)
      req.resultKeys <- data.result?.keys()  
    else
      req.error <- data?.error
    reqTime = req?.reqTime ?? 0
  })
  return reqTime
}

function collectLastRequest(id, action, params) {
  lastRequests.mutate(function(v) {
    if (v.len() >= MAX_REQUESTS_HISTORY)
      v.remove(0)
    v.append({ id, action, params, reqTime = get_time_msec() })
  })
}

let paramLogRemap = {
  ["array"] = @(v) $"array:{v.len()}",
  ["table"] = @(v) $"table:{v.len()}",
}

let getParamsLog = @(params) params == null ? "null"
  : object_to_json_string(params.map(@(v) paramLogRemap?[type(v)](v) ?? v))

local doRequest = null 

eventbus_subscribe(RESULT_ID, function checkAndLogError(msg) {
  local result = clone msg
  let actionFull  = result?.$rawdelete("$action")
  let context = result?.$rawdelete("$context")
  if (actionFull == null) {
    logerr($"PServer request result process: No '$action' in result")
    return
  }
  if (context == null) {
    logerr($"PServer request result process: Empty '$context' in result")
    return
  }

  let { id, params, progressId, action } = context

  local err = debugError ?? result?.error
  debugError = null
  if (err == null && !(result?.response.success ?? true))
    err = result?.response.error ?? "unknown error"
  let reqTime = collectLastRequestResult(id, result)

  if (err == null) {
    logPSC($"request {id}: {action} completed without error")

    let { timeMs = 0 } = result?.result
    if (reqTime > 0 && timeMs > 0)
      serverTimeUpdate(timeMs, reqTime)
    retryActionsCounter.$rawdelete(action)

    sendResult(result, id, progressId, action)
    return
  }

  local errId = err
  local logErr = err
  if (type(err) == "table" && "message" in err) {
    errId = err.message
    logErr = " ".concat(err.message, "code" in err ? $"(code: {err.code})" : "")
  }
  else if (type(err) != "string") {
    let dumpStr = object_to_json_string(result)
    logErr = " ".concat("(full answer dump)", dumpStr)
  }

  if (type(errId) == "string" && errId.endswith(retryErrId)) {
    let count = retryActionsCounter?[action] ?? 0
    if (count < MAX_RETRIES) {
      retryActionsCounter[action] <- count + 1
      doRequest(action, params, id, progressId)
      return
    }
  }

  retryActionsCounter.$rawdelete(action)
  if (errId not in noNeedLogerrOnErrors)
    logerr($"[profileServerClient] {action} returned error: {logErr} /*params = {getParamsLog(params)}*/")
  sendResult({ error = err }, id, progressId, action)

  if (errId == "NO_TOKEN")
    deferOnce(startRelogin)
})

function doRequestOnline(action, params, id, progressId) {
  if (!isAuthAndUpdated.value) {
    logPSC($"Skip action {action}, no token")
    sendResult({ error = "Not authorized" }, id, progressId, action)
    return
  }

  collectLastRequest(id, action, params)

  let actionEx = $"das.{action}"
  let reqData = {
    method = actionEx
    id = id
    jsonrpc = "2.0"
  }
  if (params != null)
    reqData.params <- params

  let requestData = {
    headers = { appid = APP_ID }
    add_token = true
    action = actionEx
    data = reqData
  }

  logPSC($"Sending request {id}, method: {action}, params: {getParamsLog(params)}")
  profile.requestEventBus(requestData, RESULT_ID, { id, params, progressId, action })
}

function doRequestOffline(action, params, id, progressId) {
  logPSC($"Offline request {id}, method: {action}, params: {getParamsLog(params)}")
  defer(function() {
    let actionHandler = offlineActions?[action]
    eventbus_send(RESULT_ID,
      {
        ["$action"] = $"das.{action}",
        ["$context"] = { id, params, progressId, action },
        error = actionHandler == null ? "Method does not supported offline" : null,
        result = actionHandler?(params),
      })
  })
}

doRequest = isOfflineMenu ? doRequestOffline : doRequestOnline

function requestImpl(msg) {
  let { id, data } = msg
  let { progressId = null, progressValue = null } = data
  startProgress(progressId, progressValue)
  doRequest(data.method, data?.params, id, progressId)
}

local request = requestImpl
function updateDebugDelay() {
  request = (debugDelay.value <= 0) ? requestImpl
    : function(msg) {
        startProgress(msg.data?.progressId, msg.data?.progressValue)
        setTimeout(max(0.2, frnd()) * debugDelay.value, @() requestImpl(msg))
      }
}
updateDebugDelay()
debugDelay.subscribe(@(_) updateDebugDelay())

function debugLastRequests() {
  log("lastRequests: ")
  debugTableData(lastRequests.value, { recursionLevel = 7 })
}

function checkTimeouts() {
  let time = get_time_sec()
  let finished = progressTimeouts.value.filter(@(v) v.timeout <= time)
  if (finished.len() == 0)
    return
  progressTimeouts(progressTimeouts.value.filter(@(_, id) id not in finished))
  finished.each(@(v, id) sendProgress(id, v.value, false))
}
checkTimeouts()
let startNextTimer = @(t) t <= 0 ? null : resetTimeout(t - get_time_sec(), checkTimeouts)
startNextTimer(nextTimeout.value)
nextTimeout.subscribe(startNextTimer)

eventbus_subscribe("profile_srv.request", @(msg) request(msg))
eventbus_subscribe("profile_srv.debugLastRequests", debugLastRequests)


register_command(@(delay) debugDelay(delay), "pserver.delay_requests")
register_command(debugLastRequests, "pserver.debug_last_requests")
register_command(function(errId) { debugError = errId }, "pserver.debug_next_request_error")
