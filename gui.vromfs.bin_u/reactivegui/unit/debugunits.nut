from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "hangar" import hangar_load_model
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/unitTags.nut" import getUnitTags, getUnitTagsCfg
from "%rGui/gameModes/startOfflineMode.nut" import startTestFlightByName
from "%rGui/unit/unitStats.nut" import gatherUnitStatsLimits
from "types" import String





function debugUnitStats() {
  let { allUnits = {} } = serverConfigs.get()
  let unitsByCamp = {}
  foreach(name, unit in allUnits) {
    let { campaign = "" } = unit
    if (campaign not in unitsByCamp)
      unitsByCamp[campaign] <- {}
    unitsByCamp[campaign][name] <- unit
  }

  let stats = unitsByCamp.map(@(units) gatherUnitStatsLimits(units.keys()))
  log("Unit stats ranges:", stats)
}

let isFilledString = @(unitName) unitName instanceof String && unitName.len() != 0
const invalidStrParamMsg = "ERROR: Param {0} should be a non empty string in double quotes."

function debug_show_unit(unitName) {
  if (!isFilledString(unitName))
    return console_print(invalidStrParamMsg.subst("unitName"))
  hangar_load_model(unitName, false, false)
}

function debug_start_testflight(unitName, missionName) {
  if (!isFilledString(unitName))
    return console_print(invalidStrParamMsg.subst("unitName"))
  if (!isFilledString(missionName))
    return console_print(invalidStrParamMsg.subst("missionName"))
  console_print($"Starting testflight, unit \"{unitName}\", mission \"{missionName}\"")
  startTestFlightByName(unitName, missionName)
}

let needToShowHiddenUnitsDebug = mkWatched(persist, "needToShowHiddenUnitsDebug", false)

register_command(@() needToShowHiddenUnitsDebug.set(!needToShowHiddenUnitsDebug.get()), "ui.showHiddenUnits")
register_command(debugUnitStats, "debug.unitStats")
register_command(
  @(unitName) console_print($"Tags of '{unitName}': ", getUnitTags(unitName)), 
  "debug.get_unit_tags")
register_command(
  @(unitName) console_print($"Tags of '{unitName}': ", getUnitTagsCfg(unitName)), 
  "debug.get_unit_tags_full")
register_command(debug_show_unit, "ui.debug.show_unit")
register_command(debug_start_testflight, "ui.debug.testflight")
register_command(@(unitName) debug_start_testflight(unitName, "testFlight_ussr_tft"), "ui.debug.testflight_tank")
register_command(@(unitName) debug_start_testflight(unitName, "testFlight_destroyer_usa_tfs"), "ui.debug.testflight_ship")
register_command(@(unitName) debug_start_testflight(unitName, "testFlight_plane"), "ui.debug.testflight_air")

return {
  needToShowHiddenUnitsDebug
}