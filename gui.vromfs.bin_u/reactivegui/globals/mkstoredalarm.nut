from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "eventbus" import eventbus_send
from "%appGlobals/loginState.nut" import isOnlineSettingsAvailable
from "%appGlobals/timeoutExt.nut" import resetExtTimeout
from "%appGlobals/userstats/serverTime.nut" import serverTime


return function mkStoredAlarm(persistId, period = 604800 ) {
  let isTimerPassed = Watched(false)
  let lastTime = Watched(-1)
  let setTimerPassed = @() isTimerPassed.set(true)
  let storeId = $"{persistId}Time"

  lastTime.subscribe(function(value) {
    if (serverTime.get() > value + period)
      setTimerPassed()
    else
      resetExtTimeout(value + period - serverTime.get(), setTimerPassed)
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


