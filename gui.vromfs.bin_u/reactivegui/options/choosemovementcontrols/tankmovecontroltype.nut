from "%globalsDarg/darg_library.nut" import *
let { OPT_TANK_MOVEMENT_CONTROL, mkOptionValue } = require("%rGui/options/guiOptions.nut")

let tankMoveCtrlTypesList = ["stick_static", "stick", "arrows"]
let currentTankMoveCtrlType = mkOptionValue(OPT_TANK_MOVEMENT_CONTROL, null,
  @(v) tankMoveCtrlTypesList.contains(v) ? v : tankMoveCtrlTypesList[0])
let ctrlTypeToString = @(v) loc($"options/{v}")

return {
  tankMoveCtrlTypesList
  currentTankMoveCtrlType
  ctrlTypeToString
}