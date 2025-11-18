from "%globalsDarg/darg_library.nut" import *
import "%globalScripts/ecs.nut" as ecs
let { setInterval, clearTimer } = require("dagor.workcycle")
let { CmdActionInRespawn } = require("dasevents")
let { register_command } = require("console")
let { debounce } = require("%sqstd/timers.nut")
let { isInRespawn } = require("%appGlobals/clientState/respawnStateBase.nut")

let find_local_player_respawn_query = ecs.SqQuery("find_local_player_respawn_query",
  { comps_rq = ["localPlayer"] })
let local_player_eid = @() find_local_player_respawn_query(@(eid, _) eid) ?? ecs.INVALID_ENTITY_ID

let sendPlayerActivityToServer = debounce(function() {
  let eid = local_player_eid()
  if (eid != ecs.INVALID_ENTITY_ID && isInRespawn.get())
    ecs.g_entity_mgr.sendEvent(local_player_eid(), CmdActionInRespawn({}))
}, 2)

let isDebugActive = persist("isDebugActive", @() Watched(false))

if(isDebugActive.get())
  setInterval(10.0, sendPlayerActivityToServer)

function blockInactivityKickToggle() {
  isDebugActive.set(!isDebugActive.get())
  log("Block inactivity kick from respawn: ", isDebugActive.get())

  if (isDebugActive.get())
    setInterval(10.0, sendPlayerActivityToServer)
  else
    clearTimer(sendPlayerActivityToServer)
}

register_command(blockInactivityKickToggle, "debug.block_inactivity_kick_from_respawn")

return { sendPlayerActivityToServer }