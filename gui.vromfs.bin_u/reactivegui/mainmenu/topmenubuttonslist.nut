from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%sqstd/underscore.nut" import arrayByRows
from "%appGlobals/activeControls.nut" import isGamepad
from "%appGlobals/clientState/initialState.nut" import isOfflineMenu
from "%appGlobals/permissions.nut" import can_debug_configs, can_debug_missions, can_use_debug_console,
  can_view_replays, can_write_replays, has_offline_battle_access
from "%rGui/components/msgBox.nut" import openMsgBox
import "%rGui/controls/help/controlsHelpWnd.nut" as controlsHelpWnd
import "%rGui/debugTools/debugCommandsWnd.nut" as openDebugCommandsWnd
from "%rGui/debugTools/debugConfigsWnd.nut" import openDebugConfigWnd
from "%rGui/debugTools/debugProfileWnd.nut" import openDebugProfileWnd
import "%rGui/debugTools/debugQuirrelConsoleWnd.nut" as debugQuirrelConsoleWnd
import "%rGui/debugTools/debugShopWnd.nut" as debugShopWnd
from "%rGui/feedback/bugReport.nut" import openBugReport
import "%rGui/gameModes/debugGameModes.nut" as debugGameModes
from "%rGui/gameModes/offlineBattlesState.nut" import openOfflineBattleMenu
from "%rGui/gameModes/startOfflineMode.nut" import startTestFlight, startTestFlightByName
import "%rGui/mainMenu/chooseBenchmarkWnd.nut" as chooseBenchmarkWnd
from "%rGui/news/newsState.nut" import openNewsWnd, isFeedReceived
from "%rGui/options/accountOptionsScene.nut" import accountOptionsScene, setCurTabId
import "%rGui/options/optionsScene.nut" as optionsScene
from "%rGui/replay/lastReplayState.nut" import hasUnsavedReplay
import "%rGui/replay/saveReplayWindow.nut" as saveReplayWindow
import "%rGui/squad/notAvailableForSquadMsg.nut" as notAvailableForSquadMsg
from "%rGui/tutorial/tutorialMissions.nut" import startTutor, firstBattleTutor
from "%rGui/unit/hangarUnit.nut" import hangarUnit
from "%rGui/unlocks/loginAwardState.nut" import isLoginAwardOpened, canShowLoginAwards
from "%rGui/unlocks/userstat.nut" import isUserstatMissingData


const TF_SHIP_TUNE_MISSION = "testFlight_ship_tuning_tfs"
const TF_SHIP_VS_PLANES_MISSION = "testFlight_ship_aaa_vs_planes"
const TEST_AIR_BATTLE_MISSION = "abandoned_factory_single_AD"
const TEST_AIR_BATTLE_UNIT = "fw_190a_1"

const MAX_ROWS_COUNT = 11

let openConfirmationTutorialMsg = @() openMsgBox({
  text = loc("tutorial/startConfirmation")
  buttons = [
    { id = "cancel", isCancel = true }
    { id = "startTutorial", styleId = "PRIMARY", isDefault = true,
      cb = @() notAvailableForSquadMsg(@() startTutor(firstBattleTutor.get(), ""))
    }
  ]
})

function openReplaysPage() {
  setCurTabId("replays")
  accountOptionsScene()
}

eventbus_subscribe("showReplaysPage", @(_) openReplaysPage())

