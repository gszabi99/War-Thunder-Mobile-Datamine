from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/clientState.nut" import isInDebriefing, isInBattle, isInLoadingScreen
from "%appGlobals/pServer/pServerApi.nut" import registerHandler
from "%appGlobals/pServer/profile.nut" import curUnits
from "%appGlobals/squadState.nut" import isInSquad, squadId, isSquadLeader, squadLeaderReadyCheckTime, squadMembers
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/msgBox.nut" import openMsgBox, closeMsgBox
from "%rGui/debriefing/debriefingState.nut" import isDebriefingAnimFinished
from "%rGui/gameModes/gameModeState.nut" import randomBattleMode
from "%rGui/queue/penaltyComps.nut" import battleBtnCampaign, penaltyTimerIcon
import "%rGui/queue/queuePenaltyWnd.nut" as tryOpenQueuePenaltyWnd
import "%rGui/shop/missingPremiumAccWnd.nut" as showNoPremMessageIfNeed
import "%rGui/shop/offerMissingUnitItemsMessage.nut" as offerMissingUnitItemsMessage
import "%rGui/squad/setReady.nut" as setReady


const MSG_UID = "readyCheck"
const CAN_REPEAT_SEC = 15
let readyCheckTime = hardPersistWatched("readyCheckTime", 0)
let isReadyCheckSuspended = Watched(false)
let needReadyCheckButton = Computed(@() isSquadLeader.get()
  && squadMembers.get().findvalue(@(m, uid) uid != squadId.get() && !m?.ready) != null)
isInSquad.subscribe(@(_) readyCheckTime.set(isSquadLeader.get() ? 0 : serverTime.get()))
isSquadLeader.subscribe(@(v) !isInSquad.get() ? null
  : readyCheckTime.set(v ? 0 : serverTime.get()))

let needReadyCheckMsg = Computed(@() isInSquad.get()
  && !isSquadLeader.get()
  && squadLeaderReadyCheckTime.get() > readyCheckTime.get())
let canShowReadyCheck = Computed(@() !isInBattle.get()
  && !isInLoadingScreen.get()
  && (!isInDebriefing.get() || isDebriefingAnimFinished.get()))

let shouldShowMsg = keepref(Computed(@() needReadyCheckMsg.get() && canShowReadyCheck.get()))

function initiateReadyCheck() {
  if (!isSquadLeader.get())
    return
  if (isReadyCheckSuspended.get()) {
    openMsgBox({ text = loc("squad/readyCheckInCooldownMsg") })
    return
  }
  readyCheckTime.set(serverTime.get())
  isReadyCheckSuspended.set(true)
  resetTimeout(CAN_REPEAT_SEC, @() isReadyCheckSuspended.set(false))
}

function applyReadyCheckResult(newReady) {
  setReady(newReady)
  readyCheckTime.set(max(serverTime.get(), squadLeaderReadyCheckTime.get()))
}

let onSquadReady = @() showNoPremMessageIfNeed(@()
  offerMissingUnitItemsMessage(curUnits.get(), @() applyReadyCheckResult(true), null, @() applyReadyCheckResult(false)))
let onSquadNotReady = @() applyReadyCheckResult(false)

const cbReadyCheckId = "onResetPenaltyReadyCheck"
registerHandler(cbReadyCheckId, @(res) res?.error == null ? onSquadReady() : null)

function showReadyCheck() {
  if (!shouldShowMsg.get())
    return
  openMsgBox({
    uid = MSG_UID
    text = loc("squad/readyCheckMsg")
    buttons = [
      { text = loc("status/squad_not_ready"), isCancel = true, cb = onSquadNotReady }
      { text = loc("status/squad_ready"), styleId = "PRIMARY", isDefault = true, addChild = penaltyTimerIcon()
        function cb() {
          if (tryOpenQueuePenaltyWnd(battleBtnCampaign.get(), randomBattleMode.get(), cbReadyCheckId, onSquadNotReady))
            return
          onSquadReady()
        }
      }
    ]
  })
}

showReadyCheck()
shouldShowMsg.subscribe(@(v) v ? resetTimeout(0.1, showReadyCheck) : closeMsgBox(MSG_UID))

return {
  readyCheckTime
  needReadyCheckButton
  initiateReadyCheck
  isReadyCheckSuspended
}