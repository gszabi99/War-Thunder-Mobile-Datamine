from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { OPT_WALER_CAMERA_FORWARD_MOVEMENT, OPT_WALKER_STEP_SHAKE_CAMERA, OPT_AUTO_ZOOM_WALKER, mkOptionValue
} = require("%rGui/options/guiOptions.nut")
let { set_walker_camera_forward_movement, set_auto_zoom_walker } = require("controlsOptions")
let { sendSettingChangeBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { groundMoveCtrlTypesList, currentWalkerMoveCtrlType, ctrlTypeToString
} = require("%rGui/options/chooseMovementControls/groundMoveControlType.nut")
let { openChooseWalkerMovementControls
} = require("%rGui/options/chooseMovementControls/chooseMovementControlsState.nut")

let sendChange = @(id, v) sendSettingChangeBqEvent(id, "walkers", v)

let validate = @(val, list) list.contains(val) ? val : list[0]

let walkerMoveControlType = {
  locId = "options/walker_movement_control"
  ctrlType = OCT_LIST
  value = currentWalkerMoveCtrlType
  onChangeValue = @(v) sendChange("walker_movement_control", v)
  list = groundMoveCtrlTypesList
  valToString = ctrlTypeToString
  openInfo = openChooseWalkerMovementControls
}

let autoZoomList = [false, true]
let currentAutoZoom = mkOptionValue(OPT_AUTO_ZOOM_WALKER, true, @(v) validate(v, autoZoomList))
set_auto_zoom_walker(currentAutoZoom.get())
currentAutoZoom.subscribe(@(v) set_auto_zoom_walker(v))
let currentAutoZoomType = {
  locId = "options/auto_zoom"
  ctrlType = OCT_LIST
  value = currentAutoZoom
  onChangeValue = @(v) sendChange("auto_zoom", v)
  list = autoZoomList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/auto_zoom")
}

let cameraForwardMovementTypeList = [false, true]
let currentCameraForwardMovementType = mkOptionValue(OPT_WALER_CAMERA_FORWARD_MOVEMENT, false, @(v) validate(v, cameraForwardMovementTypeList))
set_walker_camera_forward_movement(currentCameraForwardMovementType.get())
currentCameraForwardMovementType.subscribe(@(v) set_walker_camera_forward_movement(v))
let cameraForwardMovementType = {
  locId = "options/walker_camera_forward_movement"
  ctrlType = OCT_LIST
  value = currentCameraForwardMovementType
  function setValue(v){
    currentCameraForwardMovementType.set(v)
    sendChange("walker_camera_forward_movement", v)
  }
  list = cameraForwardMovementTypeList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc($"options/desc/walker_camera_forward_movement")
}

let stepShakeCameraList = [false, true]
let currentStepShakeCameraType = mkOptionValue(OPT_WALKER_STEP_SHAKE_CAMERA, false, @(v) validate(v, stepShakeCameraList))
let stepShakeCameraType = {
  locId = "options/walker_step_shake_camera"
  ctrlType = OCT_LIST
  value = currentStepShakeCameraType
  onChangeValue = @(v) sendChange("camera_shake_on_step", v)
  list = stepShakeCameraList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc($"options/desc/walker_step_shake_camera")
}

return {
  walkerControlsOptions = [
    walkerMoveControlType
    currentAutoZoomType
    cameraForwardMovementType
    stepShakeCameraType
  ]
}
