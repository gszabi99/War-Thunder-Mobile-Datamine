from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%rGui/hud/hudEventManager.nut" import subscribeHudEvent


const defaultTtl = 5

let state = require("%sqstd/mkEventLogState.nut")({
  persistId = "warningHintLogState"
  maxActiveEvents = 2
  isEventsEqual = @(a, b) "id" in a ? a?.id == b?.id : a?.text == b?.text
})

isInBattle.subscribe(@(_) state.clearEvents())

let { addEvent, removeEvent} = state
let addWarning = @(text, evId = "", ttl = 0, evType = "warningTextTiny") addEvent({ id = evId, hType = evType, text, ttl })

subscribeHudEvent("warn:visible_by_zone", function(data) {
  if (data?.isVisible)
    addWarning(data?.text ?? "", "warn:visible_by_zone")
  else
    removeEvent({id = "warn:visible_by_zone"})
})

subscribeHudEvent("warn:crit_speed", function(data) {
  if (data?.isVisible)
    addWarning(data?.text ?? "", "warn:crit_speed")
  else
    removeEvent({id = "warn:crit_speed"})
})

subscribeHudEvent("warn:stamina_loose_control", function(data) {
  if (data?.isVisible)
    addWarning(data?.text ?? "", "warn:stamina_loose_control")
  else
    removeEvent({id = "warn:stamina_loose_control"})
})

subscribeHudEvent("warn:crit_overload", function(data) {
  let overloadText = "".concat(loc("HUD_CRIT_OVERLOAD")," ", data?.val ?? "", loc("HUD_CRIT_OVERLOAD_G"))
  if (data?.isVisible)
    addWarning(overloadText, "warn:overload")
  else
    removeEvent({id = "warn:overload"})

})

subscribeHudEvent("warn:danger_overload", function(data) {
  let overloadText = "".concat(loc("HUD_DANGEROUS_OVERLOAD")," ", data?.val ?? "", loc("HUD_CRIT_OVERLOAD_G"))
  if (data?.isVisible)
    addWarning(overloadText, "warn:overload")
  else
    removeEvent({id = "warn:overload"})
})

let handleSimpleWarning = @(name, data) data?.isVisible
  ? addWarning(data?.text ?? "", "warn:net_unresponsive", defaultTtl)
  : removeEvent({id = name})

let simpleWarningEvents = [
  "warn:net_slow",
  "warn:net_unresponsive",
  "warn:crit_flaps",
  "warn:crit_gears",
  "warn:crit_airbrake",
  "warn:crit_flutter",
  "warn:high_engine_rpm",
  "warn:art_warning",
  "warn:missile_warning",
  "warn:gun_breech_malfunction",
  "warn:gun_barrel_malfunction",
  "warn:rocket_launcher_malfunction",
  "warn:crit_cockpit_door",
  "warn:set_takeoff_flaps_for_takeoff",
  "warn:owned_unit_dead",
]

foreach (ev in simpleWarningEvents) {
  let name = ev
  subscribeHudEvent(ev, @(data) handleSimpleWarning(name, data))
}


return state