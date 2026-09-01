from "frp" import Computed
from "%sqstd/globalState.nut" import hardPersistWatched


const CON_UNKNOWN = "unknown"
const CON_LIMITED = "limited"
const CON_OK = "ok"
const CON_NO_CONNECTION = "no connection"
let connectionStatus = hardPersistWatched("connectionStatus", CON_UNKNOWN)

return {
  CON_LIMITED
  CON_OK
  CON_NO_CONNECTION
  CON_UNKNOWN

  connectionStatus
  isConnectionLimited = Computed(@() connectionStatus.get() == CON_LIMITED)
  hasConnection = Computed(@() connectionStatus.get() != CON_NO_CONNECTION)
}