from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { send } = require("eventbus")
let { DBGLEVEL } = require("dagor.system")
let { OPT_TANK_MOVEMENT_CONTROL,  /* OPT_TANK_TARGETING_CONTROL,  */ OPT_CAMERA_SENSE_IN_ZOOM,
  OPT_CAMERA_SENSE, OPT_HAPTIC_INTENSITY, OPT_HAPTIC_INTENSITY_ON_SHOOT, OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT,
  OPT_HAPTIC_INTENSITY_ON_COLLISION, OPT_TARGET_TRACKING, OPT_SHOW_MOVE_DIRECTION, mkOptionValue } = require("%rGui/options/guiOptions.nut")
let { CAM_TYPE_NORMAL, CAM_TYPE_BINOCULAR, set_camera_sens, set_should_target_tracking } = require("controlsOptions")
let { setHapticIntensity, ON_SHOOT, ON_HERO_GET_SHOT, ON_COLLISION } = require("hapticVibration")
let { get_option_multiplier, set_option_multiplier, OPTION_FREE_CAMERA_INERTIA } = require("gameOptions")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")

let validate = @(val, list) list.contains(val) ? val : list[0]

let tankMoveControlTypesList = ["stick", "stick_static", "arrows"]
let currentTankMoveControlType = mkOptionValue(OPT_TANK_MOVEMENT_CONTROL, null,
  @(v) validate(v, tankMoveControlTypesList))
let tankMoveControlType = {
  locId = "options/tank_movement_control"
  ctrlType = OCT_LIST
  value = currentTankMoveControlType
  list = tankMoveControlTypesList
  valToString = @(v) loc($"options/{v}")
}

// let tankTargetControlTypesList = ["autoAim", "directAim"]
// let tankTargetControlType = {
//   locId = "options/tank_targeting_control"
//   ctrlType = OCT_LIST
//   value = mkOptionValue(OPT_TANK_TARGETING_CONTROL, null, @(v) validate(v, tankTargetControlTypesList))
//   list = tankTargetControlTypesList
//   valToString = @(v) loc($"options/{v}")
// }

let function cameraSenseSlider(camType, locId, optId) {
  let value = mkOptionValue(optId, 1.0)
  set_camera_sens(camType, value.value)
  value.subscribe(@(v) set_camera_sens(camType, v))
  return {
    locId
    value
    ctrlType = OCT_SLIDER
    valToString = @(v) $"{v*100}%"
    ctrlOverride = {
      min = 0.1
      max = 3
      unit = 0.01 //step
    }
  }
}

let targetTrackingList = [false, true]
let currentTargetTrackingType = mkOptionValue(OPT_TARGET_TRACKING, true, @(v) validate(v, targetTrackingList))
set_should_target_tracking(currentTargetTrackingType.value)
currentTargetTrackingType.subscribe(@(v) set_should_target_tracking(v))
let targetTrackingType = {
  locId = "options/target_tracking"
  ctrlType = OCT_LIST
  value = currentTargetTrackingType
  list = targetTrackingList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

let function hapticIntensitySlider(locId, optId, intensityType = -1) {
  let value = mkOptionValue(optId, 1.0)
  setHapticIntensity(value.value, intensityType)
  value.subscribe(@(v) setHapticIntensity(v, intensityType))
  return {
    locId
    value
    ctrlType = OCT_SLIDER
    valToString = @(v) $"{v*100}%"
    ctrlOverride = {
      min = 0.1
      max = 3
      unit = 0.1 //step
    }
  }
}

let freeCameraInertia = Watched(get_option_multiplier(OPTION_FREE_CAMERA_INERTIA))
isOnlineSettingsAvailable.subscribe(@(_) freeCameraInertia(get_option_multiplier(OPTION_FREE_CAMERA_INERTIA)))
let optFreeCameraInertia = {
  locId = "options/free_camera_inertia"
  value = freeCameraInertia
  function setValue(v) {
    freeCameraInertia(v)
    set_option_multiplier(OPTION_FREE_CAMERA_INERTIA, v)
    send("saveProfile", {})
  }
  ctrlType = OCT_SLIDER
  valToString = @(v) $"{(100 * v + 0.5).tointeger()}%"
  ctrlOverride = {
    min = 0
    max = 1.0
    unit = 0.01 //step
  }
}

let moveDirestionList = [false, true]
let currentShowMoveDirection = mkOptionValue(OPT_SHOW_MOVE_DIRECTION, false, @(v) validate(v, moveDirestionList))
set_should_target_tracking(currentShowMoveDirection.value)
currentShowMoveDirection.subscribe(@(v) set_should_target_tracking(v))
let showMoveDirection = {
  locId = "options/show_move_direction"
  ctrlType = OCT_LIST
  value = currentShowMoveDirection
  list = moveDirestionList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

return {
  currentTankMoveControlType
  tankMoveControlType
  controlsOptions = [
    tankMoveControlType
    targetTrackingType
    // tankTargetControlType
    hapticIntensitySlider("options/vibration", OPT_HAPTIC_INTENSITY)
    hapticIntensitySlider("options/vibration_on_shoot", OPT_HAPTIC_INTENSITY_ON_SHOOT, ON_SHOOT)
    hapticIntensitySlider("options/vibration_on_hero_get_shot", OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT, ON_HERO_GET_SHOT)
    hapticIntensitySlider("options/vibration_on_collision", OPT_HAPTIC_INTENSITY_ON_COLLISION, ON_COLLISION)
    cameraSenseSlider(CAM_TYPE_NORMAL, "options/camera_sensitivity", OPT_CAMERA_SENSE)
    cameraSenseSlider(CAM_TYPE_BINOCULAR, "options/camera_sensitivity_in_zoom", OPT_CAMERA_SENSE_IN_ZOOM)
    DBGLEVEL > 0 ? optFreeCameraInertia : null
    showMoveDirection
  ]
}
