from "%scripts/dagui_natives.nut" import hud_request_hud_ship_debuffs_state, hud_request_hud_tank_debuffs_state, hud_request_hud_crew_state
from "%scripts/dagui_library.nut" import *

let { eventbus_subscribe, eventbus_send } = require("eventbus")
let g_mislist_type = require("%scripts/missions/misListType.nut")
let { broadcastEvent } = require("%sqStdLibs/helpers/subscriptions.nut")
let { addOptionMode, setGuiOptionsMode, addUserOption, set_gui_option } = require("guiOptions")
let { actualizeBattleData } = require("%scripts/battleData/menuBattleData.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let DataBlock  = require("DataBlock")
let { get_meta_mission_info_by_name, do_start_flight, select_mission,
  select_training_mission
} = require("guiMission")
let { set_game_mode } = require("mission")

let TESTFLIGHT_MISSION = "testFlight_destroyer_usa_tfs"
let optModeTraining = addOptionMode("OPTIONS_MODE_TRAINING") //hardcoded in the native code
let optModeGameplay = addOptionMode("OPTIONS_MODE_GAMEPLAY") //hardcoded in the native code
let bulletOptions = array(BULLETS_SETS_QUANTITY).map(@(_, idx) {
  bulletOption = addUserOption($"USEROPT_BULLETS{idx}")
  bulletCountOption = addUserOption($"USEROPT_BULLET_COUNT{idx}")
})
let USEROPT_AIRCRAFT = addUserOption("USEROPT_AIRCRAFT")
let USEROPT_WEAPONS = addUserOption("USEROPT_WEAPONS")
let USEROPT_SKIN = addUserOption("USEROPT_SKIN")

function startOfflineMission(unitName, skin, missionId, bullets, localMP = false, gameMode = GM_TEST_FLIGHT
) {
  let misBlk = get_meta_mission_info_by_name(missionId)
  if (misBlk == null) {
    openFMsgBox({ text = "Mission not found." })
    return
  }

  if (unitName == "") {
    openFMsgBox({ text = "No showed unit. Select unit in ship window" })
    return
  }
  actualizeBattleData(unitName)

  hud_request_hud_tank_debuffs_state()
  hud_request_hud_crew_state()
  hud_request_hud_ship_debuffs_state()

  if (gameMode != null)
    misBlk["_gameMode"] = gameMode
  misBlk["difficulty"] = "arcade"
  misBlk["localMP"] = localMP

  setGuiOptionsMode(optModeTraining)
  set_gui_option(USEROPT_AIRCRAFT, unitName)
  set_gui_option(USEROPT_WEAPONS, $"{unitName}_default")
  set_gui_option(USEROPT_SKIN, skin)
  foreach (idx, opts in bulletOptions) {
    set_gui_option(opts.bulletOption, bullets?[idx].name ?? "")
    set_gui_option(opts.bulletCountOption, bullets?[idx].count ?? 0)
  }
  setGuiOptionsMode(optModeGameplay)
  foreach (idx, opts in bulletOptions) { //FIXME: we receive error from ative code when bad bullets in the OPTIONS_MODE_TRAINING, but bullets not apply when they not in current options mode
    set_gui_option(opts.bulletOption, bullets?[idx].name ?? "")
    set_gui_option(opts.bulletCountOption, bullets?[idx].count ?? 0)
  }

  broadcastEvent("BeforeStartCustomMission")
  select_training_mission(misBlk)
}

function openBenchmarkWnd(id) {
  set_game_mode(GM_BENCHMARK)
  g_mislist_type.BASE.requestMissionsList(function(list) {
    let mission = list.findvalue(@(m) m.id == id)
    if (mission == null)
      return
    let missionBlk = DataBlock()
    missionBlk.setFrom(mission.blk)
    select_mission(missionBlk, true)
    do_start_flight()
  })
}

function sendBenchmarksList(_) {
  set_game_mode(GM_BENCHMARK)
  g_mislist_type.BASE.requestMissionsList(@(list) eventbus_send("benchmarksList", {
        benchmarks = list.filter(@(m) !m?.isHeader)
          .map(@(m) { name = m.getNameText(), id = m.id })
      }))
}

eventbus_subscribe("startTestFlight", @(p)
  startOfflineMission(p.unitName, p.skin, p?.missionName ?? TESTFLIGHT_MISSION, p?.bullets))
eventbus_subscribe("startTraining", @(p)
  startOfflineMission(p.unitName, p.skin, p.missionName, p?.bullets, false, GM_TRAINING))
eventbus_subscribe("startLocalMP", @(p)
  startOfflineMission(p.unitName, p.skin, p.missionName, p?.bullets, true, GM_DOMINATION))
eventbus_subscribe("startBenchmark", @(v) openBenchmarkWnd(v.id))
eventbus_subscribe("getBenchmarksList", sendBenchmarksList)
