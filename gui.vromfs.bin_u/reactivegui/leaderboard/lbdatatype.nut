from "%globalsDarg/darg_library.nut" import *
from "%rGui/leaderboard/lbConst.nut" import *

function makeType(params, id) {
  let {
    getNotAvailableText = @(value) value == null || value < 0 ? loc("leaderboards/notAvailable") : null,
    getTextImpl = @(value) value.tostring()
  } = params
  let getText = params?.getText ?? @(value) this.getNotAvailableText(value) ?? this.getTextImpl(value)
  return params.__merge({
    id
    getNotAvailableText
    getTextImpl
    getText
  })
}

let resultLocIds = {
  [RESULT_DESERTER] = "debriefing/deserter",
  [RESULT_IN_PROGRESS] = "debriefing/inProgress",
  [RESULT_LOSE] = "debriefing/defeat",
  [RESULT_WIN] = "debriefing/victory",
}
let defResulLocId = resultLocIds[RESULT_LOSE]

let types = {
  NUM               = { getTextImpl = @(v) v.tointeger().tostring() }
  PLACE             = { getTextImpl = @(v) (v + 1).tostring() }
  RATING            = { getTextImpl = @(v) (0.01 * v + 0.5).tointeger() }
  WIN_TEXT          = { getTextImpl = @(v) loc(resultLocIds?[v] ?? defResulLocId) }

  NICKNAME = {
    getNotAvailableText = @(value) value ? null : "-"
  }
}.map(makeType)

return types
