from "%globalsDarg/darg_library.nut" import *
let { get_game_type } = require("mission")
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

let isGtFFA = Computed(@() !!(gameType.get() & (GT_FFA_DEATHMATCH | GT_FFA)))
let isGtBattleRoyale = Computed(@() !!(gameType.get() & GT_FFA))
let isGtLastManStanding = Computed(@() (gameType.get() & GT_LAST_MAN_STANDING))

let missionState = missionStateInterop.__merge({
  isGtFFA
  isGtBattleRoyale
  isGtLastManStanding
})

return missionState
