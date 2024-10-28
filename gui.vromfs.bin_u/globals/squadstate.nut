let { Computed } = require("frp")
let { max } = require("math")
let { myUserId } = require("%appGlobals/profileStates.nut")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let squadId = sharedWatched("squadId", @() null)
let isInvitedToSquad = sharedWatched("isInvitedToSquad", @() {})
let squadMembers = sharedWatched("squadMembers", @() {})
let squadOnline = sharedWatched("squadOnline", @() {})
let squadMembersOrder = sharedWatched("squadMembersOrder", @() [])
let isReady = sharedWatched("squadIsReady", @() false)
let squadLen = Computed(@() squadMembers.value.len())
let squadMyState = Computed(@() squadMembers.value?[myUserId.value])
let squadLeaderState = Computed(@() squadMembers.value?[squadId.value])
let squadLeaderCampaign = Computed(@() squadLeaderState.value?.campaign)
let squadLeaderReadyCheckTime = Computed(@() squadLeaderState.value?.readyCheckTime ?? 0)
let squadLeaderMRankCheckTime = Computed(@() squadLeaderState.value?.mRankCheckTime ?? 0)
let squadLeaderQueueDataCheckTime = Computed(@() squadLeaderState.value?.queueDataCheckTime ?? 0)

let isInSquad = Computed(@() squadId.value != null)
let isSquadLeader = Computed(@() squadId.value == myUserId.value)
let isLeavingWillDisbandSquad = Computed(@() squadLen.value == 1 || (squadLen.value + isInvitedToSquad.value.len() <= 2))
let canInviteToSquad = Computed(@() !isInSquad.value || isSquadLeader.value)
let myClustersRTT = sharedWatched("myClustersRTT", @() {})
let queueDataCheckTime = sharedWatched("queueDataCheckTime", @() 0)

function getMemberMaxMRank(memberInfo, campaign, srvConfigs) {
  local list = memberInfo?.units[campaign]
  if (list == null)
    return -1
  return list.reduce(@(res, unitName) max(res, srvConfigs?.allUnits[unitName].mRank ?? 0), -1)
}

return {
  MAX_SQUAD_MRANK_DIFF = 1

  squadId
  isReady
  isInvitedToSquad
  squadMembers
  squadOnline
  squadMembersOrder
  isSquadNotEmpty = Computed(@() squadMembers.value.len()>1)
  squadLen
  squadMyState
  squadLeaderState
  squadLeaderCampaign
  squadLeaderReadyCheckTime
  squadLeaderMRankCheckTime
  squadLeaderQueueDataCheckTime

  isInSquad
  isSquadLeader
  isLeavingWillDisbandSquad
  canInviteToSquad
  myClustersRTT
  queueDataCheckTime

  getMemberMaxMRank
}