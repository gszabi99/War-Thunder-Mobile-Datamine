from "%globalsDarg/darg_library.nut" import *

let state = require("%sqstd/mkEventLogState.nut")({
  persistId = "warningHintLogState"
  maxActiveEvents = 2
  isEventsEqual = @(a, b) "id" in a ? a?.id == b?.id : a?.text == b?.text
})

return state