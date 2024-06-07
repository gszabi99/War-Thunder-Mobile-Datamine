from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { get_base_game_version_str } = require("app")
let { check_version } = require("%sqstd/version_compare.nut")
let {
  OPT_AIRCRAFT_FIXED_AIM_CURSOR,
  OPT_CAMERA_SENSE_IN_ZOOM_PLANE,
  OPT_CAMERA_SENSE_PLANE,
  OPT_CAMERA_SENSE,
  OPT_CAMERA_SENSE_IN_ZOOM,
  OPT_FREE_CAMERA_PLANE,
  OPT_CAMERA_VISC_PLANE,
  OPT_CAMERA_VISC_IN_ZOOM_PLANE,
  OPT_AIRCRAFT_INVERTED_Y,
  OPT_AIRCRAFT_MOVEMENT_CONTROL,
  OPT_AIRCRAFT_CONTINUOUS_TURN_MODE,
  OPT_AIRCRAFT_GYRO_CONTROL_FLAG_AILERONS,
  OPT_AIRCRAFT_GYRO_CONTROL_FLAG_ELEVATOR,
  OPT_AIRCRAFT_GYRO_CONTROL_PARAM_DEAD_ZONE,
  OPT_AIRCRAFT_GYRO_CONTROL_PARAM_SENSITIVITY,
  OPT_AIRCRAFT_TAP_SELECTION,
  OPT_AIRCRAFT_ADDITIONAL_FLY_CONTROLS,
  mkOptionValue,
  getOptValue } = require("%rGui/options/guiOptions.nut")
let {
  set_aircraft_continuous_turn_mode,
  set_aircraft_control_by_gyro = @(...) null,
  set_aircraft_control_by_gyro_mode_flag = @(...) null,
  set_aircraft_control_by_gyro_mode_param = @(...) null,
  CBG_FLAG_AILERONS = 0,
  CBG_FLAG_ELEVATOR = 1,
  CBG_PARAM_DEAD_ZONE = 0,
  CBG_PARAM_SENSITIVITY = 1,
  set_aircraft_fixed_aim_cursor,
  set_should_invert_camera,
  set_camera_viscosity,
  set_camera_viscosity_in_zoom,
  set_aircraft_tap_selection = null,
  CAM_TYPE_FREE_PLANE,
  CAM_TYPE_NORMAL_PLANE,
  CAM_TYPE_BINOCULAR_PLANE } = require("controlsOptions")
let { cameraSenseSlider } =  require("%rGui/options/options/controlsOptions.nut")
let { crosshairOptions } = require("crosshairOptions.nut")

let validate = @(val, list) list.contains(val) ? val : list[0]

let fixedAimCursorList = [false, true]
let currentFixedAimCursor = mkOptionValue(OPT_AIRCRAFT_FIXED_AIM_CURSOR, false, @(v) validate(v, fixedAimCursorList))
set_aircraft_fixed_aim_cursor(currentFixedAimCursor.value)
currentFixedAimCursor.subscribe(@(v) set_aircraft_fixed_aim_cursor(v))
let currentFixedAimCursorType = {
  locId = "options/fixed_aim_cursor"
  ctrlType = OCT_LIST
  value = currentFixedAimCursor
  list = fixedAimCursorList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/fixed_aim_cursor")
}

let CAN_USE_ADDINTIONAL_FLY_CTRLS = check_version($">=1.6.0.106", get_base_game_version_str())
let currentAdditionalFlyControlsList = [false, true]
let currentAdditionalFlyControls = !CAN_USE_ADDINTIONAL_FLY_CTRLS ? Watched(false) : mkOptionValue(OPT_AIRCRAFT_ADDITIONAL_FLY_CONTROLS, false,
  @(v) validate(v, currentAdditionalFlyControlsList))
