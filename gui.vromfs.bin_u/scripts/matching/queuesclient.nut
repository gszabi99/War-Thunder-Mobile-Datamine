from "%scripts/dagui_library.nut" import *
let logQ = log_with_prefix("[QUEUE] ")
let { get_time_msec } = require("dagor.time")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { get_meta_mission_info_by_name } = require("guiMission")
let { SERVER_ERROR_REQUEST_REJECTED, SERVER_ERROR_NOT_IN_QUEUE } = require("matching.errors")
let { isEqual } = require("%sqstd/underscore.nut")
let { can_send_hosts_reachability_to_matching } = require("%appGlobals/permissions.nut")
let queueState = require("%appGlobals/queueState.nut")
let { curQueue, isInQueue, curQueueState, queueStates, jwtUserstat,
  QS_REQUEST_STATS, QS_ACTUALIZE, QS_CHECK_PENALTY, QS_ACTUALIZE_SQUAD, QS_CHECK_HOSTS,
    QS_JOINING, QS_IN_QUEUE, QS_LEAVING
} = queueState
let { TEAM_ANY } = require("%appGlobals/teams.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { allGameModes } = require("%appGlobals/gameModes/gameModes.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { REACHABILITY_CHECK_TIMEOUT_SEC } = require("%appGlobals/clustersState.nut")
let { isHostsReachabilityValid, requestHostsReachability, getClustersAndHostsForQueue
} = require("optimalClusters.nut")
let { queueData, isQueueDataActual, actualizeQueueData, curUnitInfo
} = require("%scripts/battleData/queueData.nut")
let { isStatsActual, actualizeStats, allowSendOldStats, oldStatSendTime
} = require("%scripts/battleData/userstatStats.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let showMatchingError = require("showMatchingError.nut")
let { isMatchingConnected } = require("%appGlobals/loginState.nut")
let { registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { isInSquad, squadMembers, isSquadLeader, squadLeaderCampaign, queueDataCheckTime
} = require("%appGlobals/squadState.nut")
let { decodeJwtAndHandleErrors } = require("%appGlobals/pServer/pServerJwt.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let matching = require("%appGlobals/matching_api.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { get_gui_option, addUserOption } = require("guiOptions")


let isSquadActualizeSend = mkWatched(persist, "isSquadActualizeSend", false)
let USEROPT_ALLOW_JIP = addUserOption("USEROPT_ALLOW_JIP")
let lastQueueStatsJwt = mkWatched(persist, "lastQueueStatsJwt", null)

isInQueue.subscribe(@(_) isSquadActualizeSend.set(false))
curQueueState.subscribe(@(v) logQ($"Queue state changed to: {queueStates.findindex(@(s) s == v)}"))

let setQueueState = @(state) curQueue.mutate(@(q) q.state = state)
let destroyQueue = @() curQueue.set(null)

let writeJwtData = @() curQueue.mutate(function(q) {
  let { payload = {}, jwt = "" } = queueData.get()
  let myParams = { profileJwt = jwt, statsJwt = jwtUserstat.get() ?? "" }

  q.state = QS_ACTUALIZE_SQUAD
  q.params = q.params.__merge({
    players = { [myUserId.get().tostring()] = myParams }
  })
  q.unitInfo <- queueData.get()?.unitInfo
  logQ($"Queue ", q.unitInfo, " params by token: ", payload)
})

function actualizeSquadQueueOnce() {
  if (isSquadActualizeSend.get())
    return
  isSquadActualizeSend.set(true)
  queueDataCheckTime.set(serverTime.get())
}

function findFirstGameMode(allGms, queueParams) {
  let { mode = null, game_modes_list = null } = queueParams
  if (mode != null)
    return allGms?.findvalue(@(m) m.name == mode)
  if (game_modes_list != null)
    return allGms?[game_modes_list.findvalue(@(id) id in allGms)]
  return null
}

function isModeInParams(modeName, allGms, queueParams) {
  let { mode = null, game_modes_list = null } = queueParams
  if (mode != null)
    return modeName == mode
  if (game_modes_list != null)
    return null != game_modes_list.findvalue(@(id) allGms?[id].name == modeName)
  return false
}

function tryWriteMembersData() {
  let playersUpd = {}
  let campaign = squadLeaderCampaign.get()
  let curGm = findFirstGameMode(allGameModes.get(), curQueue.get()?.params)
  let { penaltyId = "" } = curGm?.mission_decl

  foreach(uid, m in squadMembers.get()) {
    if (uid == myUserId.get())
      continue
    let { queueToken = "", statsToken = "", units = {} } = m
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

    let penaltyEndTime = payload?.penaltyEndTimeList[penaltyId == "" ? campaign : penaltyId] ?? 0
    if (penaltyEndTime > serverTime.get()) {
      openFMsgBox({ text = loc("multiplayer/queuePenaltySquad") })
      curQueue.set(null)
      return
    }
    playersUpd[uid.tostring()] <- { profileJwt = queueToken, statsJwt = statsToken }
  }

  curQueue.mutate(function(q) {
    q.params.players = q.params.players.__merge(playersUpd)
    q.state = QS_CHECK_HOSTS
    logQ($"Add {playersUpd.len()} squad members to queue state")
  })
}

function addClustersInfoAndContinue() {
  if (curQueueState.get() != QS_CHECK_HOSTS)
    return
  let { clusters, unreachableHosts } = getClustersAndHostsForQueue(squadMembers.get())
  curQueue.mutate(function(q) {
    q.params = q.params.__merge(can_send_hosts_reachability_to_matching.get()
      ? { clusters, unreachableHosts }
      : { clusters })
    q.state = QS_JOINING
    logQ($"Set clusters {",".join(clusters)}")
  })
}

eventbus_subscribe("hosts_reachability_validated", @(_) addClustersInfoAndContinue())

registerHandler("onActiveQueueActualizeData",
  function(res) {
    if (("error" in res) && curQueueState.get() == QS_ACTUALIZE)
      curQueue.set(null)
  })

let queueSteps = {
  [QS_REQUEST_STATS] = function() {
    if (isStatsActual.get() || allowSendOldStats.get())
      setQueueState(QS_ACTUALIZE)
    else {
      actualizeStats()
      resetTimeout(oldStatSendTime, @() curQueueState.get() != QS_REQUEST_STATS ? null : setQueueState(QS_ACTUALIZE))
    }
  },

  [QS_ACTUALIZE] = function() {
    if (isQueueDataActual.get())
      setQueueState(QS_CHECK_PENALTY)
    else
      actualizeQueueData("onActiveQueueActualizeData")
  },

  [QS_CHECK_PENALTY] = function() {
    let curGm = findFirstGameMode(allGameModes.get(), curQueue.get()?.params)
    let { penaltyId = "" } = curGm?.mission_decl
    let byMissionPenaltyId = penaltyId != ""
    if (!byMissionPenaltyId && curGm?.campaign == null)
      return writeJwtData()

    let mName = curGm?.mission_decl.missions_list.findindex(@(_) true) ?? curGm?.name ?? ""
    if (get_meta_mission_info_by_name(mName)?.gt_ffa)
      return writeJwtData()

    let { campaign, headerLocId } = getCampaignPresentation(curGm?.campaign)
    let actPenaltyId = byMissionPenaltyId ? penaltyId : campaign
    if ((servProfile.get()?.penalties[actPenaltyId].penaltyEndTime ?? 0) <= serverTime.get())
      return writeJwtData()

    curQueue.set(null)
    openFMsgBox({
      text = loc("multiplayer/queuePenalty/common",
        { name = byMissionPenaltyId
            ? loc($"penaltyId/{penaltyId}")
            : loc("penaltyId/campaign", { campaign = loc(headerLocId) })})
    })
  },

  [QS_ACTUALIZE_SQUAD] = function() {
    if (!isInSquad.get())
      setQueueState(QS_CHECK_HOSTS)
    else
      tryWriteMembersData()
  },

  [QS_CHECK_HOSTS] = function() {
    if (isHostsReachabilityValid())
      addClustersInfoAndContinue()
    else {
      requestHostsReachability() 
      resetTimeout(REACHABILITY_CHECK_TIMEOUT_SEC + 1, addClustersInfoAndContinue) 
      logQ("Requested hosts reachability")
    }
  },

  [QS_JOINING] = @() matching.rpc_call("match.enqueue",
    curQueue.get().params,
    function(response) {
      if (!isInQueue.get())
        return
      if (showMatchingError(response))
        curQueue.set(null)
      else
        setQueueState(QS_IN_QUEUE)
    }),

  [QS_IN_QUEUE] = function() {
    lastQueueStatsJwt.set(jwtUserstat.get()) 
    curQueue.mutate(@(q) q.activateTime <- get_time_msec())
  },

  [QS_LEAVING] = @() matching.rpc_call("match.leave_queue",
    {},
    function(response) {
      if (!isInQueue.get())
        return
      let errorId = response?.error
      if (errorId == SERVER_ERROR_REQUEST_REJECTED)
        eventbus_send("setWaitForQueueRoom", true)
      else if (errorId != SERVER_ERROR_NOT_IN_QUEUE)
        showMatchingError(response)
      destroyQueue()
    }),
}

let doStepAction = @() queueSteps?[curQueueState.get()]()
let doStepActionDelayed = @() deferOnce(doStepAction)
doStepActionDelayed()

curQueueState.subscribe(@(_) doStepActionDelayed())

let leaveQueue = @() isInQueue.get() ? setQueueState(QS_LEAVING) : null

isQueueDataActual.subscribe(function(v) {
  if (!v)
    return
  if (curQueueState.get() == QS_ACTUALIZE)
    setQueueState(QS_CHECK_PENALTY)
  else if (curQueueState.get() == QS_CHECK_PENALTY)
    writeJwtData()
})
isStatsActual.subscribe(function(v) {
  if (!v)
    return
  if (curQueueState.get() == QS_REQUEST_STATS)
    setQueueState(QS_ACTUALIZE)
})
allowSendOldStats.subscribe(function(v) {
  if (!v)
    return
  if (curQueueState.get() == QS_REQUEST_STATS)
    setQueueState(QS_ACTUALIZE)
})

curUnitInfo.subscribe(function(_) {  
  if (!isInQueue.get())
    return
  logQ("Leave queue by curUnitInfo change")
  leaveQueue()
})

squadMembers.subscribe(function(v) {
  if (!isInQueue.get() || !isSquadLeader.get())
    return

  foreach(uid, m in squadMembers.get())
    if (uid != myUserId.get() && !m?.ready) {
      logQ("Leave queue because member become not ready")
      leaveQueue()
      return
    }

  if (curQueueState.get() != QS_ACTUALIZE_SQUAD)
    return
  if (v.len() <= 1) 
    leaveQueue()
  else
    tryWriteMembersData()
})

function joinQueue(params) {
  if (isInQueue.get()) {
    logerr("Try to join new queue while in queue")
    return
  }
  let paramsExt = {
    team = TEAM_ANY
    jip = get_gui_option(USEROPT_ALLOW_JIP) ?? true
  }.__update(params)
  logQ("Request join queue: ", paramsExt)
  curQueue.set({ state = QS_REQUEST_STATS, params = paramsExt })
}

matching.subscribe("match.notify_queue_join", function(params) {
  logQ("match.notify_queue_join ", params)
  if (!isInQueue.get()) {
    curQueue.set({ state = QS_IN_QUEUE, params })
    return
  }
  let { mode = "" } = params
  if (!isModeInParams(mode, allGameModes.get(), curQueue.get().params))
    return
  curQueue.mutate(@(v) v.__update({ state = QS_IN_QUEUE }))
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
  let { mode = "" } = params
  if (!isModeInParams(mode, allGameModes.get(), curQueue.get().params))
    return
  destroyQueue()
})

eventbus_subscribe("leaveQueue", @(_) leaveQueue())

isMatchingConnected.subscribe(@(_) destroyQueue())

return queueState.__merge({
  joinQueue
  leaveQueue
  destroyQueue
  lastQueueStatsJwt
})