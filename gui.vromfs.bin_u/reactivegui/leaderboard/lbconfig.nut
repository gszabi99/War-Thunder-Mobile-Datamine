from "%globalsDarg/darg_library.nut" import *
let { RANK, NAME, SHIP_RATING, TANKS_RATING, WP_RATING, KILL, KILL_SHIPS, KILL_TANKS,
  WIN, BATTLES, PRIZE
} = require("lbCategory.nut")
let { ships, tanks } = require("%appGlobals/config/campaignPresentation.nut").campaignPresentations

let lbCfgOrdered = [
  {
    id = "ships"
    lbTable = "ships_event_leaderboard"
    gameMode = "ships"
    campaign = "ships"
    categories = [
      RANK, NAME, SHIP_RATING, PRIZE, KILL_SHIPS, WIN, BATTLES
    ]
    sortBy = SHIP_RATING
    icon = ships.icon
    locId = ships.unitsLocId
  }
  {
    id = "tanks"
    lbTable = "tanks_event_leaderboard"
    gameMode = "tanks"
    campaign = "tanks"
    categories = [
      RANK, NAME, TANKS_RATING, PRIZE, KILL_TANKS, WIN, BATTLES
    ]
    sortBy = TANKS_RATING
    icon = tanks.icon
    locId = tanks.unitsLocId
  }
  {
    id = "wp"
    gameMode = "battle_common"
    lbTable = "wp_event_leaderboard"
    categories = [
      RANK, NAME, WP_RATING, PRIZE, KILL, WIN, BATTLES
    ]
    sortBy = WP_RATING
    icon = "ui/gameuiskin#score_icon.svg"
    locId = "lb/overall_rating"
  }
]

return {
  lbCfgOrdered
  lbCfgById = lbCfgOrdered.reduce(@(res, m) res.rawset(m.id, m), {})
}