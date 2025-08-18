from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { isInSquad, squadId, isSquadLeader, squadLeaderReadyCheckTime, squadMembers } = require("%appGlobals/squadState.nut")
let setReady = require("%rGui/squad/setReady.nut")
let { registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { isInDebriefing, isInBattle, isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { isDebriefingAnimFinished } = require("%rGui/debriefing/debriefingState.nut")
let { openMsgBox, closeMsgBox } = require("%rGui/components/msgBox.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let showNoPremMessageIfNeed = require("%rGui/shop/missingPremiumAccWnd.nut")
let offerMissingUnitItemsMessage = require("%rGui/shop/offerMissingUnitItemsMessage.nut")
let tryOpenQueuePenaltyWnd = require("%rGui/queue/queuePenaltyWnd.nut")
let { battleBtnCampaign, penaltyTimerIcon } = require("%rGui/queue/penaltyComps.nut")


let MSG_UID = "readyCheck"
let CAN_REPEAT_SEC = 15
let readyCheckTime = hardPersistWatched("readyCheckTime", 0)
let isReadyCheckSuspended = Watched(false)
let needReadyCheckButton = Computed(@() isSquadLeader.get()
  && squadMembers.get().findvalue(@(m, uid) uid != squadId.get() && !m?.ready) != null)
isInSquad.subscribe(@(_) readyCheckTime(isSquadLeader.get() ? 0 : serverTime.get()))
isSquadLeader.subscribe(@(v) !isInSquad.get() ? null
  : readyCheckTime(v ? 0 : serverTime.get()))

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
  readyCheckTime(serverTime.get())
  isReadyCheckSuspended.set(true)
  resetTimeout(CAN_REPEAT_SEC, @() isReadyCheckSuspended.set(false))
}

function applyReadyCheckResult(newReady) {
  setReady(newReady)
  readyCheckTime(max(serverTime.get(), squadLeaderReadyCheckTime.get()))
}

let onSquadReady = @() showNoPremMessageIfNeed(@()
  offerMissingUnitItemsMessage(curUnit.get(), @() applyReadyCheckResult(true), @() applyReadyCheckResult(false)))
let onSquadNotReady = @() applyReadyCheckResult(false)

let cbReadyCheckId = "onResetPenaltyReadyCheck"
registerHandler(cbReadyCheckId, @(res) res?.error == null ? onSquadReady() : null)

function showReadyCheck() {
  if (!shouldShowMsg.value)
    return
  openMsgBox({
    uid = MSG_UID
    text = loc("squad/readyCheckMsg")
    buttons = [
      { text = loc("status/squad_not_ready"), isCancel = true, cb = onSquadNotReady }
      { text = loc("status/squad_ready"), styleId = "PRIMARY", isDefault = true, addChild = penaltyTimerIcon()
        function cb() {
          if (tryOpenQueuePenaltyWnd(battleBtnCampaign.get(), cbReadyCheckId, onSquadNotReady))
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