from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/chooseMovementControls/groundMoveControlType.nut" import currentTankMoveCtrlType
from "%rGui/options/guiOptions.nut" import OPT_GEAR_DOWN_ON_STOP_BUTTON, mkOptionValue


let validate = @(val, list) list.contains(val) ? val : list[0]

let gearDownOnStopButtonList = [false, true]
let showGearDownControl = Computed(@() currentTankMoveCtrlType.get() == "arrows")
let currentGearDownOnStopButtonTouch =
  mkOptionValue(OPT_GEAR_DOWN_ON_STOP_BUTTON, true, @(v) validate(v, gearDownOnStopButtonList))

return {
  currentGearDownOnStopButtonTouch
  showGearDownControl
  gearDownOnStopButtonList
}
