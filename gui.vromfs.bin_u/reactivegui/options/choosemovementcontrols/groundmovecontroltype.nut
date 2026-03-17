from "%globalsDarg/darg_library.nut" import *
let { OPT_TANK_MOVEMENT_CONTROL, mkOptionValue } = require("%rGui/options/guiOptions.nut")

let groundMoveCtrlTypesList = ["stick_static", "stick", "arrows"]
let currentTankMoveCtrlType = mkOptionValue(OPT_TANK_MOVEMENT_CONTROL, null,
  @(v) groundMoveCtrlTypesList.contains(v) ? v : groundMoveCtrlTypesList[0])
let ctrlTypeToString = @(v) loc($"options/{v}")

return {
  groundMoveCtrlTypesList
  currentTankMoveCtrlType
  ctrlTypeToString
}