from "%globalsDarg/darg_library.nut" import *
let { check_purchases } = require("%appGlobals/pServer/pServerApi.nut")
let menuAutoRefreshTimer = require("%appGlobals/menuAutoRefreshTimer.nut")

let { refreshOnWindowActivate, refreshIfWindowActive } = menuAutoRefreshTimer({
  refresh = check_purchases
  refreshDelaySec = 30.0
})

return {
  severalCheckPurchasesOnActivate = @() refreshOnWindowActivate(6, 10.0)
  startSeveralCheckPurchases      = @() refreshIfWindowActive(6, 10.0)
}