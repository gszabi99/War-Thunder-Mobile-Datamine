from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let { get_user_system_info, get_battery, is_charging, get_thermal_state } = require("sysinfo")
let { get_game_version_str } = require("app")
let { get_gui_option, addUserOption } = require("guiOptions")
let { myUserName } = require("%appGlobals/profileStates.nut")
let { getAppsFlyerUID } = require("appsFlyer")
let { authState } = require("authState.nut")

let fieldsToClear = ["MAC", "uuid0", "uuid1", "uuid2", "uuid3"]
let OPT_TANK_MOVEMENT_CONTROL = addUserOption("OPT_TANK_MOVEMENT_CONTROL")

let function getSysInfo() {
  let tbl = get_user_system_info()
  tbl.userName <- myUserName.value
  tbl.appsflyer_id <- getAppsFlyerUID()
  tbl.gameVersion <- get_game_version_str()
  tbl.tankMoveControlType <- get_gui_option(OPT_TANK_MOVEMENT_CONTROL) ?? "stick"
  tbl.battery <- get_battery()
  tbl.isCharging <- is_charging()
  tbl.thermalState <- get_thermal_state()
  tbl.authorization <- authState.value.loginType

  foreach (key in fieldsToClear)
    if (key in tbl)
      delete tbl[key]

  if ("cpuFeatures" in tbl)
    if (type(tbl.cpuFeatures) == "table") {
      let values = tbl.cpuFeatures.filter(@(v) v)
        .keys()
        .sort(@(a, b) a <=> b)
      tbl.cpuFeatures = $";{";".join(values)};"
    }
    else if (type(tbl.cpuFeatures) != "string")
      delete tbl.cpuFeatures

  return tbl
}

return {
  getSysInfo = getSysInfo
}
