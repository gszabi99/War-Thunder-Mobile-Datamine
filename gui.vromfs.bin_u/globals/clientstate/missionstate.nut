
let sharedWatched = require("%globalScripts/sharedWatched.nut")

return {
  missionProgressType = sharedWatched("missionProgressType", @() "")
  battleCampaign = sharedWatched("battleCampaign", @() "")
  battleUnitClasses = sharedWatched("battleUnitClasses", @() {})
  mainBattleUnitName = sharedWatched("mainBattleUnitName", @() null)
}
