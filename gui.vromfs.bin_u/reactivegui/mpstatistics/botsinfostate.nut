from "%globalsDarg/darg_library.nut" import *
from "dagor.random" import rnd_int, rnd_float
from "%appGlobals/clientState/clientState.nut" import isInBattle


let botsInfo = mkWatched(persist, "botsInfo", {})

function mkUnits(level) {
  let research = (rnd_float(1.0, 1.5) * level).tointeger()
  let blueprint = (rnd_float(0.0, 0.375) * level).tointeger()
  let premium = rnd_int(0, 3)
  let collectible = rnd_int(0, 3)

  return {
    research
    blueprint
    premium
    collectible
    all = research + blueprint + premium + collectible
    maxLevel = premium + collectible +
      (rnd_float(0.05, 0.15) * (research + blueprint)).tointeger()
  }
}

function generateBot(player) {
  let { userId, decorators = {}, level = 1 } = player
  let battle_end_ships = (level * level * rnd_float(3.0, 6.0) + 0.5).tointeger()
  let battle_end_tanks = (level * level * rnd_float(3.0, 6.0) + 0.5).tointeger()
  let battle_end_air = (level * level * rnd_float(3.0, 6.0) + 0.5).tointeger()

  let result = {
    info = {
      playerLevel = level
      campaigns = {
        ships = {
          units = mkUnits(level)
          level
          starLevelHistory = []
        }
        tanks = {
          units = mkUnits(level)
          level
          starLevelHistory = []
        }
        air = {
          units = mkUnits(level)
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
          air = {
            battle_end = battle_end_air
            win = rnd_int(0.45 * battle_end_air, 0.55 * battle_end_air)
          }
        }
      }
    }
  }

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
