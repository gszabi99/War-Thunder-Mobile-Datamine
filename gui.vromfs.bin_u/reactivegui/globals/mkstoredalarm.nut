from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { resetTimeout } = require("dagor.workcycle")
let { get_local_custom_settings_blk } = require("blkGetters")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")

return function mkStoredAlarm(persistId, period = 604800 ) {
  let isTimerPassed = Watched(false)
  let lastTime = Watched(-1)
  let setTimerPassed = @() isTimerPassed.set(true)
  let storeId = $"{persistId}Time"

  lastTime.subscribe(function(value) {
    if (serverTime.get() > value + period)
      setTimerPassed()
    else
      resetTimeout(value + period - serverTime.get(), setTimerPassed)
  })

  let loadStoredTime = @() lastTime.set(get_local_custom_settings_blk()?[storeId] ?? 0)

  function setLastTime(time) {
    isTimerPassed.set(false)
    lastTime.set(time)
    get_local_custom_settings_blk()[storeId] = lastTime.get()
    eventbus_send("saveProfile", {})
  }

  if (isOnlineSettingsAvailable.get())
    loadStoredTime()
  isOnlineSettingsAvailable.subscribe(@(v) v ? loadStoredTime() : null)

  return {
    isTimerPassed
    setLastTime
  }
}


