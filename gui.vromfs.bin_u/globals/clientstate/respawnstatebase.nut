
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let isInRespawn = sharedWatched("isInRespawn", @() false)
let isBatleDataRequired = sharedWatched("isBatleDataRequired", @() false)
let respawnsLeft = sharedWatched("respawnsLeft", @() -1)
let respawnsTotalInitial = sharedWatched("respawnsTotalInitial", @() -1)
let respawnUnitInfo = sharedWatched("respawnUnitInfo", @() null)
let respawnUnitItems = sharedWatched("respawnUnitItems", @() null)
let respawnUnitMods = sharedWatched("respawnUnitMods", @() null)
let respawnUnitSkins = sharedWatched("respawnUnitSkins", @() null)
let isRespawnStarted = sharedWatched("isRespawnStarted", @() false)
let isRespawnDataInProgress = sharedWatched("isRespawnDataInProgress", @() false)
let isRespawnInProgress = sharedWatched("isRespawnInProgress", @() false)
let timeToRespawn = sharedWatched("timeToRespawn", @() -1)
let curUnitsAvgCostWp = sharedWatched("curUnitsAvgCostWp", @() null)
let isBattleDataFake = sharedWatched("isBattleDataFake", @() null)
let hasPredefinedReward = sharedWatched("hasPredefinedReward", @() false)
let dailyBonus = sharedWatched("dailyBonus", @() null)

return {
  isInRespawn
  isBatleDataRequired
  respawnsLeft
  respawnsTotalInitial
  respawnUnitInfo
  respawnUnitItems
  respawnUnitMods
  respawnUnitSkins
  isRespawnStarted
  isRespawnDataInProgress
  isRespawnInProgress
  timeToRespawn
  curUnitsAvgCostWp
  isBattleDataFake
  hasPredefinedReward
  dailyBonus
}
