from "%globalsDarg/darg_library.nut" import *
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { randomBattleMode } = require("%rGui/gameModes/gameModeState.nut")
let { hasPenaltyStatus } = require("%rGui/mainMenu/penaltyState.nut")


let battleBtnCampaign = Computed(@() randomBattleMode.get()?.campaign ?? curCampaign.get())

let timerSize = hdpxi(40)
let penaltyTimerIcon = @(campaign = null) function() {
  let res = { watch = [hasPenaltyStatus, battleBtnCampaign] }
  let hasPenalty = (hasPenaltyStatus.get()?[campaign ?? battleBtnCampaign.get()] ?? false)
    || (hasPenaltyStatus.get()?[curCampaign.get()] ?? false)
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