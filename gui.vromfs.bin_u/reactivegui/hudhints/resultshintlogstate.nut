from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { HUD_MSG_STREAK_EX } = require("hudMessages")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let state = require("%sqstd/mkEventLogState.nut")({
  persistId = "resultsHintLogState"
  maxActiveEvents = 3
  isEventsEqual = @(a, b) "id" in a ? a?.id == b?.id : a?.text == b?.text
})

eventbus_subscribe("HudMessage", function(data){
  if (data?.type == HUD_MSG_STREAK_EX) {
    let { unlockId = "" } = data
    state.addEvent(data.__merge({
      id = $"streak_{unlockId}"
      hType = "streak"
      ttl = 5
    }))
  }
})

isInBattle.subscribe(@(v) v ? state.clearEvents() : null)

return state