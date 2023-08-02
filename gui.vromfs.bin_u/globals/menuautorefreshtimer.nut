
let { get_time_msec } = require("dagor.time")
let { setTimeout } = require("dagor.workcycle")
let { kwarg } = require("%sqstd/functools.nut")
let { windowActive } = require("%globalScripts/windowState.nut")
let { isLoggedIn } = require("loginState.nut")
let { isInBattle } = require("clientState/clientState.nut")

//call refresh function after each windowActivate
//function will be called only when logged in and not in battle
let function menuAutoRefreshTimer(
  refresh, //function to call
  refreshDelaySec = 30 //minimum timeout after refresh to ignore window activate
) {
  local readyRefreshTime = 0
  local timeLeftToUpdate = 0
  local refreshPeriod = 10.0

  local startAutoRefreshTimer = null

  let function autoRefreshImpl() {
    if (!isLoggedIn.value || isInBattle.value)
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
      if (windowActive.value)
        autoRefreshImpl()
    })
  }


  let function windowStateHandler(isActive) {
    if (isActive && (readyRefreshTime <= get_time_msec()))
      autoRefreshImpl()
  }

  windowActive.subscribe(windowStateHandler)

  return {
    function refreshOnWindowActivate(repeatAmount = 1, refreshPeriodSec = 10.0) { //repeat several calls by timeout after window activate
      readyRefreshTime = 0
      timeLeftToUpdate = repeatAmount
      refreshPeriod = refreshPeriodSec
    }
    function refreshIfWindowActive(repeatAmount = 1, refreshPeriodSec = 10.0) { //repeat several calls by timeout without wait if window active
      readyRefreshTime = 0
      timeLeftToUpdate = repeatAmount
      refreshPeriod = refreshPeriodSec
      if (windowActive.value)
        windowStateHandler(true)
    }
  }
}

return kwarg(menuAutoRefreshTimer)