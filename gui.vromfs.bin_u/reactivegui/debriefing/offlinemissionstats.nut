from "%globalsDarg/darg_library.nut" import *
from "mPlayerEvents" import EventOnPlayerKill
from "unit" import get_unit_by_id
import "%sqstd/ecs.nut" as ecs
from "%appGlobals/clientState/clientState.nut" import isInBattle, battleSessionId


let offlineKills = mkWatched(persist, "offlineKills", 0)
let offlineKillsByUnit = mkWatched(persist, "offlineKillsByUnit", {})
isInBattle.subscribe(function(v) {
  if (!v)
    return
  offlineKills.set(0)
  offlineKillsByUnit.set({})
})

ecs.register_es("player_kill_counter_es", {
  [EventOnPlayerKill] = function(evt, _eid, _comp) {
    let [offenderPlayerId, offenderUnitId] = evt
    if (battleSessionId.get() == -1 && offenderPlayerId == 0) 
      offlineKills.set(offlineKills.get() + 1)

    let offenderUnit = get_unit_by_id(offenderUnitId)?.name
    if (offenderUnit)
      offlineKillsByUnit.mutate(@(v) v.$rawset(offenderUnit, (v?[offenderUnit] ?? 0) + 1))
  }
})

return {
  offlineKills
  offlineKillsByUnit
}