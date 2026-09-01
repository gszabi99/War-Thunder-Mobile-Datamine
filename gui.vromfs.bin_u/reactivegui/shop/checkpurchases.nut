from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "eventbus" import eventbus_subscribe
from "%appGlobals/loginState.nut" import isLoggedIn
import "%appGlobals/menuAutoRefreshTimer.nut" as menuAutoRefreshTimer
from "%appGlobals/pServer/pServerApi.nut" import check_purchases


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