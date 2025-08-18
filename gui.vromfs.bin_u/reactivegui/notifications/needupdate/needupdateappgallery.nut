from "%globalsDarg/darg_library.nut" import *
let logUpdate = log_with_prefix("[UPDATE] AppGallery: ")
let { eventbus_subscribe } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { checkAppUpdateOnMarket } = require("android.platform")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInBattle, isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")

const REQUEST_PERIOD_MSEC = 1800000
let needSuggestToUpdate = hardPersistWatched("huawei.needSuggestToUpdate")
let nextRequestTime = hardPersistWatched("huawei.needSuggestToUpdate.nextTime")
let needRequest = Watched(nextRequestTime.get() <= get_time_msec())
let allowRequest = Computed(@() needRequest.get() && !isInBattle.get() && !isInLoadingScreen.get())

needRequest.subscribe(@(v) v ? null
  : nextRequestTime(get_time_msec() + REQUEST_PERIOD_MSEC))

function requestNeedUpdate() {
  if (!allowRequest.get())
    return
  needRequest.set(false)
  logUpdate("request")
  checkAppUpdateOnMarket()
}

eventbus_subscribe("android.platform.onUpdateCheck", function(response) {
  let { status = false } = response
  logUpdate($"status = {status}")
  needSuggestToUpdate.update(status)
})

if (allowRequest.get())
  deferOnce(requestNeedUpdate)
allowRequest.subscribe(@(v) v ? deferOnce(requestNeedUpdate) : null)

let needRequestOn = @() needRequest.set(true)
function startTimer() {
  if (!needRequest.get())
    resetTimeout(max(0.1, 0.001 * (nextRequestTime.get() - get_time_msec())), needRequestOn)
}
startTimer()
nextRequestTime.subscribe(@(_) startTimer())

return {
  needSuggestToUpdate
}