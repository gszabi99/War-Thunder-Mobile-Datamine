from "%scripts/dagui_library.nut" import *
import "%sqstd/ecs.nut" as ecs
let { EventOnPlayerKill } = require("mPlayerEvents")
let { isInBattle, battleSessionId } = require("%appGlobals/clientState/clientState.nut")

let offlineKills = mkWatched(persist, "offlineKills", 0)
isInBattle.subscribe(@(v) v ? offlineKills(0) : null)

ecs.register_es("player_kill_counter_es", {
  [EventOnPlayerKill] = function(_evt, _eid, _comp) {
    if (battleSessionId.value == -1)
      offlineKills(offlineKills.value + 1)
  }
})

return {
  offlineKills
}