from "%scripts/dagui_library.nut" import *

let { totalPlayers, totalRooms } = require("%appGlobals/gameModes/gameModes.nut")
let matching = require("%scripts/matching_api.nut")

matching.subscribe("mlogin.update_online_info", function(data) {
  totalPlayers(data?.online_stats.players_total ?? -1)
  totalRooms(data?.online_stats.rooms_total ?? -1)
})
