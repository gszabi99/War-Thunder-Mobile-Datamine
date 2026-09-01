from "%globalsDarg/darg_library.nut" import *
from "android.platform" import checkAppUpdateOnMarket
from "dagor.time" import get_time_msec
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_subscribe
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/clientState.nut" import isInBattle, isInLoadingScreen
from "%appGlobals/timeoutExt.nut" import resetExtTimeout


let logUpdate = log_with_prefix("[UPDATE]: ")


const REQUEST_PERIOD_MSEC = 1800000
let needSuggestToUpdate = hardPersistWatched("huawei.needSuggestToUpdate")
let nextRequestTime = hardPersistWatched("huawei.needSuggestToUpdate.nextTime")
let needRequest = Watched(nextRequestTime.get() <= get_time_msec())
let allowRequest = Computed(@() needRequest.get() && !isInBattle.get() && !isInLoadingScreen.get())

needRequest.subscribe(@(v) v ? null
  : nextRequestTime.set(get_time_msec() + REQUEST_PERIOD_MSEC))

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
  needSuggestToUpdate.set(status)
})

if (allowRequest.get())
  deferOnce(requestNeedUpdate)
allowRequest.subscribe(@(v) v ? deferOnce(requestNeedUpdate) : null)

let needRequestOn = @() needRequest.set(true)
function startTimer() {
  if (!needRequest.get())
    resetExtTimeout(max(0.1, 0.001 * (nextRequestTime.get() - get_time_msec())), needRequestOn)
}
startTimer()
nextRequestTime.subscribe(@(_) startTimer())

return {
  needSuggestToUpdate
}