from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "dagor.workcycle" import deferOnce
from "%appGlobals/loginState.nut" import isLoggedIn, isMatchingOnline
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

function checkPurchasesOnBackOnline() {
  if (isLoggedIn.get() && loginTime + 1000 < get_time_msec()) 
    check_purchases()
}
isMatchingOnline.subscribe(@(v) v ? deferOnce(checkPurchasesOnBackOnline) : null)

return {
  severalCheckPurchasesOnActivate = @() refreshOnWindowActivate(6, 10.0)
  startSeveralCheckPurchases      = @() refreshIfWindowActive(6, 10.0)
}