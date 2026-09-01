from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "eventbus" import eventbus_send
from "%globalScripts/debugTools/subscribeDedicLogerr.nut" import enableDedicLogerr, subscribeDedicLogerr
import "%globalScripts/ecs.nut" as ecs
from "%appGlobals/permissions.nut" import can_receive_dedic_logerr
from "%appGlobals/profileStates.nut" import myUserId
from "%appGlobals/util.nut" import is_multiplayer


let setEnableDedicLogger = @() enableDedicLogerr(true)

subscribeDedicLogerr(function(text) {
  log("Received dedicated logerr: ", text)
  eventbus_send("dedicatedLogerr", { text })
})

ecs.register_es("debug_dedic_logerrs_es",
  {
    [["onInit", "onChange"]] = function(_eid, comp) {
      if (can_receive_dedic_logerr.get() && is_multiplayer()
          && myUserId.get() == comp.server_player__userId)
        resetTimeout(1.0, setEnableDedicLogger) 
    },
  },
  {
    comps_ro = [["server_player__userId", ecs.TYPE_UINT64]]
    comps_track = [["unitSlots", ecs.TYPE_STRING_LIST]]
  })

