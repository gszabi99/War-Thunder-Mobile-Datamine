from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { request, HTTP_SUCCESS } = require("dagor.http")
let { parse_json } = require("json")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { get_cur_circuit_name } = require("app")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { isInBattle, isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")

const REQUEST_PERIOD_MSEC = 1800000
const ACTUAL_VERSION_ID = "actualVersion.response"
let proj = {
  ["wtm-production"] = "wtm_production",
  ["wtm-staging"] = "wtm_staging",
  ["wtm-stable"] = "wtm_stable",
}?[get_cur_circuit_name()]
let tag = {
  ["wtm-production"] = "production",
  ["wtm-staging"] = "staging",
  ["wtm-stable"] = "stable",
}?[get_cur_circuit_name()]


let actualGameVersion = mkHardWatched("actualGameVersion.value")
let nextRequestTime = mkHardWatched("actualGameVersion.nextTime")
let needRequest = Watched(nextRequestTime.value <= get_time_msec())
let allowRequest = Computed(@() needRequest.value && !isInBattle.value && !isInLoadingScreen.value)

needRequest.subscribe(@(v) v ? null
  : nextRequestTime(get_time_msec() + REQUEST_PERIOD_MSEC))

let updateGameVersionImpl = proj == null ? @() null
  : @() request({
      method = "GET"
      url = $"https://gdn.gaijin.net/apk/version?proj={proj}&tag={tag}"
      respEventId = ACTUAL_VERSION_ID
    })

let function updateGameVersion() {
  if (!allowRequest.value)
    return
  needRequest(false)
  updateGameVersionImpl()
}

subscribe(ACTUAL_VERSION_ID, function(response) {
  let { status = -1, http_code = -1, body = null } = response
  let hasError = status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code
  if (hasError)
    return
  local result = null
  try {
    result = body != null ? parse_json(body.as_string()) : null
  }
  catch(e) {}
  if (result?.status == "OK")
    actualGameVersion(result?.version)
})

if (allowRequest.value)
  deferOnce(updateGameVersion)
allowRequest.subscribe(@(v) v ? deferOnce(updateGameVersion) : null)

let needRequestOn = @() needRequest(true)
let function startTimer() {
  if (!needRequest.value)
    resetTimeout(max(0.1, 0.001 * (nextRequestTime.value - get_time_msec())), needRequestOn)
}
startTimer()
nextRequestTime.subscribe(@(_) startTimer())

return actualGameVersion