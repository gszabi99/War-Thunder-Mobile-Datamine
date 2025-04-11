from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")


let hasPenaltyStatus = Watched({})
let penalties = Computed(@() servProfile.get()?.penalties ?? {})

function updatePenaltyStatus() {
  if (!isServerTimeValid.get()) {
    hasPenaltyStatus.set({})
    return
  }

  local minLeftTime = 0
  let penaltyUpdate = {}
  foreach (camp, p in penalties.get()) {
    let leftTime = (p?.penaltyEndTime ?? 0) - serverTime.get()
    let hasPenalty = leftTime > 0
    penaltyUpdate[camp] <- hasPenalty
    if (!hasPenalty)
      continue
    minLeftTime = minLeftTime == 0 ? leftTime : min(minLeftTime, leftTime)
  }
  hasPenaltyStatus.set(penaltyUpdate)

  if (minLeftTime > 0)
    resetTimeout(minLeftTime, updatePenaltyStatus)
}

isServerTimeValid.subscribe(@(_) updatePenaltyStatus())
penalties.subscribe(@(_) updatePenaltyStatus())
updatePenaltyStatus()

return {
  hasPenaltyStatus
  penalties
}