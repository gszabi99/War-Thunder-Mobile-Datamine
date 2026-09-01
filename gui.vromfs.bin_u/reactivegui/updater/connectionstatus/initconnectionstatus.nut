from "%globalsDarg/darg_library.nut" import *
from "%sqstd/platform.nut" import is_ios
from "%appGlobals/clientState/connectionStatus.nut" import connectionStatus
import "%rGui/isFirstLoad.nut" as isFirstLoad


if (is_ios)
  require("%rGui/updater/connectionStatus/connectionStatusIos.nut")
else
  require("%rGui/updater/connectionStatus/connectionStatusAndroid.nut") 

if (isFirstLoad)
  log($"Connection status on init: {connectionStatus.get()}")

connectionStatus.subscribe(@(s) log($"Connection status changed to: {s}"))
