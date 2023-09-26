from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/ecs.nut" import *
let { get_mplayer_by_id } = require("mission")
let { resetTimeout } = require("dagor.workcycle")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let playersDamageStats = Watched({})
let statsRaw = Watched({})
let localPlayerId = Watched(-1)
let playerTeams = Watched({})
let playerTeamDamageStats = Computed(function() {
  let team = playerTeams.value?[localPlayerId.value]
  if (team == null)
    return {}
  return playersDamageStats.value.filter(@(_, id) playerTeams.value?[id] == team)
})

let syncStats = @() playersDamageStats(clone statsRaw.value)
statsRaw.subscribe(@(_)
  resetTimeout(playersDamageStats.value.len() == 0 ? 0.01 : 0.1, syncStats))

playersDamageStats.subscribe(function(stats) {
  if (!isInBattle.value)
    return
  let upd = []
  foreach(id, _ in stats)
    if (id not in playerTeams.value)
      upd.append(id)
  if (upd.len() == 0)
    return

  let teams = clone playerTeams.value
  foreach(id in upd) {
    let { team = null, isLocal = false } = get_mplayer_by_id(id)
    if (team != null)
      teams[id] <- team
    if (isLocal)
      localPlayerId(id)
  }
  playerTeams(teams)
})

isInBattle.subscribe(function(_) {
  localPlayerId(-1)
  playerTeams({})
  playersDamageStats({})
  statsRaw({})
})

register_es("players_damage_stats_es",
  {
    [["onInit", "onChange"]] = function trackDamageStats(_, comp) {
      let { stats__damage, stats__score, player_id } = comp
      statsRaw.mutate(@(v) v[player_id] <- {
        damage = stats__damage
        score = stats__score
      })
    },
    [["onDestroy"]] = function trackDamageStats(_, comp) {
      let { player_id } = comp
      if (player_id.tostring() in statsRaw.value)
        statsRaw.mutate(@(v) delete v[player_id])
    },
  },
  {
    comps_track = [
      ["stats__damage", TYPE_FLOAT],
      ["stats__score", TYPE_FLOAT],
    ]
    comps_ro = [["player_id", TYPE_INT]]
  })

return {
  playersDamageStats
  localPlayerId
  playerTeamDamageStats
  localPlayerDamageStats = Computed(@() playersDamageStats.value?[localPlayerId.value])
}