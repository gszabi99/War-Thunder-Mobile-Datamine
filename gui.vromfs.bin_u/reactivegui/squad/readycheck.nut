from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { isInSquad, squadId, isSquadLeader, squadLeaderReadyCheckTime, squadMembers } = require("%appGlobals/squadState.nut")
let setReady = require("setReady.nut")
let { isInDebriefing, isInBattle, isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { isDebriefingAnimFinished } = require("%rGui/debriefing/debriefingState.nut")
let { openMsgBox, closeMsgBox } = require("%rGui/components/msgBox.nut")

let MSG_UID = "readyCheck"
let CAN_REPEAT_SEC = 15
let readyCheckTime = hardPersistWatched("readyCheckTime", 0)
let isReadyCheckSuspended = Watched(false)
let needReadyCheckButton = Computed(@() isSquadLeader.value
  && squadMembers.value.findvalue(@(m, uid) uid != squadId.value && !m?.ready) != null)
isInSquad.subscribe(@(_) readyCheckTime(isSquadLeader.value ? 0 : serverTime.value))
isSquadLeader.subscribe(@(v) !isInSquad.value ? null
  : readyCheckTime(v ? 0 : serverTime.value))

let needReadyCheckMsg = Computed(@() isInSquad.value
  && !isSquadLeader.value
  && squadLeaderReadyCheckTime.value > readyCheckTime.value)
let canShowReadyCheck = Computed(@() !isInBattle.value
  && !isInLoadingScreen.value
  && (!isInDebriefing.value || isDebriefingAnimFinished.value))

let shouldShowMsg = keepref(Computed(@() needReadyCheckMsg.value && canShowReadyCheck.value))

let function initiateReadyCheck() {
  if (!isSquadLeader.value)
    return
  if (isReadyCheckSuspended.value) {
    openMsgBox({ text = loc("squad/readyCheckInCooldownMsg") })
    return
  }
  readyCheckTime(serverTime.value)
  isReadyCheckSuspended(true)
  resetTimeout(CAN_REPEAT_SEC, @() isReadyCheckSuspended(false))
}

let function applyReadyCheckResult(newReady) {
  setReady(newReady)
  readyCheckTime(max(serverTime.value, squadLeaderReadyCheckTime.value))
}

let function showReadyCheck() {
  if (!shouldShowMsg.value)
    return
  openMsgBox({
    uid = MSG_UID
    text = loc("squad/readyCheckMsg")
    buttons = [
      { text = loc("status/squad_not_ready"), isCancel = true,
        cb = @() applyReadyCheckResult(false) }
      { text = loc("status/squad_ready"), styleId = "PRIMARY", isDefault = true,
        cb = @() applyReadyCheckResult(true) }
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