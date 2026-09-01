from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/campaign.nut" import curCampaign


let selectedPlayerForInfo = Watched(null)
let SECTION_PROFILE_IDS = {
  PROFILE = "profile"
  SCORE = "score"
}

return {
  selectedPlayerForInfo
  SECTION_PROFILE_IDS
  viewProfile = @(userId, ovr = {}) selectedPlayerForInfo.set({
    player = { userId, isBot = false }
    campaign = curCampaign.get()
  }.__merge(ovr))
}
