//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
from "%globalScripts/ecs.nut" import *
let { get_default_graphics_preset, get_default_fps_limit } = require("graphicsOptions")
let { EventOnSetupFrameTimes } = require("gameEvents")
let { get_mp_session_id_int } = require("multiplayer")
let { get_current_mission_name } = require("mission")
let { get_battery, is_charging, get_thermal_state } = require("sysinfo")
let { get_platform_string_id } = require("platform")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { blk2SquirrelObjNoArrays } = require("%sqstd/datablock.nut")
let { get_gui_option, addUserOption } = require("guiOptions")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")
let { battleResult } = require("battleResult.nut")

let OPT_GRAPHICS_QUALITY = addUserOption("OPT_GRAPHICS_QUALITY")
let OPT_FPS = addUserOption("OPT_FPS")
let OPT_TANK_MOVEMENT_CONTROL = addUserOption("OPT_TANK_MOVEMENT_CONTROL")

let function onFrameTimes(evt, _eid, _comp) {
  log("[BQ] send battle fps info to BQ")
  let data = blk2SquirrelObjNoArrays(evt[0])
  if ("time" in data)
    delete data.time
  data.__update({
    platform = get_platform_string_id()
    campaign = battleCampaign.value ?? battleResult.value?.campaign ?? ""
    mission = get_current_mission_name()
    fpsLimit = get_gui_option(OPT_FPS) ?? get_default_fps_limit()
    videoSetting = get_gui_option(OPT_GRAPHICS_QUALITY) ?? get_default_graphics_preset()
    sessionId = get_mp_session_id_int()
    tankMoveControlType = get_gui_option(OPT_TANK_MOVEMENT_CONTROL) ?? "stick"
    battery = get_battery()
    isCharging = is_charging()
    thermalState = get_thermal_state()
  })
  sendCustomBqEvent("session_fps", data)
}

register_es("frame_times_bq_es",
  {
    [EventOnSetupFrameTimes] = onFrameTimes,
  },
  {})
