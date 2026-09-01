from "%globalsDarg/darg_library.nut" import *
from "hudMessages" import HUD_MSG_STREAK_EX
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%rGui/hud/hudEventManager.nut" import subscribeHudEvent


let state = require("%sqstd/mkEventLogState.nut")({
  persistId = "resultsHintLogState"
  maxActiveEvents = 3
  isEventsEqual = @(a, b) "id" in a ? a?.id == b?.id : a?.text == b?.text
})

subscribeHudEvent("HudMessage", function(data){
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