let OPTIONS = {
  name = loc("mainmenu/btnOptions")
  icon = "ui/gameuiskin#icon_menu_settings.svg"
  cb = optionsScene
}
let TEST_FLIGHT = {
  name = "Test Drive"
  cb = @() startTestFlight(hangarUnit.get())
}
let TF_SHIP_TUNE = {
  name = "Ship Tuning"
  cb = @() openMsgBox({
    text = "Select mission"
    buttons = [
      { text = "basic", styleId = "PRIMARY", cb = @() startTestFlight(hangarUnit.get(), TF_SHIP_TUNE_MISSION) }
      { text = "antiair", styleId = "PRIMARY", cb = @() startTestFlight(hangarUnit.get(), TF_SHIP_VS_PLANES_MISSION) }
      { id = "cancel", isCancel = true }
    ]
  })
}
let TEST_AIR_BATTLE = {
  name = "Test Air Battle"
  cb = @() startTestFlightByName(TEST_AIR_BATTLE_UNIT, TEST_AIR_BATTLE_MISSION)
}
let BENCHMARK = {
  name = loc("mainmenu/btnBenchmark")
  cb = @() notAvailableForSquadMsg(chooseBenchmarkWnd)
}
let REPLAYS = {
  name = loc("mainmenu/btnReplays")
  icon = "ui/gameuiskin#icon_menu_replay.svg"
  cb = openReplaysPage
}
let SAVE_LAST_REPLAY = {
  name = loc("mainmenu/btnSaveLastReplay")
  icon = "ui/gameuiskin#icon_menu_replay_save.svg"
  cb = saveReplayWindow
}
let GAMEPAD_HELP = {
  name = loc("flightmenu/btnControlsHelp")
  icon = "ui/gameuiskin#menu_game.svg"
  cb = controlsHelpWnd
}
let DEBUG_EVENTS = {
  name = "Debug Game Modes"
  cb = debugGameModes
}
let DEBUG_CONFIGS = {
  name = "Debug Configs"
  cb = openDebugConfigWnd
}
let DEBUG_PROFILE = {
  name = "Debug Profile"
  cb = openDebugProfileWnd
}
let DEBUG_COMMANDS = {
  name = "Debug Commands"
  cb = openDebugCommandsWnd
}
let DEBUG_QCONSOLE = {
  name = "Quirrel Console"
  cb = debugQuirrelConsoleWnd
}
let DEBUG_SHOP = {
  name = "Debug Shop"
  cb = debugShopWnd
}
let NEWS = {
  name = loc("mainmenu/btnNews")
  icon = "ui/gameuiskin#icon_menu_news.svg"
  cb = openNewsWnd
}
let LOGIN_AWARD = {
  name = loc("dailyRewards/header")
  icon = "ui/gameuiskin#icon_menu_daily.svg"
  cb = @() canShowLoginAwards.get() ? isLoginAwardOpened.set(true)
    : openMsgBox({ text = loc("error/serverTemporaryUnavailable") })
}
let BUG_REPORT = {
  name = loc("mainmenu/btnBugReport")
  icon = "ui/gameuiskin#icon_social_support.svg"
  cb = openBugReport
}
let TUTORIAL = {
  name = loc("mainmenu/btnTutorial")
  icon = "ui/gameuiskin#icon_menu_tutorial.svg"
  cb = openConfirmationTutorialMsg
}
let OFFLINE_BATTLES = {
  name = loc("mainmenu/offlineBattles")
  icon = "ui/gameuiskin#icon_minimap_attack.svg"
  cb = openOfflineBattleMenu
}

function getPublicButtons() {
  let res = [OPTIONS]
  if (isGamepad.get())
    res.append(GAMEPAD_HELP)
  if (isFeedReceived.get())
    res.append(NEWS)
  if (canShowLoginAwards.get() || isUserstatMissingData.get())
    res.append(LOGIN_AWARD)
  if (firstBattleTutor.get())
    res.append(TUTORIAL)
  if (can_view_replays.get())
    res.append(REPLAYS)
  if (can_write_replays.get() && hasUnsavedReplay.get())
    res.append(SAVE_LAST_REPLAY)
  if (has_offline_battle_access.get())
    res.append(OFFLINE_BATTLES)
  res.append(BUG_REPORT)
  return res
}

function getDevButtons() {
  let res = []
  if (!can_debug_configs.get() && !can_debug_missions.get())
    return res

  if (can_debug_missions.get())
    res.append(TEST_FLIGHT, TF_SHIP_TUNE, TEST_AIR_BATTLE, BENCHMARK, DEBUG_EVENTS)
  else if (isOfflineMenu)
    res.append(TEST_FLIGHT, BENCHMARK)
  if (can_debug_configs.get())
    res.append(DEBUG_CONFIGS, DEBUG_PROFILE, DEBUG_SHOP)
  if (can_use_debug_console.get())
    res.append(DEBUG_QCONSOLE, DEBUG_COMMANDS)
  return res.filter(@(v) v != null)
}

let getTopMenuButtons = @() []
  .extend(arrayByRows(getPublicButtons(), MAX_ROWS_COUNT).map(@(columns) columns),
    arrayByRows(getDevButtons(), MAX_ROWS_COUNT).map(@(columns) columns))

let topMenuButtonsGenId = Computed(function(prev) {
  let vals = [   
    can_debug_missions, can_debug_configs, can_use_debug_console, isGamepad,
    isFeedReceived, firstBattleTutor, canShowLoginAwards, isUserstatMissingData,
    can_view_replays, can_write_replays, hasUnsavedReplay, has_offline_battle_access
  ]
  return prev == FRP_INITIAL ? 0 : prev + 1
})

return {
  getTopMenuButtons
  topMenuButtonsGenId
}
