from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/loginState.nut" import isReadyToFullLoad, isLoginRequired


if (!isReadyToFullLoad.get() && isLoginRequired.get() && !__static_analysis__)
  logerr("Load script not allowed before login")
