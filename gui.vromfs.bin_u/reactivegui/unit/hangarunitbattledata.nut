from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
import "io" as io
from "json" import object_to_json_string
from "scriptRespondent" import registerRespondent
import "%globalScripts/ecs.nut" as ecs
from "%appGlobals/profileStates.nut" import myUserId
from "%rGui/unit/hangarUnit.nut" import hangarBattleData, lastHangarUnitBattleData


let logBD = log_with_prefix("[HANGAR_BATTLE_DATA] ")


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

  if (!isFound)
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
