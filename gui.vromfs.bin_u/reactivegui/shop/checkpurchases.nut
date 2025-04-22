from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { check_purchases } = require("%appGlobals/pServer/pServerApi.nut")
let menuAutoRefreshTimer = require("%appGlobals/menuAutoRefreshTimer.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let { refreshOnWindowActivate, refreshIfWindowActive } = menuAutoRefreshTimer({
  refresh = check_purchases
  refreshDelaySec = 30.0
})

local loginTime = 0
isLoggedIn.subscribe(function(v) {
  loginTime = v ? get_time_msec() : 0
})
eventbus_subscribe("onMatchingOnlineAvailable", function(_) {
  if (isLoggedIn.get() && loginTime + 1000 < get_time_msec()) 
    check_purchases()
})

return {
  severalCheckPurchasesOnActivate = @() refreshOnWindowActivate(6, 10.0)
  startSeveralCheckPurchases      = @() refreshIfWindowActive(6, 10.0)
}