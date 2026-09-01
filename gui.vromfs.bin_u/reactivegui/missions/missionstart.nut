from "%globalsDarg/darg_library.nut" import *
import "DataBlock" as DataBlock
from "eventbus" import eventbus_subscribe
from "guiMission" import get_meta_mission_info_by_name, do_start_flight, select_mission
from "%rGui/battleData/menuBattleData.nut" import actualizeBattleData
from "%rGui/missions/guiOptions.nut" import requestHudState, changeTrainingUnit


eventbus_subscribe("startSingleMission", function(msg) {
  let { id, unitName = null, bullets = null } = msg
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
    changeTrainingUnit(unitName, "", bullets)
  }

  log($"[OFFLINE_MISSION] startSingleMission {id} (unitName = {unitName})")
  select_mission(missionCopy, true)
  do_start_flight()
})
