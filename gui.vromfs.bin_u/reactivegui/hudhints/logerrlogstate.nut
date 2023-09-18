from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let state = require("%sqstd/mkEventLogState.nut")({
  persistId = "logerrLogState"
  maxActiveEvents = 3
  defTtl = 30
  isEventsEqual = @(_, __) false
})
let { addEvent, clearEvents } = state

isInBattle.subscribe(@(_) clearEvents())

subscribe("dedicatedLogerr", @(data) addEvent({
  hType = "errorText"
  text = data.text
}))

return state