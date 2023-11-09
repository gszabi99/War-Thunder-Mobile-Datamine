from "%scripts/dagui_library.nut" import *
let { subscribe, send } = require("eventbus")
let { destroy_session } = require("multiplayer")
let { loadJson, saveJson } = require("%sqstd/json.nut")
let { register_command } = require("console")
let { resetTimeout } = require("dagor.workcycle")
let { needLogoutAfterSession, startLogout } = require("%scripts/login/logout.nut")
let { isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { battleResult, debugBattleResult } = require("battleResult.nut")
let loadRootScreen = require("%scripts/loadRootScreen.nut")
let { is_benchmark_game_mode, get_game_mode } = require("mission")
let { stat_get_benchmark } = require("guiMission")
let { locCurrentMissionName } = require("%scripts/missions/missionsUtils.nut")
let { hangar_enable_controls } = require("hangar")

::gui_start_debriefing <- function gui_start_debriefing() {
  if (needLogoutAfterSession.value) {
    destroy_session("on needLogoutAfterSession from gui_start_debriefing")
    //need delay after destroy session before is_multiplayer become false
    resetTimeout(0.3, startLogout)
    return
  }

  let gm = get_game_mode()
  if (is_benchmark_game_mode()) {
    let title = locCurrentMissionName()
    let stats = stat_get_benchmark()
    loadRootScreen()
    send("showBenchmarkResult", { title, stats })
    return
  }
  if (gm == GM_TEST_FLIGHT) {
     loadRootScreen()
     return
  }

  ::set_presence_to_player("menu")
  hangar_enable_controls(true)
  isInDebriefing(true)
}

let function closeDebriefing() {
  isInDebriefing(false)
  loadRootScreen()
}

let saveDebriefing = @(fileName) saveJson(fileName, battleResult.value)

let function loadDebriefing(fileName) {
  let data = loadJson(fileName)
  if (data == null)
    return console_print($"Can not load file {fileName}")

  debugBattleResult(data)
  //need delay here because sendBattleResult is delayed by 0.1 sec
  resetTimeout(0.2, @() isInDebriefing(true))
  return true
}

const SAVE_FILE = "wtmDebriefingData.json"
register_command(@() saveDebriefing(SAVE_FILE), "debriefing.debriefing_save")
register_command(@() loadDebriefing(SAVE_FILE), "debriefing.debriefing_load")
register_command(@(fileName) saveDebriefing(fileName), "debriefing.debriefing_save_by_name")
register_command(@(fileName) loadDebriefing(fileName), "debriefing.debriefing_load_by_name")

subscribe("Debriefing_CloseInDagui", @(_) closeDebriefing())
