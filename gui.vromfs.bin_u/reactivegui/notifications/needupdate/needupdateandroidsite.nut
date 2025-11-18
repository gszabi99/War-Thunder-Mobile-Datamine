from "%globalsDarg/darg_library.nut" import *
let logUpdate = log_with_prefix("[UPDATE]: ")
let { eventbus_subscribe } = require("eventbus")
let { httpRequest, HTTP_SUCCESS } = require("dagor.http")
let { parse_json } = require("json")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { get_cur_circuit_name } = require("app")
let { get_all_library_versions } = require("contentUpdater")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInBattle, isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { check_version } = require("%sqstd/version_compare.nut")

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


let actualGameVersion = hardPersistWatched("actualGameVersion.get()")
let actualGameHash = hardPersistWatched("actualGameVersion.hash")
let nextRequestTime = hardPersistWatched("actualGameVersion.nextTime")
let needRequest = Watched(nextRequestTime.get() <= get_time_msec())
let allowRequest = Computed(@() needRequest.get() && !isInBattle.get() && !isInLoadingScreen.get())

needRequest.subscribe(@(v) v ? null
  : nextRequestTime.set(get_time_msec() + REQUEST_PERIOD_MSEC))

let getApkLinkWithHash = @(gameHash) $"https://gdn.gaijin.net/apk/download?proj={proj}&tag={tag}&hash={gameHash}"

let updateGameVersionImpl = proj == null ? @() null
  : @() httpRequest({
      method = "GET"
      url = $"https://gdn.gaijin.net/apk/version?proj={proj}&tag={tag}"
      respEventId = ACTUAL_VERSION_ID
    })

function updateGameVersion() {
  if (!allowRequest.get())
    return
  needRequest.set(false)
  logUpdate("request")
  updateGameVersionImpl()
}

eventbus_subscribe(ACTUAL_VERSION_ID, function(response) {
  let { status = -1, http_code = -1, body = null } = response
  let hasError = status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code
  if (hasError)
    return
  local result = null
  try {
    result = body != null ? parse_json(body.as_string()) : null
  }
  catch(e) {}
  if (result?.status == "OK") {
    actualGameVersion.set(result?.version)
    actualGameHash.set(result?.hash)
  }
  logUpdate($"status = {status}, version = {result?.version}")
})

if (allowRequest.get())
  deferOnce(updateGameVersion)
allowRequest.subscribe(@(v) v ? deferOnce(updateGameVersion) : null)

let needRequestOn = @() needRequest.set(true)
function startTimer() {
  if (!needRequest.get())
    resetTimeout(max(0.1, 0.001 * (nextRequestTime.get() - get_time_msec())), needRequestOn)
}
startTimer()
nextRequestTime.subscribe(@(_) startTimer())

let needSuggestToUpdate = Computed(function() {
  local actualVersion = actualGameVersion.get() ?? ""
  if (actualVersion == "")
    return false
  let all = get_all_library_versions()
  return all.len() != 0 && null == all.findvalue(@(v) check_version($">={actualVersion}", v))
})

return {
  actualGameVersion
  actualGameHash
  getApkLinkWithHash
  needSuggestToUpdate
}