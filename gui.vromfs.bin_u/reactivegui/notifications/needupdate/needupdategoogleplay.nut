from "%globalsDarg/darg_library.nut" import *
let logUpdate = log_with_prefix("[UPDATE] googlePlay: ")
let { subscribe } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { checkGooglePlayUpdate } = require("android.platform")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInBattle, isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")


const REQUEST_PERIOD_MSEC = 1800000
let needSuggestToUpdate = hardPersistWatched("googlePlay.needSuggestToUpdate")
let nextRequestTime = hardPersistWatched("needSuggestToUpdate.nextTime")
let needRequest = Watched(nextRequestTime.value <= get_time_msec())
let allowRequest = Computed(@() needRequest.value && !isInBattle.value && !isInLoadingScreen.value)

needRequest.subscribe(@(v) v ? null
  : nextRequestTime(get_time_msec() + REQUEST_PERIOD_MSEC))

let function requestNeedUpdate() {
  if (!allowRequest.value)
    return
  needRequest(false)
  logUpdate("request")
  checkGooglePlayUpdate()
}

subscribe("android.platform.onUpdateCheck", function(response) {
  let { status = false } = response
  logUpdate($"status = {status}")
  needSuggestToUpdate.update(status)
})

if (allowRequest.value)
  deferOnce(requestNeedUpdate)
allowRequest.subscribe(@(v) v ? deferOnce(requestNeedUpdate) : null)

let needRequestOn = @() needRequest(true)
let function startTimer() {
  if (!needRequest.value)
    resetTimeout(max(0.1, 0.001 * (nextRequestTime.value - get_time_msec())), needRequestOn)
}
startTimer()
nextRequestTime.subscribe(@(_) startTimer())

return {
  needSuggestToUpdate
}