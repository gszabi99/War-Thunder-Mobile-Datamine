from "%globalsDarg/darg_library.nut" import *
let isFirstLoad = require("%rGui/isFirstLoad.nut")
let { is_ios } = require("%sqstd/platform.nut")
let { connectionStatus } = require("%appGlobals/clientState/connectionStatus.nut")
if (is_ios)
  require("%rGui/updater/connectionStatus/connectionStatusIos.nut")
else
  require("%rGui/updater/connectionStatus/connectionStatusAndroid.nut") 

if (isFirstLoad)
  log($"Connection status on init: {connectionStatus.get()}")

connectionStatus.subscribe(@(s) log($"Connection status changed to: {s}"))
