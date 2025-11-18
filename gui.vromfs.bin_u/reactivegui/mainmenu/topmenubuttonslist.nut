from "%globalsDarg/darg_library.nut" import *
let { arrayByRows } = require("%sqstd/underscore.nut")
let { can_debug_configs, can_debug_missions, can_use_debug_console, can_view_replays, can_write_replays,
  has_offline_battle_access
} = require("%appGlobals/permissions.nut")
let { openDebugProfileWnd } = require("%rGui/debugTools/debugProfileWnd.nut")
let { openDebugConfigWnd } = require("%rGui/debugTools/debugConfigsWnd.nut")
let debugShopWnd = require("%rGui/debugTools/debugShopWnd.nut")
let openDebugCommandsWnd = require("%rGui/debugTools/debugCommandsWnd.nut")
let debugQuirrelConsoleWnd = require("%rGui/debugTools/debugQuirrelConsoleWnd.nut")
let optionsScene = require("%rGui/options/optionsScene.nut")
let debugGameModes = require("%rGui/gameModes/debugGameModes.nut")
let chooseBenchmarkWnd = require("%rGui/mainMenu/chooseBenchmarkWnd.nut")
let replaysWnd = require("%rGui/replay/replaysWnd.nut")
let { hasUnsavedReplay } = require("%rGui/replay/lastReplayState.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let controlsHelpWnd = require("%rGui/controls/help/controlsHelpWnd.nut")
let { openNewsWnd, isFeedReceived } = require("%rGui/news/newsState.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { startTestFlight, startTestFlightByName } = require("%rGui/gameModes/startOfflineMode.nut")
let { isLoginAwardOpened, canShowLoginAwards } = require("%rGui/unlocks/loginAwardState.nut")
let { isUserstatMissingData } = require("%rGui/unlocks/userstat.nut")
let { startTutor, firstBattleTutor } = require("%rGui/tutorial/tutorialMissions.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let saveReplayWindow = require("%rGui/replay/saveReplayWindow.nut")
let notAvailableForSquadMsg = require("%rGui/squad/notAvailableForSquadMsg.nut")
let { openBugReport } = require("%rGui/feedback/bugReport.nut")
let { openOfflineBattleMenu } = require("%rGui/gameModes/offlineBattlesState.nut")


let TF_SHIP_TUNE_MISSION = "testFlight_ship_tuning_tfs"
let TF_SHIP_VS_PLANES_MISSION = "testFlight_ship_aaa_vs_planes"
let TEST_AIR_BATTLE_MISSION = "abandoned_factory_single_AD"
let TEST_AIR_BATTLE_UNIT = "fw_190a_1"

let MAX_ROWS_COUNT = 10

let openConfirmationTutorialMsg = @() openMsgBox({
  text = loc("tutorial/startConfirmation")
  buttons = [
    { id = "cancel", isCancel = true }
    { id = "startTutorial", styleId = "PRIMARY", isDefault = true,
      cb = @() notAvailableForSquadMsg(@() startTutor(firstBattleTutor.get(), ""))
    }
  ]
})

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
  icon = "ui/gameuiskin#watch_ads.svg"
  cb = @() notAvailableForSquadMsg(replaysWnd)
}
let SAVE_LAST_REPLAY = {
  name = loc("mainmenu/btnSaveReplay")
  icon = "ui/gameuiskin#icon_save.svg"
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
  return res
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
