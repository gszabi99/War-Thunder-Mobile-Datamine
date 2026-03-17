from "%globalScripts/logs.nut" import *
from "dagor.time" import get_time_msec
from "%appGlobals/windowState.nut" import windowActive
let { resetTimeout, clearTimer, hasTimer = @(_) true, deferOnce } = require("dagor.workcycle")

let CLEAR_AFTER_COUNT = 20

let timers = {}
local resetCount = 0

function clearTimers() {
  let toRemove = []
  foreach (a, _ in timers)
    if (!hasTimer(a))
      toRemove.append(a)
  foreach (a in toRemove)
    timers.$rawdelete(a)
  resetCount = 0
}

function restartAll() {
  let curTime = get_time_msec()
  let toRemove = []
  foreach (a, t in timers)
    if (!hasTimer(a))
      toRemove.append(a)
    else if (t <= curTime) {
      deferOnce(a)
      toRemove.append(a)
    }
    else
      resetTimeout(0.001 * (t - curTime), a)

  foreach (a in toRemove)
    timers.$rawdelete(a)
  resetCount = 0
}

function resetExtTimeout(time, action) {
  if (resetCount++ >= CLEAR_AFTER_COUNT)
    clearTimers()
  resetTimeout(time, action)
  timers[action] <- get_time_msec() + (1000 * time).tointeger()
}

function clearExtTimer(action) {
  clearTimer(action)
  timers.$rawdelete(action)
}

windowActive.subscribe(function(v) {
  if (v)
    restartAll()
})

return {
  resetExtTimeout
  clearExtTimer
}