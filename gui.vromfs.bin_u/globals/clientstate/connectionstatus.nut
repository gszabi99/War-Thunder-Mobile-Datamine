let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")


let CON_UNKNOWN = "unknown"
let CON_LIMITED = "limited"
let CON_OK = "ok"
let CON_NO_CONNECTION = "no connection"
let connectionStatus = sharedWatched("connectionStatus", @() CON_UNKNOWN)

return {
  CON_LIMITED
  CON_OK
  CON_NO_CONNECTION
  CON_UNKNOWN

  connectionStatus
  isConnectionLimited = Computed(@() connectionStatus.value == CON_LIMITED)
  hasConnection = Computed(@() connectionStatus.get() != CON_NO_CONNECTION)
}