from "%globalsDarg/darg_library.nut" import *
from "connectionStatusConsts.nut" import *
let { subscribe, send } = require("eventbus")
let { register_command } = require("console")
let { is_android } = require("%sqstd/platform.nut")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")

let debugStatus = mkHardWatched("connectionStatus.debugStatus", 0)
let { get_connection_status, CONN_LIMITED, CONN_OK, CONN_NO_CONNECTION, CONN_UNKNOWN
} = is_android ? require("android.updater")
  : { //debug_mode
      get_connection_status = @() debugStatus.value
      CONN_LIMITED = 1
      CONN_OK = 0
      CONN_NO_CONNECTION = -1
      CONN_UNKNOWN = -2
    }

let connectionStatusMap = {
  [CONN_LIMITED] = CON_LIMITED,
  [CONN_OK] = CON_OK,
  [CONN_NO_CONNECTION] = CON_NO_CONNECTION,
  [CONN_UNKNOWN] = CON_UNKNOWN,
}

let connectionStatusAnd = Watched(get_connection_status())
let connectionStatus = Computed(@() connectionStatusMap?[connectionStatusAnd.value] ?? CONN_UNKNOWN)

subscribe("android.network.onConnectionStatusChange", @(msg) connectionStatusAnd(msg.status))

register_command(function() {
  let status = connectionStatusAnd.value == CONN_OK ? CONN_LIMITED : CONN_OK
  debugStatus(status)
  send("android.network.onConnectionStatusChange", { status })
  console_print($"Connection status changed to {connectionStatusMap[status]}") //warning disable: -forbidden-function
}, "debug.ui.connectionStatusToggle")

return {
  connectionStatus
}