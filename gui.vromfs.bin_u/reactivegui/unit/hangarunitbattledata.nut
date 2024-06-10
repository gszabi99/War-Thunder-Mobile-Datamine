from "%globalsDarg/darg_library.nut" import *
import "%globalScripts/ecs.nut" as ecs
let { eventbus_subscribe } = require("eventbus")
let io = require("io")
let { object_to_json_string } = require("json")
let { register_command } = require("console")
let logBD = log_with_prefix("[HANGAR_BATTLE_DATA] ")
let { hangarUnit } = require("hangarUnit.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")


let battleDataQuery = ecs.SqQuery("hangarBattleDataQuery",
  {
    comps_ro = [["server_player__userId", ecs.TYPE_UINT64]]
    comps_rw = [["battleData", ecs.TYPE_OBJECT]]
  })


function setBattleDataToClientEcs(bd) {
  if (bd == null)
    return
  local isFound = false
  battleDataQuery(function(_, c) {
    if (c.server_player__userId != myUserId.value)
      return
    logBD("Set battle data to client entity")
    c.battleData = bd
    isFound = true
  })
  if (isFound)
    return

  ecs.g_entity_mgr.createEntity("wtm_server_player",
    {
      server_player__userId = [myUserId.value, ecs.TYPE_UINT64]
      isBattleDataReceived = true
      battleData = bd
    }, @(_e) logBD("Created wtm_server_player with battle data."))
}

function mkHangarBattleData() {
  if (hangarUnit.value == null)
    return null
  let { name, country = "", unitType = "", mods = null, modPreset = "",
    isUpgraded = false, isPremium = false
  } = hangarUnit.value

  let cfgMods = serverConfigs.value?.unitModPresets[modPreset] ?? {}
  let items = mods != null
      ? mods.filter(@(has, id) has && id in cfgMods)
          .map(@(_) 1)
    : isPremium || isUpgraded
      ? cfgMods.map(@(_) 1) //just all modifications, but later maybe filter them by groups
    : {}

  return {
    userId = myUserId.value
    items
    unit = {
      name
      country
      unitType
      isUpgraded
      isPremium = isPremium || isUpgraded
      weapons = {} //olnly default weapon atm
      attributes = {} //no need in the hangar
    }
  }
}

eventbus_subscribe("CreateBattleDataForHangar",
  @(_) setBattleDataToClientEcs(mkHangarBattleData()))

register_command(
  function() {
    const fileName = "wtmHangarBattleData.json"
    let file = io.file(fileName, "wt+")
    file.writestring(object_to_json_string(mkHangarBattleData(), true))
    file.close()
    log($"Saved json hangar battle data to {fileName}")
  }
  "meta.debugHangarBattleData")
