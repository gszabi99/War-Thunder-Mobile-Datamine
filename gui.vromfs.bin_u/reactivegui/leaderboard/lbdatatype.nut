from "%globalsDarg/darg_library.nut" import *
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")

let function makeType(params, id) {
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

let types = {
  NUM               = { getTextImpl = @(v) v.tointeger().tostring() }
  PLACE             = { getTextImpl = @(v) (v + 1).tostring() }
  RATING            = { getTextImpl = @(v) (0.01 * v + 0.5).tointeger() }

  NICKNAME = {
    getNotAvailableText = @(value) value ? null : "-"
    getTextImpl = @(value) getPlayerName(value.tostring())
  }
}.map(makeType)

return types
