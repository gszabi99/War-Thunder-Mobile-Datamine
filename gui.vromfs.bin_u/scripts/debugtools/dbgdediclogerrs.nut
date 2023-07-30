from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

import "%globalScripts/ecs.nut" as ecs
let { send } = require("eventbus")
let { can_receive_dedic_logerr } = require("%appGlobals/permissions.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { enableDedicLogerr, subscribeDedicLogerr
} = require("%globalScripts/debugTools/subscribeDedicLogerr.nut")
let { setTimeout } = require("dagor.workcycle")

subscribeDedicLogerr(function(text) {
  log("Received dedicated logerr: ", text)
  send("dedicatedLogerr", { text })
})

ecs.register_es("debug_dedic_logerrs_es",
  {
    [["onInit", "onChange"]] = function(_eid, comp) {
      if (can_receive_dedic_logerr.value && ::is_multiplayer() //this global function is only one reason to this module be in dagui VM
          && myUserId.value == comp.server_player__userId)
        setTimeout(1.0, @() enableDedicLogerr(true)) //without timeout this event can reach dedicated before it create m_player entity
    },
  },
  {
    comps_ro = [["server_player__userId", ecs.TYPE_UINT64]]
    comps_track = [["unitSlots", ecs.TYPE_STRING_LIST]]
  })

