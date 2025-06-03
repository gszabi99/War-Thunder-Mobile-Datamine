from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/clientState/connectionStatus.nut" import *
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { is_android } = require("%sqstd/platform.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { get_connection_status, CONN_LIMITED, CONN_OK, CONN_NO_CONNECTION, CONN_UNKNOWN
} = is_android ? require("android.updater")
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

let debugStatus = hardPersistWatched("connectionStatus.debugStatus", null)
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
  debugStatus(status == connectionStatusAndRaw.get() ? null : status)
  eventbus_send("android.network.onConnectionStatusChange", { status })
  console_print($"Connection status changed to {connectionStatusMap[status]}") 
}, "debug.ui.connectionStatusToggle")
