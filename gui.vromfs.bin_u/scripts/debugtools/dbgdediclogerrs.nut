from "%scripts/dagui_library.nut" import *

import "%globalScripts/ecs.nut" as ecs
let { eventbus_send } = require("eventbus")
let { is_multiplayer } = require("%scripts/util.nut")
let { can_receive_dedic_logerr } = require("%appGlobals/permissions.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { enableDedicLogerr, subscribeDedicLogerr
} = require("%globalScripts/debugTools/subscribeDedicLogerr.nut")
let { resetTimeout } = require("dagor.workcycle")

subscribeDedicLogerr(function(text) {
  log("Received dedicated logerr: ", text)
  eventbus_send("dedicatedLogerr", { text })
})

ecs.register_es("debug_dedic_logerrs_es",
  {
    [["onInit", "onChange"]] = function(_eid, comp) {
      if (can_receive_dedic_logerr.get() && is_multiplayer() 
          && myUserId.get() == comp.server_player__userId)
        resetTimeout(1.0, @() enableDedicLogerr(true)) 
    },
  },
  {
    comps_ro = [["server_player__userId", ecs.TYPE_UINT64]]
    comps_track = [["unitSlots", ecs.TYPE_STRING_LIST]]
  })

