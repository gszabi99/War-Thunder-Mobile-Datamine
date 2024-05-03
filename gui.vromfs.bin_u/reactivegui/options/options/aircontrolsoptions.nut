from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { OPT_AIRCRAFT_FIXED_AIM_CURSOR, OPT_CAMERA_SENSE_IN_ZOOM_PLANE, OPT_CAMERA_SENSE_PLANE, OPT_CAMERA_SENSE, OPT_CAMERA_VISC_PLANE, OPT_CAMERA_VISC_IN_ZOOM_PLANE,
  OPT_CAMERA_SENSE_IN_ZOOM, OPT_FREE_CAMERA_PLANE, OPT_AIRCRAFT_INVERTED_Y, OPT_AIRCRAFT_CONTINUOUS_TURN_MODE,
  mkOptionValue, getOptValue} = require("%rGui/options/guiOptions.nut")
let { set_aircraft_fixed_aim_cursor = null, set_camera_viscosity = null, set_should_invert_camera, set_camera_viscosity_in_zoom = null,
  set_aircraft_continuous_turn_mode = null,
  CAM_TYPE_NORMAL_PLANE = -1, CAM_TYPE_BINOCULAR_PLANE = -1, CAM_TYPE_FREE_PLANE } = require("controlsOptions")
let { cameraSenseSlider } =  require("%rGui/options/options/controlsOptions.nut")

let { check_version } = require("%sqstd/version_compare.nut")
let { get_base_game_version_str } = require("app")
let isVersion_1_5_4_51 = check_version($">=1.5.4.51", get_base_game_version_str())
let isVersion_1_5_4_70 = check_version($">=1.5.4.70", get_base_game_version_str())

let validate = @(val, list) list.contains(val) ? val : list[0]

let fixedAimCursorList = [false, true]
let currentFixedAimCursor = mkOptionValue(OPT_AIRCRAFT_FIXED_AIM_CURSOR, false, @(v) validate(v, fixedAimCursorList))
set_aircraft_fixed_aim_cursor?(currentFixedAimCursor.value)
currentFixedAimCursor.subscribe(@(v) set_aircraft_fixed_aim_cursor?(v))
let currentFixedAimCursorType = {
  locId = "options/fixed_aim_cursor"
  ctrlType = OCT_LIST
  value = currentFixedAimCursor
  list = fixedAimCursorList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/fixed_aim_cursor")
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

function cameraViscositySlider(inZoom, locId, optId, cur = 1.0, minVal = 0.03, step = 0.003, maxVal = 3.0) {
  let value = mkOptionValue(optId, cur)
  if (inZoom)
    set_camera_viscosity_in_zoom?(max(maxVal - value.value, minVal))
  else
    set_camera_viscosity?(max(maxVal - value.value, minVal))
  value.subscribe(@(v) inZoom ? set_camera_viscosity_in_zoom?(max(maxVal - v, minVal)) : set_camera_viscosity?(max(maxVal - v, minVal)))
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

let continuousTurnModeList = [false, true]
let currentContinuousTurnMode = mkOptionValue(OPT_AIRCRAFT_CONTINUOUS_TURN_MODE, false, @(v) validate(v, continuousTurnModeList))
set_aircraft_continuous_turn_mode?(currentContinuousTurnMode.value)
currentContinuousTurnMode.subscribe(@(v) set_aircraft_continuous_turn_mode?(v))
let currentContinuousTurnModeType = {
  locId = "options/continuous_turn_mode"
  ctrlType = OCT_LIST
  value = currentContinuousTurnMode
  list = continuousTurnModeList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/continuous_turn_mode")
}

return {
  airControlsOptions = [
    set_aircraft_fixed_aim_cursor == null || !isVersion_1_5_4_51 ? null : currentFixedAimCursorType
    isVersion_1_5_4_51 ? currentinvertedYOptionType : null
    CAM_TYPE_NORMAL_PLANE < 0 ? null : cameraSenseSlider(CAM_TYPE_NORMAL_PLANE, "options/cursor_sensitivity", OPT_CAMERA_SENSE_PLANE, getOptValue(OPT_CAMERA_SENSE)?? 1.0, 0.33, 3.0, 0.026)
    set_camera_viscosity == null ? null : cameraViscositySlider(false, "options/camera_sensitivity", OPT_CAMERA_VISC_PLANE)
    CAM_TYPE_BINOCULAR_PLANE < 0 ? null : cameraSenseSlider(CAM_TYPE_BINOCULAR_PLANE, "options/cursor_sensitivity_in_zoom", OPT_CAMERA_SENSE_IN_ZOOM_PLANE, getOptValue(OPT_CAMERA_SENSE_IN_ZOOM)?? 1.0, 0.33, 3.0, 0.026)
    set_camera_viscosity_in_zoom == null ? null : cameraViscositySlider(true, "options/camera_sensitivity_in_zoom", OPT_CAMERA_VISC_IN_ZOOM_PLANE,1.0, 0.003, 0.1, 10.0)
    cameraSenseSlider(CAM_TYPE_FREE_PLANE, "options/free_camera_sensitivity_plane", OPT_FREE_CAMERA_PLANE, 0.5, 0.125, 2.0, 0.0187)
    isVersion_1_5_4_70 ? currentContinuousTurnModeType : null
  ]
}
