//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { get_time_msec } = require("dagor.time")
let logQ = log_with_prefix("[QUEUE] ")
let { subscribe } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let queueState = require("%appGlobals/queueState.nut")
let { curQueue, isInQueue, curQueueState, queueStates,
  QS_ACTUALIZE, QS_JOINING, QS_IN_QUEUE, QS_LEAVING
} = queueState
let { TEAM_ANY } = require("%appGlobals/teams.nut")
let { selClusters } = require("clustersList.nut")
let { queueData, isQueueDataActual, actualizeQueueData } = require("%scripts/battleData/queueData.nut")
let { actualizeBattleData } = require("%scripts/battleData/menuBattleData.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let showMatchingError = require("showMatchingError.nut")
let { isMatchingConnected } = require("%appGlobals/loginState.nut")
let { registerHandler } = require("%appGlobals/pServer/pServerApi.nut")


curQueueState.subscribe(@(v) logQ($"Queue state changed to: {queueStates.findindex(@(s) s == v)}"))

let setQueueState = @(state) curQueue.mutate(@(q) q.state = state)
let destroyQueue = @() curQueue(null)

let writeJwtData = @() curQueue.mutate(function(q) {
  let { payload = {}, jwt = "" } = queueData.value
  let myParams = { profileJwt = jwt }

  q.state = QS_JOINING
  q.params = q.params.__merge({
    players = { [myUserId.value.tostring()] = myParams }
  })
  q.unitName <- queueData.value?.unitName
  logQ($"Queue {q.unitName} params by token: ", payload)
})

registerHandler("onActiveQueueActualizeData",
  function(res) {
    if (("error" in res) && curQueueState.value == QS_ACTUALIZE)
      curQueue(null)
  })

let queueSteps = {
  [QS_ACTUALIZE] = function() {
    if (isQueueDataActual.value)
      writeJwtData()
    else
      actualizeQueueData("onActiveQueueActualizeData")
  },

  [QS_JOINING] = @() ::matching.rpc_call("match.enqueue",
    curQueue.value.params,
    function(response) {
      if (!isInQueue.value)
        return
      if (showMatchingError(response))
        curQueue(null)
      else
        setQueueState(QS_IN_QUEUE)
    }),

  [QS_IN_QUEUE] = function() {
    curQueue.mutate(@(q) q.activateTime <- get_time_msec())
    actualizeBattleData(curQueue.value?.unitName)
  },

  [QS_LEAVING] = @() ::matching.rpc_call("match.leave_queue",
    {},
    function(response) {
      if (!isInQueue.value)
        return
      let errorId = response?.error
      if (errorId == SERVER_ERROR_REQUEST_REJECTED)
        ::SessionLobby.setWaitForQueueRoom(true)
      else if (errorId != SERVER_ERROR_NOT_IN_QUEUE)
        showMatchingError(response)
      destroyQueue()
    }),
}

let doStepAction = @() queueSteps?[curQueueState.value]()
let doStepActionDelayed = @() deferOnce(doStepAction)
doStepActionDelayed()

curQueueState.subscribe(@(_) doStepActionDelayed())

isQueueDataActual.subscribe(function(v) {
  if (v && curQueueState.value == QS_ACTUALIZE)
    writeJwtData()
})

let function joinQueue(params) {
  if (isInQueue.value) {
    logerr("Try to join new queue while in queue")
    return
  }
  let paramsExt = {
    clusters = selClusters.value
    team = TEAM_ANY
    jip = true
  }.__update(params)
  logQ("Request join queue: ", paramsExt)
  curQueue({ state = QS_ACTUALIZE, params = paramsExt })
}

let leaveQueue = @() isInQueue.value ? setQueueState(QS_LEAVING) : null

::matching.subscribe("match.notify_queue_join", function(params) {
  logQ("match.notify_queue_join ", params)
  if (!isInQueue.value) {
    curQueue({ state = QS_IN_QUEUE, params })
    return
  }
  if (curQueue.value.params?.mode != params?.mode)
    return
  curQueue.mutate(@(v) v.__update({
    state = QS_IN_QUEUE,
    joinedClusters = (v?.joinedClusters ?? {}).__merge({ [params?.cluster ?? ""] = true })
  }))
})

::matching.subscribe("match.notify_queue_leave", function(params) {
  logQ("match.notify_queue_leave ", params)
  if (!isInQueue.value)
    return
  let cluster = params?.cluster
  if (cluster == null) { //leave all
    destroyQueue()
    return
  }
  if (curQueue.value.params?.mode != params?.mode)
    return
  let joinedClusters = clone (curQueue.value?.joinedClusters ?? {})
  if (cluster not in joinedClusters)
    return
  delete joinedClusters[cluster]
  if (joinedClusters.len() == 0)
    destroyQueue() //last cluster leave
  else
    curQueue.mutate(@(v) v.joinedClusters = joinedClusters) //remove single cluster
})

subscribe("leaveQueue", @(_) leaveQueue())

isMatchingConnected.subscribe(@(_) destroyQueue())

return queueState.__merge({
  joinQueue
  leaveQueue
  destroyQueue
})