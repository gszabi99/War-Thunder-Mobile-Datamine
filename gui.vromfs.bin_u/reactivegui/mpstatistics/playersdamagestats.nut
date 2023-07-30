from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/ecs.nut" import *
let { sendNetEvent, CmdGetPlayersStats } = require("dasevents")
let { EventPlayerStats } = require("%appGlobals/sqevents.nut")

let playersDamageStats = mkWatched(persist, "playersDamageStats", {})

let find_local_player_query = SqQuery("find_local_player_query", { comps_rq = ["localPlayer"] })
let find_local_player_eid = @()
  find_local_player_query(@(eid, _) eid) ?? INVALID_ENTITY_ID

let requestPlayersDamageStats = @()
  sendNetEvent(find_local_player_eid(), CmdGetPlayersStats())

register_es("players_damage_stats_es",
  { [EventPlayerStats] = @(evt, _eid, _comp) playersDamageStats(evt.data?.damage ?? {}) },
  { comps_rq = [["server_player__userId", TYPE_UINT64]] })

return {
  playersDamageStats
  requestPlayersDamageStats
}