let currentAdditionalFlyControlsType = {
  locId = "options/additional_fly_controls"
  ctrlType = OCT_LIST
  value = currentAdditionalFlyControls
  list = currentAdditionalFlyControlsList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

let invertedYList = [false, true]
let currentinvertedYOption = mkOptionValue(OPT_AIRCRAFT_INVERTED_Y, false, @(v) validate(v, invertedYList))
set_should_invert_camera(currentinvertedYOption.value)
currentinvertedYOption.subscribe(@(v) set_should_invert_camera(v))
let currentinvertedYOptionType = {
  locId = "options/inverted_y"
  ctrlType = OCT_LIST
  value = currentinvertedYOption
  list = invertedYList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

let aircraftCtrlTypesList = ["mouse_aim", "stick", "stick_static"]
let currentAircraftCtrlType = mkOptionValue(OPT_AIRCRAFT_MOVEMENT_CONTROL, null,
  @(v) aircraftCtrlTypesList.contains(v) ? v : aircraftCtrlTypesList[0])

let airCtrlTypeToString = @(v) loc($"options/{v}")

let aircraftControlType = {
  locId = "options/aircraft_movement_control"
  ctrlType = OCT_LIST
  value = currentAircraftCtrlType
  list = aircraftCtrlTypesList
  valToString = airCtrlTypeToString
}

let continuousTurnModeList = [false, true]
let currentContinuousTurnMode = mkOptionValue(OPT_AIRCRAFT_CONTINUOUS_TURN_MODE, false, @(v) validate(v, continuousTurnModeList))
set_aircraft_continuous_turn_mode(currentContinuousTurnMode.value)
currentContinuousTurnMode.subscribe(@(v) set_aircraft_continuous_turn_mode(v))
let currentContinuousTurnModeType = {
  locId = "options/continuous_turn_mode"
  ctrlType = OCT_LIST
  value = currentContinuousTurnMode
  list = continuousTurnModeList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/continuous_turn_mode")
}

let CAN_USE_GYRO = check_version($">=1.6.0.110", get_base_game_version_str())

let currentControlByGyroModeAileronsList = [false, true]
let currentControlByGyroModeAilerons = !CAN_USE_GYRO ? Watched(false) : mkOptionValue(OPT_AIRCRAFT_GYRO_CONTROL_FLAG_AILERONS, false,
  @(v) validate(v, currentAdditionalFlyControlsList))
set_aircraft_control_by_gyro_mode_flag(CBG_FLAG_AILERONS, currentControlByGyroModeAilerons.value)
currentControlByGyroModeAilerons.subscribe(@(v) set_aircraft_control_by_gyro_mode_flag(CBG_FLAG_AILERONS, v))
let controlByGyroModeAilerons = {
  locId = "options/control_by_gyro_ailerons"
  ctrlType = OCT_LIST
  value = currentControlByGyroModeAilerons
  list = currentControlByGyroModeAileronsList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

let currentControlByGyroModeElevatorList = [false, true]
let currentControlByGyroModeElevator = !CAN_USE_GYRO ? Watched(false) : mkOptionValue(OPT_AIRCRAFT_GYRO_CONTROL_FLAG_ELEVATOR, false,
  @(v) validate(v, currentAdditionalFlyControlsList))
set_aircraft_control_by_gyro_mode_flag(CBG_FLAG_ELEVATOR, currentControlByGyroModeElevator.value)
currentControlByGyroModeElevator.subscribe(@(v) set_aircraft_control_by_gyro_mode_flag(CBG_FLAG_ELEVATOR, v))
let controlByGyroModeElevator = {
  locId = "options/control_by_gyro_elevator"
  ctrlType = OCT_LIST
  value = currentControlByGyroModeElevator
  list = currentControlByGyroModeElevatorList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

set_aircraft_control_by_gyro(currentControlByGyroModeAilerons.value || currentControlByGyroModeElevator.value)
currentControlByGyroModeAilerons.subscribe(@(_) set_aircraft_control_by_gyro(currentControlByGyroModeAilerons.value || currentControlByGyroModeElevator.value))
currentControlByGyroModeElevator.subscribe(@(_) set_aircraft_control_by_gyro(currentControlByGyroModeElevator.value || currentControlByGyroModeAilerons.value))

let currentControlByGyroModeDeadZone = !CAN_USE_GYRO ? Watched(0.5) : mkOptionValue(OPT_AIRCRAFT_GYRO_CONTROL_PARAM_DEAD_ZONE, 0.5)
set_aircraft_control_by_gyro_mode_param(CBG_PARAM_DEAD_ZONE, currentControlByGyroModeDeadZone.value)
currentControlByGyroModeDeadZone.subscribe(@(v) set_aircraft_control_by_gyro_mode_param(CBG_PARAM_DEAD_ZONE, v))
let controlByGyroModeDeadZoneSlider = {
  locId = "options/control_by_gyro_dead_zone"
  ctrlType = OCT_SLIDER
  value = currentControlByGyroModeDeadZone
  valToString = @(v) $"{v}"
  ctrlOverride = {
    min = 0.1
    max = 1.0
    unit = 0.01
  }
}

let currentControlByGyroModeSensitivity = !CAN_USE_GYRO ? Watched(5.0) : mkOptionValue(OPT_AIRCRAFT_GYRO_CONTROL_PARAM_SENSITIVITY, 5.0)
set_aircraft_control_by_gyro_mode_param(CBG_PARAM_SENSITIVITY, currentControlByGyroModeSensitivity.value)
currentControlByGyroModeSensitivity.subscribe(@(v) set_aircraft_control_by_gyro_mode_param(CBG_PARAM_SENSITIVITY, v))
let controlByGyroModeSensitivitySlider = {
  locId = "options/control_by_gyro_sensitivity"
  ctrlType = OCT_SLIDER
  value = currentControlByGyroModeSensitivity
  valToString = @(v) $"{v}"
  ctrlOverride = {
    min = 0.0
    max = 10.0
    unit = 0.1
  }
}

function cameraViscositySlider(inZoom, locId, optId, cur = 1.0, minVal = 0.03, step = 0.03, maxVal = 3.0) {
  let value = mkOptionValue(optId, cur)
  if (inZoom)
    set_camera_viscosity_in_zoom(max(maxVal - value.value, minVal))
  else
    set_camera_viscosity(max(maxVal - value.value, minVal))
  value.subscribe(@(v) inZoom ? set_camera_viscosity_in_zoom(max(maxVal - v, minVal)) : set_camera_viscosity(max(maxVal - v, minVal)))
  return {
    locId
    value
    ctrlType = OCT_SLIDER
    valToString = @(v) $"{(((v-minVal)/(maxVal - minVal))*100 + 0.5).tointeger()}%"
    ctrlOverride = {
      min = minVal
      max = maxVal
      unit = step
    }
  }
}

let tapSelectionList = [false, true]
let currentTapSelection = mkOptionValue(OPT_AIRCRAFT_TAP_SELECTION, false, @(v) validate(v, tapSelectionList))
set_aircraft_tap_selection?(currentTapSelection.value)
currentTapSelection.subscribe(@(v) set_aircraft_tap_selection?(v))
let currentTapSelectionType = {
  locId = "options/tap_selection"
  ctrlType = OCT_LIST
  value = currentTapSelection
  list = tapSelectionList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/tap_selection")
}

return {
  airControlsOptions = [
    aircraftControlType
    currentFixedAimCursorType
    currentinvertedYOptionType
    !CAN_USE_ADDINTIONAL_FLY_CTRLS ? null : currentAdditionalFlyControlsType
    cameraSenseSlider(CAM_TYPE_NORMAL_PLANE, "options/cursor_sensitivity", OPT_CAMERA_SENSE_PLANE, getOptValue(OPT_CAMERA_SENSE)?? 1.0, 0.33, 3.0, 0.026)
    cameraViscositySlider(false, "options/camera_sensitivity", OPT_CAMERA_VISC_PLANE)
    cameraSenseSlider(CAM_TYPE_BINOCULAR_PLANE, "options/cursor_sensitivity_in_zoom", OPT_CAMERA_SENSE_IN_ZOOM_PLANE, getOptValue(OPT_CAMERA_SENSE_IN_ZOOM)?? 1.0, 0.33, 3.0, 0.026)
    cameraViscositySlider(true, "options/camera_sensitivity_in_zoom", OPT_CAMERA_VISC_IN_ZOOM_PLANE,1.0, 0.003, 0.1, 10.0)
    cameraSenseSlider(CAM_TYPE_FREE_PLANE, "options/free_camera_sensitivity_plane", OPT_FREE_CAMERA_PLANE, 0.5, 0.125, 2.0, 0.0187)
    currentContinuousTurnModeType
    !CAN_USE_GYRO ? null : controlByGyroModeAilerons
    !CAN_USE_GYRO ? null : controlByGyroModeElevator
    !CAN_USE_GYRO ? null : controlByGyroModeDeadZoneSlider
    !CAN_USE_GYRO ? null : controlByGyroModeSensitivitySlider
    set_aircraft_tap_selection == null ? null : currentTapSelectionType
  ].extend(crosshairOptions)
  currentAircraftCtrlType
  currentControlByGyroModeAilerons,
  currentControlByGyroModeElevator,
  currentControlByGyroModeDeadZone,
  currentControlByGyroModeSensitivity,
  currentAdditionalFlyControls
  CAN_USE_ADDINTIONAL_FLY_CTRLS
}
