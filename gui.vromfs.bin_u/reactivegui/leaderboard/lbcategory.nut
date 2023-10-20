from "%globalsDarg/darg_library.nut" import *
let { NUM, PLACE, NICKNAME, RATING } = require("lbDataType.nut")

let function makeType(params, id) {
  let { dataType = NUM, field = id.tolower()
  } = params
  let getValue = params?.getValue
    ?? function(rowData) {
        local res = rowData?[field]
        if (typeof res == "table")
          res = res?["value_total"]
        return res
      }
  return {
    id
    locId = ""
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
    relWidth = 0.8
  }

  NAME = {
    field = "name"
    dataType = NICKNAME
    locId = "multiplayer/name"
    relWidth = 2.0
  }

  SHIP_RATING = {
    field = "ships_rating"
    dataType = RATING
    locId = "lb/rating"
  }

  TANKS_RATING = {
    field = "tanks_rating"
    dataType = RATING
    locId = "lb/rating"
  }

  WP_RATING = {
    field = "wp_rating"
    dataType = RATING
    locId = "lb/rating"
  }

  WIN = {
    field = "win"
    dataType = RATING
    locId = "lb/wins"
  }

  KILL = {
    field = "kill"
    dataType = RATING
    locId = "debriefing/destroyed"
  }
}.map(makeType)

return categories
