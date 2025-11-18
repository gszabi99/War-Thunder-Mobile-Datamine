from "%globalsDarg/darg_library.nut" import *
import "%globalScripts/ecs.nut" as ecs
let { registerRespondent } = require("scriptRespondent")
let io = require("io")
let { object_to_json_string } = require("json")
let { register_command } = require("console")
let logBD = log_with_prefix("[HANGAR_BATTLE_DATA] ")
let { hangarBattleData, lastHangarUnitBattleData } = require("%rGui/unit/hangarUnit.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")


let battleDataQuery = ecs.SqQuery("hangarBattleDataQuery",
  {
    comps_ro = [["server_player__userId", ecs.TYPE_UINT64]]
    comps_rw = [["hangarBattleData", ecs.TYPE_OBJECT], ["isBattleDataReceived", ecs.TYPE_BOOL]]
  })


function setBattleDataToClientEcs(bd) {
  if (bd == null) {
    logBD("Ignore set battle data to client entity because it empty")
    return
  }
  local isFound = false
  battleDataQuery(function(_, c) {
    if (c.server_player__userId != myUserId.get())
      return
    logBD("Set battle data to client entity")
    c.hangarBattleData = bd
    c.isBattleDataReceived = true
    isFound = true
  })
  if (isFound)
    return

  ecs.g_entity_mgr.createEntity("hangar_battle_data",
    {
      server_player__userId = [myUserId.get(), ecs.TYPE_UINT64]
      isBattleDataReceived = true
      hangarBattleData = bd
    }, @(_e) logBD("Created wtm_server_player with battle data."))

  lastHangarUnitBattleData.set(bd)
}

registerRespondent("create_battle_data_for_hangar", @() setBattleDataToClientEcs(hangarBattleData.get()))

register_command(
  function() {
    const fileName = "wtmHangarBattleData.json"
    let file = io.file(fileName, "wt+")
    file.writestring(object_to_json_string(hangarBattleData.get(), true))
    file.close()
    log($"Saved json hangar battle data to {fileName}")
  }
  "meta.debugHangarBattleData")
