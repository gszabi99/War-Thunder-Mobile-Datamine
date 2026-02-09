let { Computed } = require("frp")

let sharedWatched = require("%globalScripts/sharedWatched.nut")

let hudCustomRules = sharedWatched("hudCustomRules", @() {})

return {
  missionProgressType = sharedWatched("missionProgressType", @() "")
  battleCampaign = sharedWatched("battleCampaign", @() "")
  battleUnitClasses = sharedWatched("battleUnitClasses", @() {})
  mainBattleUnitName = sharedWatched("mainBattleUnitName", @() null)

  hudCustomRules
  ctfFlagPreset = Computed(@() hudCustomRules.get()?.ctfFlagPreset ?? "")
}
