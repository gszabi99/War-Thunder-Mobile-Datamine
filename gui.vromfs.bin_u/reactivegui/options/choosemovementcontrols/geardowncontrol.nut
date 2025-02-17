from "%globalsDarg/darg_library.nut" import *
let { OPT_GEAR_DOWN_ON_STOP_BUTTON, mkOptionValue } = require("%rGui/options/guiOptions.nut")
let { currentTankMoveCtrlType } = require("%rGui/options/chooseMovementControls/tankMoveControlType.nut")


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
