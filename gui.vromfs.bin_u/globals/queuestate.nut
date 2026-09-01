from "frp" import Computed
from "%sqstd/globalState.nut" import hardPersistWatched


let queueStates = {
  QS_NOT_IN_QUEUE = 0
  QS_REQUEST_STATS = 1
  QS_ACTUALIZE = 2
  QS_CHECK_PENALTY = 3
  QS_ACTUALIZE_SQUAD = 4
  QS_CHECK_HOSTS = 5
  QS_JOINING = 6
  QS_IN_QUEUE = 7
  QS_LEAVING = 8
}
let { QS_NOT_IN_QUEUE } = queueStates

let curQueue = hardPersistWatched("curQueue", null)
let queueInfo = hardPersistWatched("queueInfo", null)
let curQueueState = Computed(@() curQueue.get()?.state ?? QS_NOT_IN_QUEUE)
let myQueueToken = hardPersistWatched("myQueueToken", "")
let jwtUserstat = hardPersistWatched("jwtUserstat", "")

return queueStates.__merge({
  queueStates
  curQueue
  queueInfo
  curQueueState
  isInQueue = Computed(@() curQueueState.get() != QS_NOT_IN_QUEUE)
  myQueueToken
  jwtUserstat
})
