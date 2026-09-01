from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/math.nut" import getRomanNumeral
from "%appGlobals/clientState/clientState.nut" import isInDebriefing, isInBattle, isInLoadingScreen
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/openForeignMsgBox.nut" import subscribeFMsgBtns
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/profileStates.nut" import myUserId
from "%appGlobals/squadState.nut" import isInSquad, isSquadLeader, squadLeaderMRankCheckTime, squadMembers,
  squadLeaderCampaign, squadLeaderState, getMemberMaxMRank
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/msgBox.nut" import openMsgBox, closeMsgBox
from "%rGui/debriefing/debriefingState.nut" import isDebriefingAnimFinished
import "%rGui/squad/setReady.nut" as setReady


const MSG_UID = "mRankCheck"
const CAN_REPEAT_SEC = 15
let mRankCheckTime = hardPersistWatched("mRankCheckTime", 0)
let isMRankCheckSuspended = Watched(false)
isInSquad.subscribe(@(_) mRankCheckTime.set(isSquadLeader.get() ? 0 : serverTime.get()))
isSquadLeader.subscribe(@(v) !isInSquad.get() ? null
  : mRankCheckTime.set(v ? 0 : serverTime.get()))

let needMRankCheckMsg = Computed(@() isInSquad.get()
  && !isSquadLeader.get()
  && squadLeaderMRankCheckTime.get() > mRankCheckTime.get())
let canShowMRankCheck = Computed(@() !isInBattle.get()
  && !isInLoadingScreen.get()
  && (!isInDebriefing.get() || isDebriefingAnimFinished.get()))

let shouldShowMsg = keepref(Computed(@() needMRankCheckMsg.get() && canShowMRankCheck.get()))

function initiateMRankCheck() {
  if (!isSquadLeader.get())
    return
  if (isMRankCheckSuspended.get()) {
    openMsgBox({ text = loc("msg/bigRankDiff/checkInCooldown") })
    return
  }
  mRankCheckTime.set(serverTime.get())
  isMRankCheckSuspended.set(true)
  resetTimeout(CAN_REPEAT_SEC, @() isMRankCheckSuspended.set(false))
}

function showMRankCheck() {
  if (!shouldShowMsg.get())
    return

  let leaderMRank = getMemberMaxMRank(squadLeaderState.get(), squadLeaderCampaign.get(), serverConfigs.get())
  let myMRank = getMemberMaxMRank(squadMembers.get()?[myUserId.get()], squadLeaderCampaign.get(), serverConfigs.get())
  if (leaderMRank == myMRank) {
    mRankCheckTime.set(serverTime.get())
    return
  }

  setReady(false)
  let rankText = " ".concat(loc(getCampaignPresentation(squadLeaderCampaign.get()).headerLocId), getRomanNumeral(leaderMRank))
  openMsgBox({
    uid = MSG_UID
    text = loc("msg/bigRankDiff/askChange",
      { rankText = colorize("@mark", rankText) })
    buttons = [{ id = "ok", styleId = "PRIMARY", isDefault = true, cb = @() mRankCheckTime.set(serverTime.get()) }]
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