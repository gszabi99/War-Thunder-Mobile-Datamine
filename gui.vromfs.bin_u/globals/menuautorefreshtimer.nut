from "dagor.time" import get_time_msec
from "dagor.workcycle" import setTimeout
from "math" import max
from "%sqstd/functools.nut" import kwarg
from "%appGlobals/windowState.nut" import windowActive
from "clientState/clientState.nut" import isInBattle
from "loginState.nut" import isLoggedIn




function menuAutoRefreshTimer(
  refresh, 
  refreshDelaySec = 30 
) {
  local readyRefreshTime = 0
  local timeLeftToUpdate = 0
  local refreshPeriod = 10.0

  local startAutoRefreshTimer = null

  function autoRefreshImpl() {
    if (!isLoggedIn.get() || isInBattle.get())
      return

    readyRefreshTime = get_time_msec() + (1000 * refreshDelaySec).tointeger()
    refresh()

    timeLeftToUpdate = max(0, timeLeftToUpdate - 1)
    if (timeLeftToUpdate > 0)
      startAutoRefreshTimer()
  }

  local isAutorefreshTimerStarted = false
  startAutoRefreshTimer = function() {
    if (isAutorefreshTimerStarted)
      return
    isAutorefreshTimerStarted = true
    setTimeout(refreshPeriod, function() {
      isAutorefreshTimerStarted = false
      readyRefreshTime = 0
      if (windowActive.get())
        autoRefreshImpl()
    })
  }


  function windowStateHandler(isActive) {
    if (isActive && (readyRefreshTime <= get_time_msec()))
      autoRefreshImpl()
  }

  windowActive.subscribe(windowStateHandler)

  return {
    function refreshOnWindowActivate(repeatAmount = 1, refreshPeriodSec = 10.0) { 
      readyRefreshTime = 0
      timeLeftToUpdate = repeatAmount
      refreshPeriod = refreshPeriodSec
    }
    function refreshIfWindowActive(repeatAmount = 1, refreshPeriodSec = 10.0) { 
      readyRefreshTime = 0
      timeLeftToUpdate = repeatAmount
      refreshPeriod = refreshPeriodSec
      if (windowActive.get())
        windowStateHandler(true)
    }
  }
}

return kwarg(menuAutoRefreshTimer)