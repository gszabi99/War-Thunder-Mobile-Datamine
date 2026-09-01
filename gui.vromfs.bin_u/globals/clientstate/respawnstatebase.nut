from "%sqstd/globalState.nut" import hardPersistWatched


let isInRespawn = hardPersistWatched("isInRespawn", false)
let isBatleDataRequired = hardPersistWatched("isBatleDataRequired", false)
let respawnsLeft = hardPersistWatched("respawnsLeft", -1)
let respawnsTotalInitial = hardPersistWatched("respawnsTotalInitial", -1)
let respawnUnitInfo = hardPersistWatched("respawnUnitInfo", null)
let respawnUnitItems = hardPersistWatched("respawnUnitItems", null)
let respawnUnitMods = hardPersistWatched("respawnUnitMods", null)
let respawnUnitSkins = hardPersistWatched("respawnUnitSkins", null)
let isRespawnStarted = hardPersistWatched("isRespawnStarted", false)
let isRespawnDataInProgress = hardPersistWatched("isRespawnDataInProgress", false)
let isRespawnInProgress = hardPersistWatched("isRespawnInProgress", false)
let timeToRespawn = hardPersistWatched("timeToRespawn", -1)
let curUnitsAvgCostWp = hardPersistWatched("curUnitsAvgCostWp", null)
let isBattleDataFake = hardPersistWatched("isBattleDataFake", null)
let hasPredefinedReward = hardPersistWatched("hasPredefinedReward", false)

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
}
