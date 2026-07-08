
let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

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

let curQueue = sharedWatched("curQueue", @() null)
let queueInfo = sharedWatched("queueInfo", @() null)
let curQueueState = Computed(@() curQueue.get()?.state ?? QS_NOT_IN_QUEUE)
let myQueueToken = sharedWatched("myQueueToken", @() "")
let jwtUserstat = sharedWatched("jwtUserstat", @() "")

return queueStates.__merge({
  queueStates
  curQueue
  queueInfo
  curQueueState
  isInQueue = Computed(@() curQueueState.get() != QS_NOT_IN_QUEUE)
  myQueueToken
  jwtUserstat
})
