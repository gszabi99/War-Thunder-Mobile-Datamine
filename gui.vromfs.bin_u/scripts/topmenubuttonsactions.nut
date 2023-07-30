//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { subscribe, send } = require("eventbus")
let { addOptionMode, setGuiOptionsMode, addUserOption, set_gui_option } = require("guiOptions")
let { actualizeBattleData } = require("%scripts/battleData/menuBattleData.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let DataBlock  = require("DataBlock")
let { get_meta_mission_info_by_name, do_start_flight, select_mission,
  select_training_mission
} = require("guiMission")
let { set_game_mode } = require("mission")

let TESTFLIGHT_MISSION = "testFlight_destroyer_usa_tfs"
let TF_SHIP_TUNE_MISSION = "testFlight_ship_tuning_tfs"
let optModeTraining = addOptionMode("OPTIONS_MODE_TRAINING") //hardcoded in the native code
let optModeGameplay = addOptionMode("OPTIONS_MODE_GAMEPLAY") //hardcoded in the native code
let bulletOptions = array(BULLETS_SETS_QUANTITY).map(@(_, idx) {
  bulletOption = addUserOption($"USEROPT_BULLETS{idx}")
  bulletCountOption = addUserOption($"USEROPT_BULLET_COUNT{idx}")
})
let USEROPT_AIRCRAFT = addUserOption("USEROPT_AIRCRAFT")
let USEROPT_WEAPONS = addUserOption("USEROPT_WEAPONS")
let USEROPT_SKIN = addUserOption("USEROPT_SKIN")

let function startTestFlight(unitName, testFlightName = TESTFLIGHT_MISSION, bullets = null) {
  let misBlk = get_meta_mission_info_by_name(testFlightName)
  if (misBlk == null) {
    openFMsgBox({ text = "Mission not found." })
    return
  }

  if (unitName == "") {
    openFMsgBox({ text = "No showed unit. Select unit in ship window" })
    return
  }
  actualizeBattleData(unitName)

  misBlk["_gameMode"] = GM_TEST_FLIGHT
  misBlk["difficulty"] = "arcade"

  setGuiOptionsMode(optModeTraining)
  set_gui_option(USEROPT_AIRCRAFT, unitName)
  set_gui_option(USEROPT_WEAPONS, $"{unitName}_default")
  set_gui_option(USEROPT_SKIN, "default")
  foreach (idx, opts in bulletOptions) {
    set_gui_option(opts.bulletOption, bullets?[idx].name ?? "")
    set_gui_option(opts.bulletCountOption, bullets?[idx].count ?? 0)
  }
  setGuiOptionsMode(optModeGameplay)
  foreach (idx, opts in bulletOptions) { //FIXME: we receive error from ative code when bad bullets in the OPTIONS_MODE_TRAINING, but bullets not apply when they not in current options mode
    set_gui_option(opts.bulletOption, bullets?[idx].name ?? "")
    set_gui_option(opts.bulletCountOption, bullets?[idx].count ?? 0)
  }

  ::broadcastEvent("BeforeStartCustomMission")
  select_training_mission(misBlk)
}

let function openBenchmarkWnd(id) {
  set_game_mode(GM_BENCHMARK)
  ::g_mislist_type.BASE.requestMissionsList(function(list) {
    let mission = list.findvalue(@(m) m.id == id)
    if (mission == null)
      return
    let missionBlk = DataBlock()
    missionBlk.setFrom(mission.blk)
    select_mission(missionBlk, true)
    do_start_flight()
  })
}

let function sendBenchmarksList(_) {
  set_game_mode(GM_BENCHMARK)
  ::g_mislist_type.BASE.requestMissionsList(@(list) send("benchmarksList", {
        benchmarks = list.filter(@(m) !m.isHeader)
          .map(@(m) { name = m.getNameText(), id = m.id })
      }))
}

subscribe("startTestFlight", @(params) startTestFlight(params.unitName, params?.missionName ?? TESTFLIGHT_MISSION, params?.bullets))
subscribe("startBenchmark", @(v) openBenchmarkWnd(v.id))
subscribe("getBenchmarksList", sendBenchmarksList)

return {
  startTestFlight
  TF_SHIP_TUNE_MISSION
}
