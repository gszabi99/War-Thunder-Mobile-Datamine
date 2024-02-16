from "%globalsDarg/darg_library.nut" import *
let botsInfo = mkWatched(persist, "botsInfo", {})
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { rnd_int, rnd_float } = require("dagor.random")

function generateBot(player) {
  let { level, userId, decorators = {} } = player
  let battle_end_ships = (level * level * rnd_float(3.0, 6.0) + 0.5).tointeger()
  let battle_end_tanks = (level * level * rnd_float(3.0, 6.0) + 0.5).tointeger()
  let result = {
    info = {
      playerLevel = level
      campaigns = {
        ships = {
          units = {
            wp = (rnd_float(1.0, 1.5) * level).tointeger()
            maxLevel = 0
            prem = rnd_int(1, 3)
            rare = rnd_int(1, 3)
          }
          level
          starLevelHistory = []
        }
        tanks = {
          units = {
            wp = (rnd_float(1.0, 1.5) * level).tointeger()
            maxLevel = 0
            prem = rnd_int(1, 3)
            rare = rnd_int(1, 3)
          }
          level
          starLevelHistory = []
        }
      }
      playerStarLevel = 0
      decorators
    }
    stats = {
      stats = {
        ["global"]  = {
          ships = {
            battle_end = battle_end_ships
            win = rnd_int(0.45 * battle_end_ships, 0.55 * battle_end_ships)
          }
          tanks = {
            battle_end = battle_end_tanks
            win = rnd_int(0.45 * battle_end_tanks, 0.55 * battle_end_tanks)
          }
        }
      }
    }
  }
  result.info.campaigns.ships.units.maxLevel =
    result.info.campaigns.ships.units.prem + rnd_int(0, result.info.campaigns.ships.units.wp)
  result.info.campaigns.tanks.units.maxLevel =
    result.info.campaigns.tanks.units.prem + rnd_int(0, result.info.campaigns.tanks.units.wp)
  botsInfo.mutate(@(v) v[userId] <- result)
}

function mkBotInfo(player) {
  if (player.userId not in botsInfo.get())
    generateBot(player)
  return Computed(@() botsInfo.get()[player.userId].info)
}

function mkBotStats(player) {
  if (player.userId not in botsInfo.get())
    generateBot(player)
  return Computed(@() botsInfo.get()[player.userId].stats)
}

isInBattle.subscribe(function(v) {
  if (v)
    botsInfo.set({})
})

return {
  mkBotStats
  mkBotInfo
}
