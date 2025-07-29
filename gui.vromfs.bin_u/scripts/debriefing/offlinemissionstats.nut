from "%scripts/dagui_library.nut" import *
import "%sqstd/ecs.nut" as ecs
let { EventOnPlayerKill } = require("mPlayerEvents")
let { isInBattle, battleSessionId } = require("%appGlobals/clientState/clientState.nut")

let offlineKills = mkWatched(persist, "offlineKills", 0)
isInBattle.subscribe(@(v) v ? offlineKills(0) : null)

ecs.register_es("player_kill_counter_es", {
  [EventOnPlayerKill] = function(evt, _eid, _comp) {
    let offenderPlayerId = evt[0]
    if (battleSessionId.get() == -1 && offenderPlayerId == 0) 
      offlineKills(offlineKills.value + 1)
  }
})

return {
  offlineKills
}