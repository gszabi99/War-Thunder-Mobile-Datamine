
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let isInRespawn = sharedWatched("isInRespawn", @() false)
let isBatleDataRequired = sharedWatched("isBatleDataRequired", @() false)
let respawnsLeft = sharedWatched("respawnsLeft", @() -1)
let respawnUnitInfo = sharedWatched("respawnUnitInfo", @() null)
let respawnUnitItems = sharedWatched("respawnUnitItems", @() null)
let respawnUnitSkins = sharedWatched("respawnUnitSkins", @() null)
let isRespawnStarted = sharedWatched("isRespawnStarted", @() false)
let isRespawnDataInProgress = sharedWatched("isRespawnDataInProgress", @() false)
let isRespawnInProgress = sharedWatched("isRespawnInProgress", @() false)
let timeToRespawn = sharedWatched("timeToRespawn", @() -1)

return {
  isInRespawn
  isBatleDataRequired
  respawnsLeft
  respawnUnitInfo
  respawnUnitItems
  respawnUnitSkins
  isRespawnStarted
  isRespawnDataInProgress
  isRespawnInProgress
  timeToRespawn
}
