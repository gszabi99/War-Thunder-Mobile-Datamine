//checked for explicitness
#no-root-fallback
#explicit-this

let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let gameModesRaw = sharedWatched("gameModesRaw", @() {})
let totalRooms = sharedWatched("totalRooms", @() -1)
let totalPlayers = sharedWatched("totalPlayers", @() -1)
let allGameModes = Computed(@() gameModesRaw.value.filter(@(m) !(m?.disabled ?? false)))

return {
  gameModesRaw
  allGameModes
  totalPlayers
  totalRooms
}
