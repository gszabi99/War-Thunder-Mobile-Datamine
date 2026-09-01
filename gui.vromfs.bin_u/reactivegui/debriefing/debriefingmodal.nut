from "%globalScripts/gameModeNativeConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.fs" import file_exists
from "dagor.time" import get_local_unixtime, unixtime_to_local_timetbl
from "dagor.workcycle" import resetTimeout
from "eventbus" import eventbus_subscribe, eventbus_send
from "guiMission" import stat_get_benchmark
from "json" import object_to_json_string
from "mission" import is_benchmark_game_mode, get_game_mode
from "multiplayer" import destroy_session
from "replays" import is_replay_playing
from "string" import format
from "%sqstd/json.nut" import loadJson, saveJson
from "%appGlobals/clientState/clientState.nut" import isInDebriefing, isInBattle
from "%appGlobals/openForeignMsgBox.nut" import subscribeFMsgBtns, openFMsgBox
from "%appGlobals/loginState.nut" import needLogoutAfterSession
import "%appGlobals/clientState/updateClientStates.nut" as updateClientStates
from "%rGui/missions/missionsUtils.nut" import locCurrentMissionName
from "battleResult.nut" import battleResult, debugBattleResult


let startLogout = @() eventbus_send("logOut", {})


let needRedirectToReplaysPage = mkWatched(persist, "needRedirectToReplaysPage", false)
isInBattle.subscribe(@(v) v ? needRedirectToReplaysPage.set(is_replay_playing()) : null)

eventbus_subscribe("gui_start_debriefing", function gui_start_debriefing(...) {
  if (needLogoutAfterSession.get()) {
    destroy_session("on needLogoutAfterSession from gui_start_debriefing")
    
    resetTimeout(0.3, startLogout)
    return
  }

  let gm = get_game_mode()
  if (is_benchmark_game_mode()) {
    let title = locCurrentMissionName()
    let stats = stat_get_benchmark()
    updateClientStates()
    eventbus_send("showBenchmarkResult", { title, stats })
    return
  }
  if (gm == GM_TEST_FLIGHT) {
    updateClientStates()
    return
  }
  if (needRedirectToReplaysPage.get()) {
    eventbus_send("showReplaysPage", {})
    needRedirectToReplaysPage.set(false)
    return
  }

  isInDebriefing.set(true)
})

function closeDebriefing() {
  isInDebriefing.set(false)
  updateClientStates()
}

subscribeFMsgBtns({
  debrSaveOverwrite = @(fileName) saveJson(fileName, battleResult.get(), { logger = log })
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
    return log($"Can not load file {fileName}")

  debugBattleResult.set(data)
  
  resetTimeout(0.2, @() isInDebriefing.set(true))
  log($"Loaded {fileName}")
}

function printDebriefing() {
  if (battleResult.get() == null)
    return log("No debriefing data to print")
  log("Debriefing data:\n", object_to_json_string(battleResult.get(), true))
}

function getTimestampStr() {
  let t = unixtime_to_local_timetbl(get_local_unixtime())
  return format("%02d%02d%02d_%02d%02d%02d", t.year, t.month + 1, t.day, t.hour, t.min, t.sec)
}

const SAVE_FILE = "wtmDebriefingData.json"
register_command(@() saveDebriefing(SAVE_FILE), "debriefing.debriefing_save")
register_command(@() loadDebriefing(SAVE_FILE), "debriefing.debriefing_load")
register_command(@(fileName) saveDebriefing(fileName), "debriefing.debriefing_save_by_name")
register_command(@(fileName) loadDebriefing(fileName), "debriefing.debriefing_load_by_name")
register_command(@() saveDebriefing($"wtmDebriefingData_{getTimestampStr()}.json"), "debriefing.debriefing_save_with_timestamp")
register_command(printDebriefing, "debriefing.print_console")

eventbus_subscribe("Debriefing_CloseInDagui", @(_) closeDebriefing())
