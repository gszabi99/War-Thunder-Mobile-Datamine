from "%globalsDarg/darg_library.nut" import *
let { isReadyToFullLoad, isLoginRequired } = require("%appGlobals/loginState.nut")

if (!isReadyToFullLoad.get() && isLoginRequired.get())
  logerr("Load script not allowed before login")
