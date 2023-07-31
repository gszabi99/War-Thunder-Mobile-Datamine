//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let logPSC = log_with_prefix("[profileServerClient] ")
let { json_to_string } = require("json")
let eventbus = require("eventbus")
let profile = require("profile_server")
let { isAuthAndUpdated } = require("%appGlobals/loginState.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let serverTimeUpdate = require("%appGlobals/userstats/serverTimeUpdate.nut")
let { get_time_msec } = require("dagor.time")
let { defer, setTimeout, resetTimeout } = require("dagor.workcycle")
let { register_command } = require("console")
let { APP_ID } = require("%appGlobals/gameIdentifiers.nut")
let { offlineActions } = require("offlineMenuProfile.nut")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")

const MAX_REQUESTS_HISTORY = 20
const PROGRESS_TIMEOUT_SEC = 30
let debugDelay = mkHardWatched("pserver.debugDelay", 0.0)
let lastRequests = mkHardWatched("pserver.lastRequests", [])
let progressTimeouts = mkHardWatched("pserver.inProgress", {}) //progressId = { value, timeout }
let nextTimeout = keepref(Computed(@() progressTimeouts.value
  .reduce(@(res, v) res <= 0 ? v.timeout : min(res, v.timeout), 0)))

let sendProgress = @(id, value, isInProgress) eventbus.send($"profile_srv.progressStart.{id}", { value, isInProgress })
let get_time_sec = @() (get_time_msec() * 0.001).tointeger()

let function startProgress(id, value) {
  if (id == null)
    return
  progressTimeouts.mutate(@(v) v[id] <- {
    value
    timeout = get_time_sec() + PROGRESS_TIMEOUT_SEC
  })
  sendProgress(id, value, true)
}

let function stopProgress(id) {
  if (id not in progressTimeouts.value)
    return
  let { value } = progressTimeouts.value[id]
  progressTimeouts.mutate(@(v) delete v[id])
  sendProgress(id, value, false)
}

let function collectLastRequestResult(id, data) {
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
      req.resultKeys <- data.result?.keys()  //store only keys, because of data can be really big
    else
      req.error <- data?.error
    reqTime = req?.reqTime ?? 0
  })
  return reqTime
}

let function collectLastRequest(id, action, params) {
  lastRequests.mutate(function(v) {
    if (v.len() >= MAX_REQUESTS_HISTORY)
      v.remove(0)
    v.append({ id, action, params, reqTime = get_time_msec() })
  })
}

let function checkAndLogError(id, action, cb, data) {
  local err = data?.error
  if (err == null && !(data?.response?.success ?? true))
    err = data?.response?.error ?? "unknown error"

  let reqTime = collectLastRequestResult(id, data)

  if (err == null) {
    logPSC($"request {id}: {action} completed without error")

    let { timeMs = 0 } = data?.result
    if (reqTime > 0 && timeMs > 0)
      serverTimeUpdate(timeMs, reqTime)

    cb?(data)
    return
  }

  local logErr = err
  if (type(err) == "table" && "message" in err)
    logErr = " ".concat(err.message, "code" in err ? $"(code: {err.code})" : "")
  else if (type(err) != "string") {
    let dumpStr = json_to_string(data)
    logErr = " ".concat("(full answer dump)", dumpStr)
  }
  logerr($"[profileServerClient] {action} returned error: {logErr}")
  cb?({ error = err })
}

let function doRequestOnline(action, params, id, cb) {
  if (!isAuthAndUpdated.value) {
    logPSC($"Skip action {action}, no token")
    if (cb)
      cb({ error = "Not authorized" })
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

  logPSC($"Sending request {id}, method: {action}")
  profile.request(requestData, @(r) checkAndLogError(id, action, cb, r))
}

let function doRequestOffline(action, params, id, cb) {
  logPSC($"Offline request {id}, method: {action}")
  defer(function() {
    let actionHandler = offlineActions?[action]
    checkAndLogError(id, action, cb,
      actionHandler == null ? { error = "Method does not supported offline" }
       : { result = actionHandler(params) })
  })
}

let doRequest = isOfflineMenu ? doRequestOffline : doRequestOnline

let function sendResult(data, id, progressId) {
  stopProgress(progressId)
  eventbus.send("profile_srv.response", { data, id })
}

let function requestImpl(msg) {
  let { id, data } = msg
  let { progressId = null, progressValue = null } = data
  startProgress(progressId, progressValue)
  doRequest(data.method, data?.params, id, @(resData) sendResult(resData, id, progressId))
}

local request = requestImpl
let function updateDebugDelay() {
  request = (debugDelay.value <= 0) ? requestImpl
    : function(msg) {
        startProgress(msg.data?.progressId, msg.data?.progressValue)
        setTimeout(debugDelay.value, @() requestImpl(msg))
      }
}
updateDebugDelay()
debugDelay.subscribe(@(_) updateDebugDelay())

let function debugLastRequests() {
  log("lastRequests: ")
  debugTableData(lastRequests.value, { recursionLevel = 7 })
}

let function checkTimeouts() {
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

eventbus.subscribe("profile_srv.request", @(msg) request(msg))
eventbus.subscribe("profile_srv.debugLastRequests", debugLastRequests)

//console commands&
register_command(@(delay) debugDelay(delay), "pserver.delay_requests")
register_command(debugLastRequests, "pserver.debug_last_requests")
