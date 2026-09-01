from "%appGlobals/clientState/connectionStatus.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "eventbus" import eventbus_subscribe, eventbus_send
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/platform.nut" import is_android


let { get_connection_status, CONN_LIMITED, CONN_OK, CONN_NO_CONNECTION, CONN_UNKNOWN
} = is_android ? require("android.platform")
  : { 
      get_connection_status = @() 0
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

let debugStatus = hardPersistWatched("connectionStatusAndroid.debugStatus", null)
let connectionStatusAndRaw = Watched(get_connection_status())
let connectionStatusAnd = Computed(@() debugStatus.get() ?? connectionStatusAndRaw.get())
let updateStatus = @() connectionStatus.set(connectionStatusMap?[connectionStatusAnd.get()] ?? CON_UNKNOWN)
updateStatus()
connectionStatusAnd.subscribe(@(_) updateStatus())

eventbus_subscribe("android.network.onConnectionStatusChange", @(msg) connectionStatusAndRaw.set(msg.status))

register_command(function() {
  local status = connectionStatusAnd.get() + 1
  if (status > CONN_LIMITED)
    status = CONN_NO_CONNECTION
  debugStatus.set(status == connectionStatusAndRaw.get() ? null : status)
  eventbus_send("android.network.onConnectionStatusChange", { status })
  console_print($"Connection status changed to {connectionStatusMap[status]}") 
}, "debug.ui.connectionStatusToggle")
