from "%scripts/dagui_library.nut" import *

let { totalPlayers, totalRooms } = require("%appGlobals/gameModes/gameModes.nut")
let matching = require("%appGlobals/matching_api.nut")

matching.subscribe("mlogin.update_online_info", function(data) {
  totalPlayers.set(data?.online_stats.players_total ?? -1)
  totalRooms.set(data?.online_stats.rooms_total ?? -1)
})
