from "%appGlobals/clientState/connectionStatus.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "eventbus" import eventbus_subscribe, eventbus_send
import "ios.platform" as iosModule
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/platform.nut" import is_ios


let { CONN_LIMITED, CONN_WIFI, CONN_NO_CONNECTION, CONN_UNKNOWN } = iosModule
let { getConnectionStatus } = is_ios ? iosModule
  : { getConnectionStatus = @() CONN_WIFI }

let connectionStatusMap = {
  [CONN_LIMITED] = CON_LIMITED,
  [CONN_WIFI] = CON_OK,
  [CONN_NO_CONNECTION] = CON_NO_CONNECTION,
  [CONN_UNKNOWN] = CON_UNKNOWN,
}

let debugStatus = hardPersistWatched("connectionStatusIos.debugStatus", null)
let connectionStatusIosRaw = Watched(getConnectionStatus())
let connectionStatusIos = Computed(@() debugStatus.get() ?? connectionStatusIosRaw.get())
let updateStatus = @() connectionStatus.set(connectionStatusMap?[connectionStatusIos.get()] ?? CON_UNKNOWN)
updateStatus()
connectionStatusIos.subscribe(@(_) updateStatus())

eventbus_subscribe("ios.network.onConnectionStatusChange", @(msg) connectionStatusIosRaw.set(msg.status))

register_command(function() {
  local status = connectionStatusIos.get() + 1
  if (status > CONN_WIFI)
    status = CONN_NO_CONNECTION
  debugStatus.set(status == connectionStatusIosRaw.get() ? null : status)
  eventbus_send("ios.network.onConnectionStatusChange", { status })
  console_print($"Connection status changed to {connectionStatusMap[status]}") 
}, "debug.ui.connectionStatusToggle")
