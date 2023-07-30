from "%globalsDarg/darg_library.nut" import *
let { can_debug_configs, can_debug_missions, can_use_debug_console } = require("%appGlobals/permissions.nut")
let { openDebugProfileWnd } = require("%rGui/debugTools/debugProfileWnd.nut")
let { openDebugConfigWnd } = require("%rGui/debugTools/debugConfigsWnd.nut")
let debugShopWnd = require("%rGui/debugTools/debugShopWnd.nut")
let openDebugCommandsWnd = require("%rGui/debugTools/debugCommandsWnd.nut")
let optionsScene = require("%rGui/options/optionsScene.nut")
let debugGameModes = require("%rGui/gameModes/debugGameModes.nut")
let chooseBenchmarkWnd = require("chooseBenchmarkWnd.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { isGamepad } = require("%rGui/activeControls.nut")
let controlsHelpWnd = require("%rGui/controls/help/controlsHelpWnd.nut")
let { openChangeLog, isVersionsReceived } = require("%rGui/changelog/changeLogState.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let startTestFlight = require("startTestFlight.nut")
let { isLoginAwardOpened, canShowLoginAwards } = require("%rGui/unlocks/loginAwardState.nut")
let { startTutor, firstBattleTutor } = require("%rGui/tutorial/tutorialMissions.nut")


let TF_SHIP_TUNE_MISSION = "testFlight_ship_tuning_tfs"

let OPTIONS = {
  name = loc("mainmenu/btnOptions")
  cb = optionsScene
}
let TEST_FLIGHT = {
  name = "Test Drive"
  cb = @() startTestFlight(hangarUnitName.value)
}
let TF_SHIP_TUNE = {
  name = "Ship Tuning"
  cb = @() startTestFlight(hangarUnitName.value, TF_SHIP_TUNE_MISSION)
}
let BENCHMARK = {
  name = loc("mainmenu/btnBenchmark")
  cb = chooseBenchmarkWnd
}
let GAMEPAD_HELP = {
  name = loc("flightmenu/btnControlsHelp")
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
let DEBUG_SHOP = {
  name = "Debug Shop"
  cb = debugShopWnd
}
let CHANGELOG = {
  name = loc("mainmenu/btnChangelog")
  cb = openChangeLog
}
let STORE = {
  name = loc("topmenu/store")
  cb = openShopWnd
}
let LOGIN_AWARD = {
  name = loc("dailyRewards/header")
  cb = @() isLoginAwardOpened(true)
}
let TUTORIAL = {
  name = loc("mainmenu/btnTutorial")
  cb = @() startTutor(firstBattleTutor.value)
}

let function getTopMenuButtons() {
  let res = [OPTIONS, STORE]
  if (firstBattleTutor.value)
    res.append(TUTORIAL)

  if (isGamepad.value)
    res.append(GAMEPAD_HELP)

  if (isVersionsReceived.value)
    res.append(CHANGELOG)

  if (canShowLoginAwards.value)
    res.append(LOGIN_AWARD)

  if (!can_debug_configs.value && !can_debug_missions.value)
    return res

  res.append({})  //separator
  if (can_debug_missions.value)
    res.append(TEST_FLIGHT, TF_SHIP_TUNE, BENCHMARK, DEBUG_EVENTS)
  else if (isOfflineMenu)
    res.append(TEST_FLIGHT, BENCHMARK)

  if (can_debug_configs.value)
    res.append(DEBUG_CONFIGS, DEBUG_PROFILE, DEBUG_SHOP)

  if (can_use_debug_console.value)
    res.append(DEBUG_COMMANDS)

  return res
}

let topMenuButtonsGenId = Computed(function(prev) {
  let vals = [can_debug_missions, can_debug_configs, can_use_debug_console, isGamepad, isVersionsReceived, firstBattleTutor] //warning disable: -declared-never-used
  return prev == FRP_INITIAL ? 0 : prev + 1
})

return {
  getTopMenuButtons
  topMenuButtonsGenId
}
