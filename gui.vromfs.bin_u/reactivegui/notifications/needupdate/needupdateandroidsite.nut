from "%globalsDarg/darg_library.nut" import *
from "app" import get_cur_circuit_name
from "contentUpdater" import get_all_library_versions
from "dagor.http" import httpRequest, HTTP_SUCCESS
from "dagor.time" import get_time_msec
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_subscribe
from "json" import parse_json
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/version_compare.nut" import check_version
from "%appGlobals/clientState/clientState.nut" import isInBattle, isInLoadingScreen
from "%appGlobals/timeoutExt.nut" import resetExtTimeout


let logUpdate = log_with_prefix("[UPDATE]: ")


const REQUEST_PERIOD_MSEC = 1800000
const ACTUAL_VERSION_ID = "actualVersion.response"
let proj = {
  ["wtm-production"] = "wtm_production",
  ["wtm-staging"] = "wtm_staging",
  ["wtm-stable"] = "wtm_stable",
}?[get_cur_circuit_name()]
let apkTag = {
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

let getApkLinkWithHash = @(gameHash) $"https://gdn.gaijin.net/apk/download?proj={proj}&tag={apkTag}&hash={gameHash}"

let updateGameVersionImpl = proj == null ? @() null
  : @() httpRequest({
      method = "GET"
      url = $"https://gdn.gaijin.net/apk/version?proj={proj}&tag={apkTag}"
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
    resetExtTimeout(max(0.1, 0.001 * (nextRequestTime.get() - get_time_msec())), needRequestOn)
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
  apkTag
}