from "%scripts/dagui_library.nut" import *
let logQ = log_with_prefix("[QUEUE] ")
let { get_time_msec } = require("dagor.time")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { SERVER_ERROR_REQUEST_REJECTED, SERVER_ERROR_NOT_IN_QUEUE } = require("matching.errors")
let { isEqual } = require("%sqstd/underscore.nut")
let queueState = require("%appGlobals/queueState.nut")
let { curQueue, isInQueue, curQueueState, queueStates,
  QS_ACTUALIZE, QS_ACTUALIZE_SQUAD, QS_JOINING, QS_IN_QUEUE, QS_LEAVING, QS_CHECK_PENALTY
} = queueState
let { TEAM_ANY } = require("%appGlobals/teams.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { selClusters } = require("clustersList.nut")
let { getOptimalClustersForSquad } = require("optimalClusters.nut")
let { queueData, isQueueDataActual, actualizeQueueData, curUnitInfo
} = require("%scripts/battleData/queueData.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let showMatchingError = require("showMatchingError.nut")
let { isMatchingConnected } = require("%appGlobals/loginState.nut")
let { registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { isInSquad, squadMembers, isSquadLeader, squadLeaderCampaign, queueDataCheckTime
} = require("%appGlobals/squadState.nut")
let { decodeJwtAndHandleErrors } = require("%appGlobals/pServer/pServerJwt.nut")
let { campProfile } = require("%appGlobals/pServer/campaign.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let matching = require("%appGlobals/matching_api.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { get_gui_option, addUserOption } = require("guiOptions")


let isSquadActualizeSend = mkWatched(persist, "isSquadActualizeSend", false)
let USEROPT_ALLOW_JIP = addUserOption("USEROPT_ALLOW_JIP")

isInQueue.subscribe(@(_) isSquadActualizeSend(false))
curQueueState.subscribe(@(v) logQ($"Queue state changed to: {queueStates.findindex(@(s) s == v)}"))

let setQueueState = @(state) curQueue.mutate(@(q) q.state = state)
let destroyQueue = @() curQueue(null)

let writeJwtData = @() curQueue.mutate(function(q) {
  let { payload = {}, jwt = "" } = queueData.value
  let myParams = { profileJwt = jwt }

  q.state = QS_ACTUALIZE_SQUAD
  q.params = q.params.__merge({
    players = { [myUserId.value.tostring()] = myParams }
  })
  q.unitInfo <- queueData.value?.unitInfo
  logQ($"Queue ", q.unitInfo, " params by token: ", payload)
})

let hasPenaltyNonUpdatable = @() (campProfile.get()?.penalties.penaltyEndTime ?? 0) > serverTime.get()

function actualizeSquadQueueOnce() {
  if (isSquadActualizeSend.value)
    return
  isSquadActualizeSend(true)
  queueDataCheckTime(serverTime.value)
}

function tryWriteMembersData() {
  let playersUpd = {}
  let campaign = squadLeaderCampaign.value
  foreach(uid, m in squadMembers.value) {
    if (uid == myUserId.value)
      continue
    let { queueToken = "", units = {} } = m
    if (queueToken == "") {
      logQ($"Squad member {uid} has invalid queue token. wait for validation.")
      actualizeSquadQueueOnce()
      return
    }
    let { payload = null } = decodeJwtAndHandleErrors(queueToken)
    if (payload == null) {
      logQ($"Squad member {uid} has invalid queue token. wait for validation.")
      actualizeSquadQueueOnce()
      return
    }
    let isSlots = (serverConfigs.get()?.campaignCfg[campaign].totalSlots ?? 0) > 0
    local unitInfo = units?[campaign]
    let tokenUnitInfo = isSlots ? payload?.crafts_info.map(@(u) u.name)
      : [payload?.crafts_info[0].name]

    if (!isEqual(unitInfo, tokenUnitInfo)) {
      logQ($"Squad member {uid} token unit ", tokenUnitInfo, " not same with unit ", unitInfo, ". wait for validation.")
      actualizeSquadQueueOnce()
      return
    }

    if ((payload?.penaltyEndTime ?? 0) > serverTime.get()) {
      openFMsgBox({ text = loc("multiplayer/queuePenaltySquad") })
      curQueue.set(null)
      return
    }
    playersUpd[uid.tostring()] <- { profileJwt = queueToken }
  }

  curQueue.mutate(function(q) {
    q.params.players = q.params.players.__merge(playersUpd)
    q.state = QS_JOINING
    logQ($"Add {playersUpd.len()} squad members to queue state")
  })
}

registerHandler("onActiveQueueActualizeData",
  function(res) {
    if (("error" in res) && curQueueState.value == QS_ACTUALIZE)
      curQueue(null)
  })

let queueSteps = {
  [QS_ACTUALIZE] = function() {
    if (isQueueDataActual.get())
      setQueueState(QS_CHECK_PENALTY)
    else
      actualizeQueueData("onActiveQueueActualizeData")
  },

  [QS_CHECK_PENALTY] = function() {
    if (hasPenaltyNonUpdatable())
      curQueue.set(null)
    else
      writeJwtData()
  },

  [QS_ACTUALIZE_SQUAD] = function() {
    if (!isInSquad.value)
      setQueueState(QS_JOINING)
    else
      tryWriteMembersData()
  },

  [QS_JOINING] = @() matching.rpc_call("match.enqueue",
    curQueue.value.params,
    function(response) {
      if (!isInQueue.value)
        return
      if (showMatchingError(response))
        curQueue(null)
      else
        setQueueState(QS_IN_QUEUE)
    }),

  [QS_IN_QUEUE] = @() curQueue.mutate(@(q) q.activateTime <- get_time_msec()),

  [QS_LEAVING] = @() matching.rpc_call("match.leave_queue",
    {},
    function(response) {
      if (!isInQueue.value)
        return
      let errorId = response?.error
      if (errorId == SERVER_ERROR_REQUEST_REJECTED)
        eventbus_send("setWaitForQueueRoom", true)
      else if (errorId != SERVER_ERROR_NOT_IN_QUEUE)
        showMatchingError(response)
      destroyQueue()
    }),
}

let doStepAction = @() queueSteps?[curQueueState.value]()
let doStepActionDelayed = @() deferOnce(doStepAction)
doStepActionDelayed()

curQueueState.subscribe(@(_) doStepActionDelayed())

let leaveQueue = @() isInQueue.value ? setQueueState(QS_LEAVING) : null

isQueueDataActual.subscribe(function(v) {
  if (!v)
    return
  if (curQueueState.get() == QS_ACTUALIZE)
    setQueueState(QS_CHECK_PENALTY)
  else if (curQueueState.get() == QS_CHECK_PENALTY)
    writeJwtData()
})

curUnitInfo.subscribe(function(_) {  
  if (!isInQueue.value)
    return
  logQ("Leave queue by curUnitInfo change")
  leaveQueue()
})

squadMembers.subscribe(function(v) {
  if (!isInQueue.value || !isSquadLeader.value)
    return

  foreach(uid, m in squadMembers.value)
    if (uid != myUserId.value && !m?.ready) {
      logQ("Leave queue because member become not ready")
      leaveQueue()
      return
    }

  if (curQueueState.value != QS_ACTUALIZE_SQUAD)
    return
  if (v.len() <= 1) 
    leaveQueue()
  else
    tryWriteMembersData()
})

function joinQueue(params) {
  if (isInQueue.value) {
    logerr("Try to join new queue while in queue")
    return
  }
  let paramsExt = {
    clusters = getOptimalClustersForSquad(squadMembers.value) ?? selClusters.value
    team = TEAM_ANY
    jip = get_gui_option(USEROPT_ALLOW_JIP) ?? true
  }.__update(params)
  logQ("Request join queue: ", paramsExt)
  curQueue({ state = QS_ACTUALIZE, params = paramsExt })
}

matching.subscribe("match.notify_queue_join", function(params) {
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

matching.subscribe("match.notify_queue_leave", function(params) {
  logQ("match.notify_queue_leave ", params)
  if (!isInQueue.get() || curQueue.get() == null)
    return
  let cluster = params?.cluster
  if (cluster == null) { 
    destroyQueue()
    return
  }

  if (curQueue.value.params?.mode != params?.mode)
    return

  let { joinedClusters = {} } = curQueue.value
  if (joinedClusters.len() == 0 && curQueue.value.params?.cluster == cluster) {
    destroyQueue()
    return
  }
  if (cluster not in joinedClusters)
    return
  if (joinedClusters.len() == 1)
    destroyQueue() 
  else
    curQueue.mutate(function(v) {
      let newClusters = clone joinedClusters
      newClusters.$rawdelete(cluster)
      v.joinedClusters = newClusters
    })
})

eventbus_subscribe("leaveQueue", @(_) leaveQueue())

isMatchingConnected.subscribe(@(_) destroyQueue())

return queueState.__merge({
  joinQueue
  leaveQueue
  destroyQueue
})