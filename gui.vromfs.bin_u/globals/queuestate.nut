
let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let queueStates = {
  QS_NOT_IN_QUEUE = 0
  QS_ACTUALIZE = 1
  QS_JOINING = 2
  QS_IN_QUEUE = 3
  QS_LEAVING = 4
}
let { QS_NOT_IN_QUEUE } = queueStates

let curQueue = sharedWatched("curQueue", @() null)
let queueInfo = sharedWatched("queueInfo", @() null)
let curQueueState = Computed(@() curQueue.value?.state ?? QS_NOT_IN_QUEUE)

return queueStates.__merge({
  queueStates
  curQueue
  queueInfo
  curQueueState
  isInQueue = Computed(@() curQueueState.value != QS_NOT_IN_QUEUE)
})
