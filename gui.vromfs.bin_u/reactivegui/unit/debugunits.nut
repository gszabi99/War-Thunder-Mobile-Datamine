
// warning disable: -file:forbidden-function

from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { hangar_load_model } = require("hangar")
let { gatherUnitStatsLimits } = require("unitStats.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getUnitTags, getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { startTestFlight } = require("%rGui/gameModes/startOfflineMode.nut")

let function debugUnitStats() {
  let { allUnits = {} } = serverConfigs.value
  let unitsByCamp = {}
  foreach(name, unit in allUnits) {
    let { campaign = "" } = unit
    if (campaign not in unitsByCamp)
      unitsByCamp[campaign] <- {}
    unitsByCamp[campaign][name] <- unit
  }

  let stats = unitsByCamp.map(function(units) {
    let uArr = units.keys()
    units.each(@(u) u.platoonUnits.len() != 0
      ? uArr.extend(u.platoonUnits.map(@(pu) pu.name))
      : null)
    return gatherUnitStatsLimits(uArr)
  })
  log("Unit stats ranges:", stats)
}

let isFilledString = @(unitName) type(unitName) == "string" && unitName.len() != 0
let invalidStrParamMsg = "ERROR: Param {0} should be a non empty string in double quotes."

let function debug_show_unit(unitName) {
  if (!isFilledString(unitName))
    return console_print(invalidStrParamMsg.subst("unitName"))
  hangar_load_model(unitName)
}

let function debug_start_testflight(unitName, missionName) {
  if (!isFilledString(unitName))
    return console_print(invalidStrParamMsg.subst("unitName"))
  if (!isFilledString(missionName))
    return console_print(invalidStrParamMsg.subst("missionName"))
  console_print($"Starting testflight, unit \"{unitName}\", mission \"{missionName}\"")
  startTestFlight(unitName, missionName)
}

register_command(debugUnitStats, "debug.unitStats")
register_command(
  @(unitName) console_print($"Tags of '{unitName}': ", getUnitTags(unitName)), // warning disable: -forbidden-function
  "debug.get_unit_tags")
register_command(
  @(unitName) console_print($"Tags of '{unitName}': ", getUnitTagsCfg(unitName)), // warning disable: -forbidden-function
  "debug.get_unit_tags_full")
register_command(debug_show_unit, "ui.debug.show_unit")
register_command(debug_start_testflight, "ui.debug.testflight")
register_command(@(unitName) debug_start_testflight(unitName, "testFlight_ussr_tft"), "ui.debug.testflight_tank")
register_command(@(unitName) debug_start_testflight(unitName, "testFlight_destroyer_usa_tfs"), "ui.debug.testflight_ship")
