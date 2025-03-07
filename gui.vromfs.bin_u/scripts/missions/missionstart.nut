from "%scripts/dagui_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let DataBlock  = require("DataBlock")
let { get_meta_mission_info_by_name, do_start_flight, select_mission } = require("guiMission")
let { actualizeBattleData } = require("%scripts/battleData/menuBattleData.nut")
let { requestHudState, changeTrainingUnit } = require("%scripts/missions/guiOptions.nut")

eventbus_subscribe("startSingleMission", function(msg) {
  let { id, unitName = null } = msg
  let mission = get_meta_mission_info_by_name(id)
  if (mission == null) {
    logerr($"Not found mission '{id}' to start")
    return
  }

  if (unitName != null)
    actualizeBattleData(unitName)

  requestHudState()
  let missionCopy = DataBlock()
  missionCopy.setFrom(mission)

  if (unitName != null) {
    missionCopy["modTutorial"] = true
    missionCopy["gt_training"] = false
    changeTrainingUnit(unitName)
  }

  log($"[OFFLINE_MISSION] startSingleMission {id} (unitName = {unitName})")
  select_mission(missionCopy, true)
  do_start_flight()
})
