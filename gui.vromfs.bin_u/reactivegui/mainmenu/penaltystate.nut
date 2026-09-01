from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "%appGlobals/config/campaignPresentation.nut" import campaignPresentations, getCampaignPresentation
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/timeoutExt.nut" import resetExtTimeout
from "%appGlobals/userstats/serverTime.nut" import serverTime, isServerTimeValid


let hasPenaltyStatus = Watched({})
let penalties = Computed(function() {
  let basePenalties = servProfile.get()?.penalties ?? {}
  let res = clone basePenalties
  foreach (k, v in basePenalties)
    if (k in campaignPresentations)
      res[getCampaignPresentation(k).campaign] <- v
  return res
})

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
    resetExtTimeout(minLeftTime, updatePenaltyStatus)
}

isServerTimeValid.subscribe(@(_) deferOnce(updatePenaltyStatus))
penalties.subscribe(@(_) deferOnce(updatePenaltyStatus))
updatePenaltyStatus()

return {
  hasPenaltyStatus
  penalties
}