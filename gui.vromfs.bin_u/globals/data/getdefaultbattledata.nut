//checked for explicitness
#no-root-fallback
#explicit-this

let defaultBattleData = require("defaultBattleData.nut")

return @(unitName) defaultBattleData?[unitName] ?? defaultBattleData.def