from "%globalScripts/gameTypeConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
import "DataBlock" as DataBlock
from "console" import register_command
from "guiMission" import get_current_mission_desc
from "mission" import get_game_type, get_game_mode, GM_TRAINING
from "sceneEvents" import EventLevelLoaded
from "%sqstd/datablock.nut" import isDataBlock, eachParam
from "%globalScripts/ecs.nut" import register_es
import "%globalScripts/isAppLoaded.nut" as isAppLoaded
from "%appGlobals/clientState/missionState.nut" import hudCustomRules
import "%rGui/interopGen.nut" as interopGet


let gameType = Watched(get_game_type())
let gameMode = Watched(get_game_mode())

let missionStateInterop = {
  gameType
  gameOverReason = Watched(0)
  timeLeft = Watched(900)
  roundTimeLeft = Watched(900)
  scoreTeamA = Watched(0)
  scoreTeamB = Watched(0)
  ticketsTeamA = Watched(0)
  ticketsTeamB = Watched(0)
  localTeam = Watched(0)
  scoreLimit = Watched(0)
  deathPenaltyMul = Watched(1.0)
  ctaDeathTicketPenalty = Watched(1)
}
interopGet({
  stateTable = missionStateInterop
  prefix = "mission"
  postfix = "Update"
})

let raceForceCannotShoot = Watched(false)

function addSpawnScoreParams(rules, misBlk) {
  let { costs = null, spawn_pow = 1.0 } = misBlk?.customSpawnScore
  if (!isDataBlock(costs))
    return

  let spawnCost = {}
  rules.spawnCost <- spawnCost
  eachParam(costs, @(cost, name) spawnCost[name] <- cost)
  rules.spawnPow <- spawn_pow
}

function updateByMissionDesc() {
  if (!isAppLoaded.get())
    return
  gameMode.set(get_game_mode())

  log("Update hudCustomRules")
  let misBlk = DataBlock()
  get_current_mission_desc(misBlk)

  raceForceCannotShoot.set(misBlk?.raceForceCannotShoot)
  let { useSpawnScore = false } = misBlk
  let rules = {
    ctfFlagPreset = misBlk?.customRules.ctfFlagPreset ?? ""
    missionProgressType = misBlk?.missionProgressType ?? ""
    useKillStreaks = misBlk?.useKillStreaks ?? false
    allowSpare = misBlk?.allowSpare ?? true
    isUnlimRespawn = misBlk?.multiRespawn && misBlk?.maxRespawns == -1
    useSpawnScore
  }
  if (useSpawnScore)
    addSpawnScoreParams(rules, misBlk)

  hudCustomRules.set(rules)
}

updateByMissionDesc()
isAppLoaded.subscribe(@(_) updateByMissionDesc())

register_es("update_mission_desc_es",
  { [EventLevelLoaded] = @(_, __, ___) updateByMissionDesc() },
  {})

let isGtRace = Computed(@() !!(gameType.get() & GT_RACE))

let missionState = missionStateInterop.__merge({
  isGtFFA = Computed(@() !!(gameType.get() & (GT_FFA_DEATHMATCH | GT_FFA)))
  isGtBattleRoyale = Computed(@() !!(gameType.get() & GT_LAST_MAN_STANDING))
  isTutorial = Computed(@() (gameMode.get() == GM_TRAINING) && !(gameType.get() & GT_TRAINING))
  isGtRace
  notGtRace = Computed(@() !isGtRace.get())
  raceForceCannotShoot
})

register_command(function() {
  let misBlk = DataBlock()
  get_current_mission_desc(misBlk)
  console_print(misBlk?.customRules) 
}, "mission.getDescriptionCustomRules")

return missionState
