from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%rGui/gameModes/gameModeState.nut" import randomBattleMode
from "%rGui/gameModes/offlineBattlesState.nut" import isOfflineBattlesActive
from "%rGui/mainMenu/penaltyState.nut" import hasPenaltyStatus


let battleBtnCampaign = Computed(@() randomBattleMode.get()?.campaign)

const timerSize = hdpxi(40)
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
        size = const [timerSize, timerSize]
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