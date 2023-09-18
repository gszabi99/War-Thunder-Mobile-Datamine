
from "%scripts/dagui_library.nut" import *
let { subscribe } = require("eventbus")
let DataBlock  = require("DataBlock")
let { get_meta_mission_info_by_name, do_start_flight, select_mission
} = require("guiMission")

subscribe("startSingleMission", function(msg) {
  let { id } = msg
  let mission = get_meta_mission_info_by_name(id)
  if (mission == null) {
    logerr($"Not found mission '{id}' to start")
    return
  }

  ::hud_request_hud_tank_debuffs_state()
  ::hud_request_hud_crew_state()
  ::hud_request_hud_ship_debuffs_state()
  let missionCopy = DataBlock()
  missionCopy.setFrom(mission)
  select_mission(missionCopy, true)
  do_start_flight()
})
