from "%scripts/dagui_library.nut" import *

let allStages = [
  "stageAuth.nut"
  "stageUpdateGame.nut"
  "stageMatching.nut"
  "stageContacts.nut"
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