from "%globalsDarg/darg_library.nut" import *
from "%rGui/leaderboard/lbConst.nut" import *
let { NUM, PLACE, NICKNAME, RATING, WIN_TEXT } = require("%rGui/leaderboard/lbDataType.nut")

function getRowValue(rowData, field) {
  local res = rowData?[field]
  if (typeof res == "table")
    res = res?["value_total"]
  return res
}

function makeType(params, id) {
  let { dataType = NUM, field = id.tolower()
  } = params
  let getValue = params?.getValue
    ?? @(rowData) getRowValue(rowData, field)
  return {
    id
    locId = ""
    hintLocId = ""
    icon = null
    relWidth = 1.0
    getText = @(rowData) dataType.getText(getValue(rowData))
  }.__update(
    params,
    { dataType, field, getValue }
  )
}

let categories = {
  RANK = {
    field = "idx"
    dataType = PLACE
    locId = "multiplayer/place"
    icon = "ui/gameuiskin#lb_place_icon.svg"
    relWidth = 0.8
  }

  NAME = {
    field = "name"
    dataType = NICKNAME
    relWidth = 2.0
    icon = "ui/gameuiskin#profile_avatar_icon.svg"
    locId = "player"
  }

  SHIP_RATING = {
    field = "ships_rating"
    dataType = RATING
    locId = "lb/rating"
    hintLocId = "lb/hint/ships/score"
    icon = "ui/gameuiskin#lb_rating_icon.svg"
    relWidth = 1.5
  }

  TANKS_RATING = {
    field = "tanks_rating"
    dataType = RATING
    locId = "lb/rating"
    hintLocId = "lb/hint/tanks/score"
    icon = "ui/gameuiskin#lb_rating_icon.svg"
    relWidth = 1.5
  }

  AIR_RATING = {
    field = "air_rating"
    dataType = RATING
    locId = "lb/rating"
    hintLocId = "lb/hint/tanks/score"
    icon = "ui/gameuiskin#lb_rating_icon.svg"
    relWidth = 1.5
  }

  WP_RATING = {
    field = "wp_rating"
    dataType = RATING
    locId = "lb/rating"
    hintLocId = "lb/hint/overall/score"
    icon = "ui/gameuiskin#lb_rating_icon.svg"
    relWidth = 1.5
  }

  WIN = {
    field = "win"
    dataType = NUM
    locId = "lb/wins"
    icon = "ui/gameuiskin#lb_victory_icon.svg"
  }

  WIN_SINGLE = {
    field = "win"
    dataType = WIN_TEXT
    locId = "lb/wins"
    icon = "ui/gameuiskin#lb_victory_icon.svg"
    function getValue(rowData) {
      let battles = getRowValue(rowData, "battles") ?? 0
      let win = getRowValue(rowData, "win") ?? 0
      let battle_end = getRowValue(rowData, "battle_end") ?? 0
      return battles == 0 ? RESULT_IN_PROGRESS
        : battle_end == 0 ? RESULT_DESERTER
        : win == 0 ? RESULT_LOSE
        : RESULT_WIN
    }
  }

  KILL = {
    field = "kill"
    dataType = NUM
    locId = "debriefing/destroyed"
    icon = "ui/gameuiskin#lb_kills_all_icon.svg"
  }

  KILL_SHIPS = {
    field = "kill"
    dataType = NUM
    locId = "debriefing/destroyed"
    icon = "ui/gameuiskin#ships_destroyed_icon.svg"
  }

  KILL_TANKS = {
    field = "kill"
    dataType = NUM
    locId = "debriefing/destroyed"
    icon = "ui/gameuiskin#tanks_destroyed_icon.svg"
  }

  KILL_AIR = {
    field = "kill"
    dataType = NUM
    locId = "debriefing/destroyed"
    icon = "ui/gameuiskin#air_destroyed_icon.svg"
  }

  BATTLES = {
    field = "profile_stat_battle_end"
    dataType = NUM
    locId = "lb/battles"
    icon = "ui/gameuiskin#lb_battles_icon.svg"
  }

  PRIZE = {
    field = "idx"
    dataType = PLACE
    locId = "lb/prize"
    icon = "ui/gameuiskin#lb_prize_icon.svg"
    relWidth = 0.8
  }

  INDEX = {
    field = "idx",
    dataType = PLACE,
    relWidth = 0.4
  }

  LOG_TIME = {
    icon = "ui/gameuiskin#lb_log_time.svg"
    locId = "lb/log_time"
    relWidth = 1.2
  }
}.map(makeType)

return categories
