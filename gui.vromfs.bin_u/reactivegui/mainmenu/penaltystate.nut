from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { campaignPresentations, getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { resetExtTimeout } = require("%appGlobals/timeoutExt.nut")


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