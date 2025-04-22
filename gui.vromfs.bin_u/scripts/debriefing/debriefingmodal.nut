from "%scripts/dagui_natives.nut" import set_presence_to_player
from "%scripts/dagui_library.nut" import *
let { format } = require("string")
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { destroy_session } = require("multiplayer")
let { loadJson, saveJson } = require("%sqstd/json.nut")
let { register_command } = require("console")
let { file_exists } = require("dagor.fs")
let { resetTimeout } = require("dagor.workcycle")
let { get_local_unixtime, unixtime_to_local_timetbl } = require("dagor.time")
let { needLogoutAfterSession, startLogout } = require("%scripts/login/loginStart.nut")
let { isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { battleResult, debugBattleResult } = require("battleResult.nut")
let loadRootScreen = require("%scripts/loadRootScreen.nut")
let { is_benchmark_game_mode, get_game_mode } = require("mission")
let { stat_get_benchmark } = require("guiMission")
let { locCurrentMissionName } = require("%scripts/missions/missionsUtils.nut")

eventbus_subscribe("gui_start_debriefing", function gui_start_debriefing(...) {
  if (needLogoutAfterSession.value) {
    destroy_session("on needLogoutAfterSession from gui_start_debriefing")
    
    resetTimeout(0.3, startLogout)
    return
  }

  let gm = get_game_mode()
  if (is_benchmark_game_mode()) {
    let title = locCurrentMissionName()
    let stats = stat_get_benchmark()
    loadRootScreen()
    eventbus_send("showBenchmarkResult", { title, stats })
    return
  }
  if (gm == GM_TEST_FLIGHT) {
     loadRootScreen()
     return
  }

  set_presence_to_player("menu")
  isInDebriefing(true)
})

function closeDebriefing() {
  isInDebriefing(false)
  loadRootScreen()
}

subscribeFMsgBtns({
  debrSaveOverwrite = @(fileName) saveJson(fileName, battleResult.get(), { logger = console_print })
})

function saveDebriefing(fileName) {
  if (!file_exists(fileName))
    return saveJson(fileName, battleResult.get())
  openFMsgBox({
    text = $"File already exists:\n{fileName}\nOverwrite?"
    buttons = [
      { id = "cancel", isCancel = true, styleId = "PRIMARY" }
      { text = "Overwrite", eventId = "debrSaveOverwrite", context = fileName }
    ]
  })
}

function loadDebriefing(fileName) {
  let data = loadJson(fileName)
  if (data == null)
    return console_print($"Can not load file {fileName}")

  debugBattleResult(data)
  
  resetTimeout(0.2, @() isInDebriefing(true))
  return true
}

let function getTimestampStr() {
  let t = unixtime_to_local_timetbl(get_local_unixtime())
  return format("%02d%02d%02d_%02d%02d%02d", t.year, t.month + 1, t.day, t.hour, t.min, t.sec)
}

const SAVE_FILE = "wtmDebriefingData.json"
register_command(@() saveDebriefing(SAVE_FILE), "debriefing.debriefing_save")
register_command(@() loadDebriefing(SAVE_FILE), "debriefing.debriefing_load")
register_command(@(fileName) saveDebriefing(fileName), "debriefing.debriefing_save_by_name")
register_command(@(fileName) loadDebriefing(fileName), "debriefing.debriefing_load_by_name")
register_command(@() saveDebriefing($"wtmDebriefingData_{getTimestampStr()}.json"), "debriefing.debriefing_save_with_timestamp")

eventbus_subscribe("Debriefing_CloseInDagui", @(_) closeDebriefing())
