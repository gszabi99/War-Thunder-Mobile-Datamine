from "%globalsDarg/darg_library.nut" import *
let { RANK, NAME, SHIP_RATING, TANKS_RATING, WP_RATING, AIR_RATING, KILL, KILL_SHIPS, KILL_TANKS, KILL_AIR,
  WIN, BATTLES, PRIZE, INDEX, LOG_TIME, WIN_SINGLE
} = require("lbCategory.nut")
let { lbTabIconSize } = require("lbStyle.nut")
let { ships, tanks, air } = require("%appGlobals/config/campaignPresentation.nut").campaignPresentations

let lbCfgOrdered = [
  {
    id = "ships"
    lbTable = "ships_event_leaderboard"
    gameMode = "ships"
    campaign = "ships"
    categories = [ RANK, NAME, SHIP_RATING, PRIZE, KILL_SHIPS, WIN, BATTLES ]
    battleCategories = [ INDEX, SHIP_RATING, KILL_SHIPS, WIN_SINGLE, LOG_TIME ]
    sortBy = SHIP_RATING
    icon = ships.icon
    iconSize = lbTabIconSize
    locId = ships.unitsLocId
  }
  {
    id = "tanks"
    lbTable = "tanks_event_leaderboard"
    gameMode = "tanks"
    campaign = "tanks"
    categories = [ RANK, NAME, TANKS_RATING, PRIZE, KILL_TANKS, WIN, BATTLES ]
    battleCategories = [ INDEX, TANKS_RATING, KILL_TANKS, WIN_SINGLE, LOG_TIME ]
    sortBy = TANKS_RATING
    icon = tanks.icon
    iconSize = lbTabIconSize
    locId = tanks.unitsLocId
  }
  {
    id = "air"
    lbTable = "air_event_leaderboard"
    gameMode = "air"
    campaign = "air"
    categories = [ RANK, NAME, AIR_RATING, PRIZE, KILL_AIR, WIN, BATTLES ]
    battleCategories = [ INDEX, AIR_RATING, KILL_AIR, WIN_SINGLE, LOG_TIME ]
    sortBy = AIR_RATING
    icon = air.icon
    iconSize = lbTabIconSize
    locId = air.unitsLocId
  }
  {
    id = "wp"
    gameMode = "battle_common"
    lbTable = "wp_event_leaderboard"
    categories = [ RANK, NAME, WP_RATING, PRIZE, KILL, WIN, BATTLES ]
    battleCategories = [ INDEX, WP_RATING, KILL, WIN_SINGLE, LOG_TIME ]
    sortBy = WP_RATING
    icon = "ui/gameuiskin#score_icon.svg"
    iconSize = lbTabIconSize
    locId = "lb/overall_rating"
  }
]

return {
  lbCfgOrdered
  lbCfgById = lbCfgOrdered.reduce(@(res, m) res.rawset(m.id, m), {})
}