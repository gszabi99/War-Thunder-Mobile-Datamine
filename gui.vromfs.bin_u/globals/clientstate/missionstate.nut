from "frp" import Computed
from "%sqstd/globalState.nut" import hardPersistWatched


let hudCustomRules = hardPersistWatched("hudCustomRules", {})

return {
  battleCampaign = hardPersistWatched("battleCampaign", "")
  battleUnitClasses = hardPersistWatched("battleUnitClasses", {})
  mainBattleUnitName = hardPersistWatched("mainBattleUnitName", null)

  hudCustomRules
  ctfFlagPreset = Computed(@() hudCustomRules.get()?.ctfFlagPreset ?? "")
  missionProgressType = Computed(@() hudCustomRules.get()?.missionProgressType ?? "")
}
