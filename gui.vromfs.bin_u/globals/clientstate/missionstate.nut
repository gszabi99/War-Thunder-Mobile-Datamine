
let sharedWatched = require("%globalScripts/sharedWatched.nut")

return {
  missionProgressType = sharedWatched("missionProgressType", @() "")
  battleCampaign = sharedWatched("battleCampaign", @() "")
}
