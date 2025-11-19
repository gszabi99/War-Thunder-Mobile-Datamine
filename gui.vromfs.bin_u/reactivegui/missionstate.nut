from "%globalsDarg/darg_library.nut" import *
let DataBlock  = require("DataBlock")
let { get_game_type } = require("mission")
let { get_current_mission_desc } = require("guiMission")
let isAppLoaded = require("%globalScripts/isAppLoaded.nut")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let interopGet = require("%rGui/interopGen.nut")

let gameType = Watched(get_game_type())

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

function updateRaceForceCannotShoot() {
  if (!isAppLoaded.get())
    return
  let misBlk = DataBlock()
  get_current_mission_desc(misBlk)
  raceForceCannotShoot.set(misBlk?.raceForceCannotShoot)
}

updateRaceForceCannotShoot()
isInLoadingScreen.subscribe(@(v) !v ? updateRaceForceCannotShoot() : null)
isAppLoaded.subscribe(@(_) updateRaceForceCannotShoot())

let isGtRace = Computed(@() !!(gameType.get() & GT_RACE))

let missionState = missionStateInterop.__merge({
  isGtFFA = Computed(@() !!(gameType.get() & (GT_FFA_DEATHMATCH | GT_FFA)))
  isGtBattleRoyale = Computed(@() !!(gameType.get() & GT_LAST_MAN_STANDING))
  isGtRace
  notGtRace = Computed(@() !isGtRace.get())
  raceForceCannotShoot
})

return missionState
