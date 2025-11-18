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
let squadLen = Computed(@() squadMembers.get().len())
let squadMyState = Computed(@() squadMembers.get()?[myUserId.get()])
let squadLeaderState = Computed(@() squadMembers.get()?[squadId.get()])

let isInSquad = Computed(@() squadId.get() != null)
let isSquadLeader = Computed(@() squadId.get() == myUserId.get())
let isLeavingWillDisbandSquad = Computed(@() squadLen.get() == 1 || (squadLen.get() + isInvitedToSquad.get().len() <= 2))
let canInviteToSquad = Computed(@() !isInSquad.get() || isSquadLeader.get())
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
  isSquadNotEmpty = Computed(@() squadMembers.get().len()>1)
  squadLen
  squadMyState
  squadLeaderState
  squadLeaderCampaign = Computed(@() squadLeaderState.get()?.campaign)
  squadLeaderReadyCheckTime = Computed(@() squadLeaderState.get()?.readyCheckTime ?? 0)
  squadLeaderMRankCheckTime = Computed(@() squadLeaderState.get()?.mRankCheckTime ?? 0)
  squadLeaderQueueDataCheckTime = Computed(@() squadLeaderState.get()?.queueDataCheckTime ?? 0)
  squadLeaderWantedModeId = Computed(@() squadLeaderState.get()?.wantedModeId ?? 0)
  squadLeaderDownloadCheckTime = Computed(@() squadLeaderState.get()?.downloadCheckTime ?? 0)

  isInSquad
  isSquadLeader
  isLeavingWillDisbandSquad
  canInviteToSquad
  myClustersRTT
  queueDataCheckTime

  getMemberMaxMRank
}