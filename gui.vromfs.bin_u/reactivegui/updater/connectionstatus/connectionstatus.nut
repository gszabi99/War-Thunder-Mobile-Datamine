from "%globalsDarg/darg_library.nut" import *
from "connectionStatusConsts.nut" import *
let { is_ios } = require("%sqstd/platform.nut")
let { connectionStatus } = is_ios
  ? require("connectionStatusIos.nut")
  : require("connectionStatusAndroid.nut") //for not android there will be dbg_mode

connectionStatus.subscribe(@(s) log($"Connection status changed to: {s}"))

return {
  connectionStatus
  isConnectionLimited = Computed(@() connectionStatus.value == CON_LIMITED)
  hasConnection = Computed(@() connectionStatus.value != CON_NO_CONNECTION)
}