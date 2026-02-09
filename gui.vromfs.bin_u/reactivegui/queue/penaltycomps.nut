from "%globalsDarg/darg_library.nut" import *
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { randomBattleMode } = require("%rGui/gameModes/gameModeState.nut")
let { hasPenaltyStatus } = require("%rGui/mainMenu/penaltyState.nut")
let { isOfflineBattlesActive } = require("%rGui/gameModes/offlineBattlesState.nut")


let battleBtnCampaign = Computed(@() randomBattleMode.get()?.campaign)

let timerSize = hdpxi(40)
let penaltyTimerIcon = @(rawCampaign = null, penaltyId = "") function() {
  let res = { watch = [hasPenaltyStatus, battleBtnCampaign, isOfflineBattlesActive] }
  if (isOfflineBattlesActive.get())
    return res

  let byMissionPenaltyId = penaltyId != ""
  let campaign = rawCampaign ?? battleBtnCampaign.get()
  if (!byMissionPenaltyId && campaign == null)
    return res

  let actPenaltyId = byMissionPenaltyId ? penaltyId : getCampaignPresentation(campaign).campaign
  let hasPenalty = hasPenaltyStatus.get()?[actPenaltyId] ?? false
  return !hasPenalty ? res
    : res.__update({
        size = [timerSize, timerSize]
        margin = const [hdpx(8), hdpx(16)]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#timer_icon.svg:{timerSize}:{timerSize}:P")
        vplace = ALIGN_TOP
        hplace = ALIGN_RIGHT
        keepAspect = KEEP_ASPECT_FIT
      })
}

return {
  battleBtnCampaign
  penaltyTimerIcon
}