from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let allStages = [
  "stageAuth.nut"
  "stageUpdateGame.nut"
  "stageMatching.nut"
  "stageProfile.nut"
  "stageConfigs.nut"
  "stageCheckPurchases.nut"
  "stageOnlineSettings.nut"
  "stageInitConfigs.nut"
  "stageLegalAccept.nut"
]
  .map(@(name) require($"stages/{name}"))
  .extend(require("stages/nativeOnlineStages.nut"))

return allStages