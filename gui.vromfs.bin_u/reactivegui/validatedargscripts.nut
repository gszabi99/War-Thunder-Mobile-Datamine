from "%appGlobals/loginState.nut" import isLoginRequired


println("require(\"wtmRGui/main.nut\")")
require("%rGui/main.nut")
isLoginRequired.set(false) 
require("%darg/test_ui.nut").test("%rGui/main.nut")



require("%appGlobals/data/offlineConfigs.nut")
require("%appGlobals/data/offlineProfile.nut")
