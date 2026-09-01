from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/ecs.nut" import *
from "dagor.workcycle" import resetTimeout
from "mission" import get_mplayer_by_id
from "%appGlobals/clientState/clientState.nut" import isInBattle, isInLoadingScreen


let playersDamageStats = Watched({})
let statsRaw = Watched({})
let localPlayerId = Watched(-1)
let playerTeams = Watched({})
let playerTeamDamageStats = Computed(function() {
  let team = playerTeams.get()?[localPlayerId.get()]
  if (team == null)
    return {}
  return playersDamageStats.get().filter(@(_, id) playerTeams.get()?[id] == team)
})

let syncStats = @() playersDamageStats.set(clone statsRaw.get())
statsRaw.subscribe(@(_)
  resetTimeout(playersDamageStats.get().len() == 0 ? 0.01 : 0.1, syncStats))

playersDamageStats.subscribe(function(stats) {
  if (!isInBattle.get())
    return
  let upd = []
  foreach(id, _ in stats)
    if (id not in playerTeams.get())
      upd.append(id)
  if (upd.len() == 0)
    return

  let teams = clone playerTeams.get()
  foreach(id in upd) {
    let { team = null, isLocal = false } = get_mplayer_by_id(id)
    if (team != null)
      teams[id] <- team
    if (isLocal)
      localPlayerId.set(id)
  }
  playerTeams.set(teams)
})

isInLoadingScreen.subscribe(function(v) {
  if (v && !isInBattle.get()) {
    localPlayerId.set(-1)
    playerTeams.set({})
    playersDamageStats.set({})
    statsRaw.set({})
  }
})

register_es("players_damage_stats_es",
  {
    [["onInit", "onChange"]] = function trackDamageStats(_, comp) {
      let { stats__damage, stats__score, stats__flagsDelivered, player_id, stats__bomberKills } = comp
      statsRaw.mutate(@(v) v[player_id] <- {
        damage = stats__damage
        score = stats__score
        flagsDelivered = stats__flagsDelivered
        bomberKills = stats__bomberKills
      })
    },
    [["onDestroy"]] = function trackDamageStats(_, comp) {
      let { player_id } = comp
      if (player_id in statsRaw.get())
        statsRaw.mutate(@(v) v.$rawdelete(player_id))
    },
  },
  {
    comps_track = [
      ["stats__damage", TYPE_FLOAT],
      ["stats__score", TYPE_FLOAT],
      ["stats__flagsDelivered", TYPE_INT],
      ["stats__bomberKills", TYPE_INT],
    ]
    comps_ro = [["player_id", TYPE_INT]]
  })

return {
  playersDamageStats
  localPlayerId
  playerTeamDamageStats
  localPlayerDamageStats = Computed(@() playersDamageStats.get()?[localPlayerId.get()])
}