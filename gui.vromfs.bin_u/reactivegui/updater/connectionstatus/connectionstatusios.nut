from "%globalsDarg/darg_library.nut" import *
from "connectionStatusConsts.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { getConnectionStatus, CONN_LIMITED, CONN_WIFI, CONN_NO_CONNECTION, CONN_UNKNOWN } = require("ios.platform")

let connectionStatusMap = {
  [CONN_LIMITED] = CON_LIMITED,
  [CONN_WIFI] = CON_OK,
  [CONN_NO_CONNECTION] = CON_NO_CONNECTION,
  [CONN_UNKNOWN] = CON_UNKNOWN,
}

let connectionStatusIos = Watched(getConnectionStatus())
let connectionStatus = Computed(@() connectionStatusMap?[connectionStatusIos.value] ?? CON_UNKNOWN)

eventbus_subscribe("ios.network.onConnectionStatusChange", @(msg) connectionStatusIos(msg.status))

return {
  connectionStatus
}