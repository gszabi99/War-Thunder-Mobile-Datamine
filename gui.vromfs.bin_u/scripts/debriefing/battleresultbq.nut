from "%scripts/dagui_library.nut" import *
from "%globalScripts/ecs.nut" import *

let { eventbus_subscribe, eventbus_unsubscribe } = require("eventbus")
let { round } =  require("math")
let { EventOnSetupFrameTimes } = require("gameEvents")
let { get_mp_session_id_int } = require("multiplayer")
let { get_current_mission_name } = require("mission")
let { get_battery, get_battery_capacity_mah, is_charging, get_thermal_state, get_network_connection_type } = require("sysinfo")
let { get_emulator_system_flags, get_emulator_input_flags, get_emulated_input_count,
      get_regular_input_count, reset_emulator_counters} = require("emulatorDetection")
let { get_platform_string_id } = require("platform")
let { getCountryCode } = require("auth_wt")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { median } = require("%sqstd/math.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { blk2SquirrelObjNoArrays } = require("%sqstd/datablock.nut")
let { get_gui_option, addUserOption, addLocalUserOption } = require("guiOptions")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")
let { battleResult } = require("battleResult.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curQueue } = require("%appGlobals/queueState.nut")
let { clusterStats } = require("%scripts/matching/optimalClusters.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")

let OPT_GRAPHICS_QUALITY = addLocalUserOption("OPT_GRAPHICS_QUALITY")
let OPT_FPS = addLocalUserOption("OPT_FPS")
let OPT_TANK_MOVEMENT_CONTROL = addUserOption("OPT_TANK_MOVEMENT_CONTROL")

let lastCluster = hardPersistWatched("lastCluster", "")
curQueue.subscribe(@(v) (v?.joinedClusters ?? {}).len() == 0
  ? null
  : lastCluster(",".join(v.joinedClusters.keys())))

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
function onCollectPing() {
  let { ping = -1 } = deviceState.value
  if (ping == -1)
    return
  if (pingSamples.len() == PING_SAMPLES_MAX)
    pingSamples.remove(0)
  pingSamples.append(ping)
}
function activatePingMeasurement(isActivate, needReset) {
  if (needReset) {
    pingMin = -1
    pingMax = -1
    pingSamples.clear()
  }
  if (isActivate) {
    eventbus_subscribe("updateStatusString", updateDeviceState)
    setInterval(MEASURE_PING_INTERVAL_SEC, onCollectPing)
    onCollectPing()
  }
  else {
    eventbus_unsubscribe("updateStatusString", updateDeviceState)
    clearTimer(onCollectPing)
  }
}

local batteryOnBattleStart = 0

function startBatteryChargeDrainGather() {
  batteryOnBattleStart = get_battery()
}

isInBattle.subscribe(function(v) {
  activatePingMeasurement(v, v)
  if (v) {
    startBatteryChargeDrainGather()
    reset_emulator_counters()
  }
})

if (isInBattle.value) {
  activatePingMeasurement(true, false)
}

let connectionTypeMap = {
  [-1] = "Unknown",
  [0]  = "No connection" ,// Should be impossible (how do we send data then?)
  [1] =  "Cellular",
  [2] =  "Wi-Fi",
}

function onFrameTimes(evt, _eid, _comp) {
  log("[BQ] send battle fps info to BQ")
  let data = blk2SquirrelObjNoArrays(evt[0])
  data?.$rawdelete("time")

  let drainPercentage = batteryOnBattleStart - get_battery()
  let drainmAh = drainPercentage * get_battery_capacity_mah()

  let connectionType = connectionTypeMap?[get_network_connection_type()] ?? "Unknown"

  data.__update({
    platform = get_platform_string_id()
    country = getCountryCode()
    cluster = lastCluster.value
    clusters_rtt = ",".join(clusterStats.value.map(@(c)
      ":".join([ c.clusterId, c.hostsRTT == null ? null : round(c.hostsRTT).tointeger()], true)))
    campaign = battleCampaign.value != "" ? battleCampaign.value
      : (battleResult.value?.campaign ?? curCampaign.value ?? "")
    mission = get_current_mission_name()
    fpsLimit = get_gui_option(OPT_FPS)
    videoSetting = get_gui_option(OPT_GRAPHICS_QUALITY)
    sessionId = get_mp_session_id_int()
    tankMoveControlType = get_gui_option(OPT_TANK_MOVEMENT_CONTROL) ?? "stick_static"
    battery = get_battery()
    isCharging = is_charging()
    isEmulator = (get_emulator_system_flags() != 0)
    isEmulatedInput = (get_emulator_input_flags() != 0)
    isGamepad = isGamepad.get()
    emulatorSystemFlags = get_emulator_system_flags()
    emulatorInputFlags = get_emulator_input_flags()
    emulatedInputCount = get_emulated_input_count()
    regularInputCount = get_regular_input_count()
    batteryDrainPercentage = drainPercentage
    batteryDrainmAh = drainmAh
    thermalState = get_thermal_state()
    networkConnectionType = connectionType
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
