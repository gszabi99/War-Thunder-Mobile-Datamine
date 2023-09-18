from "%globalsDarg/darg_library.nut" import *
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let state = require("%sqstd/mkEventLogState.nut")({
  persistId = "warningHintLogState"
  maxActiveEvents = 2
  isEventsEqual = @(a, b) "id" in a ? a?.id == b?.id : a?.text == b?.text
})

isInBattle.subscribe(@(_) state.clearEvents())

return state