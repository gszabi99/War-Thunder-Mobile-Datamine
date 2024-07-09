from "%globalsDarg/darg_library.nut" import *
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")

let selectedPlayerForInfo = Watched(null)

return {
  selectedPlayerForInfo
  viewProfile = @(userId, ovr = {}) selectedPlayerForInfo.set({
    player = { userId, isBot = false }
    campaign = curCampaign.get()
  }.__merge(ovr))
}
