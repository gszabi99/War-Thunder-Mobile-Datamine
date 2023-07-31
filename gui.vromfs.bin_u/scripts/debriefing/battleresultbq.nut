
from "%scripts/dagui_library.nut" import *
from "%globalScripts/ecs.nut" import *
let { subscribe, unsubscribe } = require("eventbus")
let { round } =  require("math")
let { get_default_graphics_preset, get_default_fps_limit } = require("graphicsOptions")
let { EventOnSetupFrameTimes } = require("gameEvents")
let { get_mp_session_id_int } = require("multiplayer")
let { get_current_mission_name } = require("mission")
let { get_battery, is_charging, get_thermal_state } = require("sysinfo")
let { get_platform_string_id } = require("platform")
let { getCountryCode } = require("auth_wt")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { median } = require("%sqstd/math.nut")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { blk2SquirrelObjNoArrays } = require("%sqstd/datablock.nut")
let { get_gui_option, addUserOption } = require("guiOptions")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")
let { battleResult } = require("battleResult.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curQueue } = require("%appGlobals/queueState.nut")
let { clusterStats } = require("%scripts/matching/optimalClusters.nut")

let OPT_GRAPHICS_QUALITY = addUserOption("OPT_GRAPHICS_QUALITY")
let OPT_FPS = addUserOption("OPT_FPS")
let OPT_TANK_MOVEMENT_CONTROL = addUserOption("OPT_TANK_MOVEMENT_CONTROL")

let curCluster = mkHardWatched("curCluster", "")
curQueue.subscribe(@(v) (v?.joinedClusters ?? {}).len() == 0 ? ""
  : curCluster(",".join(v.joinedClusters.keys())))

const MEASURE_PING_INTERVAL_SEC = 15
const PING_SAMPLES_MAX = 50
local pingMin = -1
local pingMax = -1
let pingSamples = persist("pingSamples", @() [])
let deviceState = Watched(null)
let updateDeviceState = @(state) deviceState(state)
deviceState.subscribe(function(v) {
  let { ping = -1 } = v
  if (ping == -1)
    return
  pingMin = pingMin == -1 ? ping : min(pingMin, ping)
  pingMax = max(pingMax, ping)
})
let function onCollectPing() {
  let { ping = -1 } = deviceState.value
  if (ping == -1)
    return
  if (pingSamples.len() == PING_SAMPLES_MAX)
    pingSamples.remove(0)
  pingSamples.append(ping)
}
let function activatePingMeasurement(isActivate, needReset) {
  if (needReset) {
    pingMin = -1
    pingMax = -1
    pingSamples.clear()
  }
  if (isActivate) {
    subscribe("updateStatusString", updateDeviceState)
    setInterval(MEASURE_PING_INTERVAL_SEC, onCollectPing)
    onCollectPing()
  }
  else {
    unsubscribe("updateStatusString", updateDeviceState)
    clearTimer(onCollectPing)
  }
}
isInBattle.subscribe(@(v) activatePingMeasurement(v, v))
if (isInBattle.value)
  activatePingMeasurement(true, false)

let function onFrameTimes(evt, _eid, _comp) {
  log("[BQ] send battle fps info to BQ")
  let data = blk2SquirrelObjNoArrays(evt[0])
  if ("time" in data)
    delete data.time

  data.__update({
    platform = get_platform_string_id()
    country = getCountryCode()
    cluster = curCluster.value
    clusters_rtt = ",".join(clusterStats.map(@(c)
      ":".join([ c.clusterId, c.hostsRTT == null ? null : round(c.hostsRTT).tointeger()], true)))
    campaign = battleCampaign.value != "" ? battleCampaign.value
      : (battleResult.value?.campaign ?? curCampaign.value ?? "")
    mission = get_current_mission_name()
    fpsLimit = get_gui_option(OPT_FPS) ?? get_default_fps_limit()
    videoSetting = get_gui_option(OPT_GRAPHICS_QUALITY) ?? get_default_graphics_preset()
    sessionId = get_mp_session_id_int()
    tankMoveControlType = get_gui_option(OPT_TANK_MOVEMENT_CONTROL) ?? "stick_static"
    battery = get_battery()
    isCharging = is_charging()
    thermalState = get_thermal_state()
    pingMin
    pingMax
    pingMedian = round(median((clone pingSamples).sort()) ?? -1).tointeger()
  })

  sendCustomBqEvent("session_fps", data)
}

register_es("frame_times_bq_es",
  {
    [EventOnSetupFrameTimes] = onFrameTimes,
  },
  {})
