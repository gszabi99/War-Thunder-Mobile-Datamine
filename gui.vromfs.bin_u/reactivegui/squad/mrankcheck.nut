from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { isInSquad, isSquadLeader, squadLeaderMRankCheckTime, squadMembers,
  squadLeaderCampaign, squadLeaderState, getMemberMaxMRank
} = require("%appGlobals/squadState.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let setReady = require("setReady.nut")
let { isInDebriefing, isInBattle, isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { isDebriefingAnimFinished } = require("%rGui/debriefing/debriefingState.nut")
let { openMsgBox, closeMsgBox } = require("%rGui/components/msgBox.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { subscribeFMsgBtns } = require("%appGlobals/openForeignMsgBox.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")

let MSG_UID = "mRankCheck"
let CAN_REPEAT_SEC = 15
let mRankCheckTime = hardPersistWatched("mRankCheckTime", 0)
let isMRankCheckSuspended = Watched(false)
isInSquad.subscribe(@(_) mRankCheckTime(isSquadLeader.value ? 0 : serverTime.value))
isSquadLeader.subscribe(@(v) !isInSquad.value ? null
  : mRankCheckTime(v ? 0 : serverTime.value))

let needMRankCheckMsg = Computed(@() isInSquad.value
  && !isSquadLeader.value
  && squadLeaderMRankCheckTime.value > mRankCheckTime.value)
let canShowMRankCheck = Computed(@() !isInBattle.value
  && !isInLoadingScreen.value
  && (!isInDebriefing.value || isDebriefingAnimFinished.value))

let shouldShowMsg = keepref(Computed(@() needMRankCheckMsg.value && canShowMRankCheck.value))

function initiateMRankCheck() {
  if (!isSquadLeader.value)
    return
  if (isMRankCheckSuspended.value) {
    openMsgBox({ text = loc("msg/bigRankDiff/checkInCooldown") })
    return
  }
  mRankCheckTime(serverTime.value)
  isMRankCheckSuspended(true)
  resetTimeout(CAN_REPEAT_SEC, @() isMRankCheckSuspended(false))
}

function showMRankCheck() {
  if (!shouldShowMsg.value)
    return

  let leaderMRank = getMemberMaxMRank(squadLeaderState.get(), squadLeaderCampaign.get(), serverConfigs.get())
  let myMRank = getMemberMaxMRank(squadMembers.get()?[myUserId.get()], squadLeaderCampaign.get(), serverConfigs.get())
  if (leaderMRank == myMRank) {
    mRankCheckTime(serverTime.get())
    return
  }

  setReady(false)
  let rankText = " ".concat(loc(getCampaignPresentation(squadLeaderCampaign.get()).headerLocId), getRomanNumeral(leaderMRank))
  openMsgBox({
    uid = MSG_UID
    text = loc("msg/bigRankDiff/askChange",
      { rankText = colorize("@mark", rankText) })
    buttons = [{ id = "ok", styleId = "PRIMARY", isDefault = true, cb = @() mRankCheckTime(serverTime.value) }]
  })
}

showMRankCheck()
shouldShowMsg.subscribe(@(v) v ? resetTimeout(0.1, showMRankCheck) : closeMsgBox(MSG_UID))

subscribeFMsgBtns({
  initiateSquadMRankCheck = @(_) initiateMRankCheck()
})

return {
  mRankCheckTime
  initiateMRankCheck
  isMRankCheckSuspended
}