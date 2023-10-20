from "%scripts/dagui_library.nut" import *

//Load main scripts
require("%scripts/main.nut")

let { isLoginRequired } = require("%appGlobals/loginState.nut")
isLoginRequired(false) //load scripts after login
