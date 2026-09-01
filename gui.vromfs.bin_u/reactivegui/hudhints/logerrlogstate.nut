from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%appGlobals/clientState/clientState.nut" import isInBattle


let state = require("%sqstd/mkEventLogState.nut")({
  persistId = "logerrLogState"
  maxActiveEvents = 3
  defTtl = 30
  isEventsEqual = @(_, __) false
})
let { addEvent, clearEvents } = state

isInBattle.subscribe(@(_) clearEvents())

eventbus_subscribe("dedicatedLogerr", @(data) addEvent({
  hType = "errorText"
  text = data.text
}))

return state