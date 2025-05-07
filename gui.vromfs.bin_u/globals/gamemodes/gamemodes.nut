
let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let gameModesRaw = sharedWatched("gameModesRaw", @() {})
let totalRooms = sharedWatched("totalRooms", @() -1)
let totalPlayers = sharedWatched("totalPlayers", @() -1)
let allGameModes = Computed(@() gameModesRaw.value.filter(@(m) !(m?.disabled ?? false)))
let mkGameModeByCampaign = @(campaign)
  Computed(@() allGameModes.get().findvalue(@(m) m?.displayType == "random_battle" && m?.campaign == campaign))

return {
  mkGameModeByCampaign
  gameModesRaw
  allGameModes
  totalPlayers
  totalRooms
}
