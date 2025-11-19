from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { sendSettingChangeBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { setVirtualAxesAim, setVirtualAxesDirectControl } = require("%globalScripts/controls/shortcutActions.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { OPT_AIRCRAFT_FIXED_AIM_CURSOR, OPT_CAMERA_SENSE_IN_ZOOM_PLANE, OPT_CAMERA_SENSE_PLANE,
  OPT_CAMERA_SENSE, OPT_CAMERA_SENSE_IN_ZOOM, OPT_FREE_CAMERA_PLANE, OPT_CAMERA_VISC_PLANE,
  OPT_CAMERA_VISC_IN_ZOOM_PLANE, OPT_CAMERA_VISC_PLANE_STICK, OPT_CAMERA_VISC_IN_ZOOM_PLANE_STICK,
  OPT_AIRCRAFT_INVERTED_Y, OPT_AIRCRAFT_MOVEMENT_CONTROL, OPT_AIRCRAFT_CONTINUOUS_TURN_MODE,
  OPT_AIRCRAFT_THROTTLE_STICK, OPT_AIRCRAFT_GYRO_CONTROL_FLAG_AILERONS, OPT_AIRCRAFT_GYRO_CONTROL_AIM_MODE,
  OPT_AIRCRAFT_GYRO_CONTROL_FLAG_DIRECT_CONTROL, OPT_AIRCRAFT_GYRO_CONTROL_PARAM_DEAD_ZONE,
  OPT_AIRCRAFT_GYRO_CONTROL_PARAM_SENSITIVITY, OPT_AIRCRAFT_GYRO_CONTROL_PARAM_ELEVATOR_DEAD_ZONE,
  OPT_AIRCRAFT_GYRO_CONTROL_PARAM_ELEVATOR_SENSITIVITY, OPT_TARGET_SELECTION_TYPE,
  OPT_AIRCRAFT_ADDITIONAL_FLY_CONTROLS, OPT_AIRCRAFT_TARGET_FOLLOWER, USEROPT_QUIT_ZOOM_AFTER_KILL,
  OPT_AIRCRAFT_FREE_CAMERA_BY_TOUCH, mkOptionValue, optionValues, getOptValue
} = require("%rGui/options/guiOptions.nut")
let { set_aircraft_continuous_turn_mode, set_aircraft_control_by_gyro, set_aircraft_control_by_gyro_mode_param,
  CBG_PARAM_DEAD_ZONE, CBG_PARAM_SENSITIVITY, set_aircraft_fixed_aim_cursor, set_should_invert_camera,
  set_camera_viscosity, set_camera_viscosity_in_zoom, set_target_selection_type, set_aircraft_target_follower,
  set_quit_zoom_after_kill, set_mouse_aim, CAM_TYPE_FREE_PLANE, CAM_TYPE_NORMAL_PLANE, CAM_TYPE_BINOCULAR_PLANE
} = require("controlsOptions")
let { cameraSenseSlider } =  require("%rGui/options/options/controlsOptions.nut")
let { crosshairOptions } = require("%rGui/options/options/crosshairOptions.nut")
let { isGtRace } = require("%rGui/missionState.nut")

let validate = @(val, list) list.contains(val) ? val : list[0]
let sendChange = @(id, v) sendSettingChangeBqEvent(id, "air", v)

let fixedAimCursorList = [false, true]
let currentFixedAimCursor = mkOptionValue(OPT_AIRCRAFT_FIXED_AIM_CURSOR, false, @(v) validate(v, fixedAimCursorList))
set_aircraft_fixed_aim_cursor(currentFixedAimCursor.get())
currentFixedAimCursor.subscribe(@(v) set_aircraft_fixed_aim_cursor(v))
let currentFixedAimCursorType = {
  locId = "options/fixed_aim_cursor"
  ctrlType = OCT_LIST
  value = currentFixedAimCursor
  list = fixedAimCursorList
  onChangeValue = @(v) sendChange("fixed_aim_cursor", v)
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/fixed_aim_cursor")
}

let currentAdditionalFlyControlsList = [false, true]
let currentAdditionalFlyControls = mkOptionValue(OPT_AIRCRAFT_ADDITIONAL_FLY_CONTROLS, false,
  @(v) validate(v, currentAdditionalFlyControlsList))
let currentAdditionalFlyControlsType = {
  locId = "options/additional_fly_controls"
  ctrlType = OCT_LIST
  value = currentAdditionalFlyControls
  onChangeValue = @(v) sendChange("additional_fly_controls", v)
  list = currentAdditionalFlyControlsList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

let invertedYList = [false, true]
let currentinvertedYOption = mkOptionValue(OPT_AIRCRAFT_INVERTED_Y, false, @(v) validate(v, invertedYList))
set_should_invert_camera(currentinvertedYOption.get())
currentinvertedYOption.subscribe(@(v) set_should_invert_camera(v))
let currentinvertedYOptionType = {
  locId = "options/inverted_y"
  ctrlType = OCT_LIST
  value = currentinvertedYOption
  onChangeValue = @(v) sendChange("inverted_y", v)
  list = invertedYList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

let aircraftCtrlTypesList = ["mouse_aim", "stick", "stick_static"]
let optAircraftCtrlType = mkOptionValue(OPT_AIRCRAFT_MOVEMENT_CONTROL, null,
  @(v) aircraftCtrlTypesList.contains(v) ? v : aircraftCtrlTypesList[0])

let airCtrlTypeToString = @(v) loc($"options/{v}")

let overridedOptions = mkWatched(persist, "overridedOptions", {})

eventbus_subscribe("overrideGuiOption", @(msg)
  overridedOptions.mutate(function(v) {
    if (msg.val != "default")
      v[msg.id] <- msg.val
    else if (msg.id in v)
       v.$rawdelete(msg.id)
  }))


eventbus_subscribe("resetGuiOptionOverrides", @(_) overridedOptions.set({}))

let currentAircraftCtrlType = Computed( @() overridedOptions.get()?[OPT_AIRCRAFT_MOVEMENT_CONTROL] ?? optAircraftCtrlType.get())

let aircraftControlType = {
  locId = "options/aircraft_movement_control"
  ctrlType = OCT_LIST
  value = optAircraftCtrlType
  onChangeValue = @(v) sendChange("aircraft_movement_control", v)
  list = aircraftCtrlTypesList
  valToString = airCtrlTypeToString
}

let freeCamByTouchList = [false, true]
let curFreeCamByTouchOption = mkOptionValue(OPT_AIRCRAFT_FREE_CAMERA_BY_TOUCH, false, @(v) validate(v, freeCamByTouchList))
let curFreeCamByTouchOptionType = {
  locId = "options/free_cam_by_touch"
  ctrlType = OCT_LIST
  value = curFreeCamByTouchOption
  onChangeValue = @(v) sendChange("free_cam_by_touch", v)
  list = Computed(@() (currentAircraftCtrlType.get() == "stick" || currentAircraftCtrlType.get() == "stick_static") ? freeCamByTouchList : [])
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

let continuousTurnModeList = [false, true]
let optContinuousTurnMode = mkOptionValue(OPT_AIRCRAFT_CONTINUOUS_TURN_MODE, false, @(v) validate(v, continuousTurnModeList))
let currentContinuousTurnMode = keepref(Computed( @() overridedOptions.get()?[OPT_AIRCRAFT_CONTINUOUS_TURN_MODE] ?? optContinuousTurnMode.get()))

set_aircraft_continuous_turn_mode(currentContinuousTurnMode.get())
currentContinuousTurnMode.subscribe(@(v) set_aircraft_continuous_turn_mode(v))
let currentContinuousTurnModeType = {
  locId = "options/continuous_turn_mode"
  ctrlType = OCT_LIST
  value = optContinuousTurnMode
  onChangeValue = @(v) sendChange("continuous_turn_mode", v)
  list = continuousTurnModeList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/continuous_turn_mode")
}

let throttleStickList = [false, true]
let currentThrottleStick = mkOptionValue(OPT_AIRCRAFT_THROTTLE_STICK, false, @(v) validate(v, throttleStickList))
let controlThrottleStick = {
  locId = "options/throttle_stick"
  ctrlType = OCT_LIST
  value = currentThrottleStick
  onChangeValue = @(v) sendChange("throttle_stick", v)
  list = throttleStickList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/throttle_stick")
}

let isOptAvailableControlByGyroModeAileronsAssist = Computed(@() setVirtualAxesAim == null && currentAircraftCtrlType.get() == "mouse_aim")
let currentControlByGyroModeAileronsAssistList = [false, true]
let currentControlByGyroModeAileronsAssist = mkOptionValue(OPT_AIRCRAFT_GYRO_CONTROL_FLAG_AILERONS, false,
  @(v) validate(v, currentAdditionalFlyControlsList))
let controlByGyroModeAileronsAssist = {
  locId = "options/control_by_gyro_ailerons_assist"
  ctrlType = OCT_LIST
  value = currentControlByGyroModeAileronsAssist
  onChangeValue = @(v) sendChange("control_by_gyro_ailerons_assist", v)
  list = Computed(@() isOptAvailableControlByGyroModeAileronsAssist.get() ? currentControlByGyroModeAileronsAssistList : [])
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

let isOptAvailableControlByGyroAimMode = Computed(@() setVirtualAxesAim != null && currentAircraftCtrlType.get() == "mouse_aim")
let currentControlByGyroAimModeList = ["off", "aim", "aileron_assist"]
let currentControlByGyroAimMode = mkOptionValue(OPT_AIRCRAFT_GYRO_CONTROL_AIM_MODE, null,
  @(v) currentControlByGyroAimModeList.contains(v) ? v : currentControlByGyroAimModeList[0])
let controlByGyroAimMode = {
  locId = "options/aircraft_gyro_aim_mode"
  ctrlType = OCT_LIST
  value = currentControlByGyroAimMode
  onChangeValue = @(v) sendChange("aircraft_gyro_aim_mode", v)
  list = Computed(@() isOptAvailableControlByGyroAimMode.get() ? currentControlByGyroAimModeList : [])
  valToString = airCtrlTypeToString
}

let isOptAvailableControlByGyroDirectControl = Computed(@() setVirtualAxesDirectControl != null && currentAircraftCtrlType.get() != "mouse_aim")
let currentControlByGyroDirectControlList = [false, true]
let currentControlByGyroDirectControl = mkOptionValue(OPT_AIRCRAFT_GYRO_CONTROL_FLAG_DIRECT_CONTROL, false,
  @(v) validate(v, currentAdditionalFlyControlsList))
let controlByGyroDirectControl = {
  locId = "options/control_gyro_direct_control"
  ctrlType = OCT_LIST
  value = currentControlByGyroDirectControl
  onChangeValue = @(v) sendChange("control_gyro_direct_control", v)
  list = Computed(@() isOptAvailableControlByGyroDirectControl.get() ? currentControlByGyroDirectControlList : [])
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

let isAircraftControlByGyro = Computed(@() (isOptAvailableControlByGyroModeAileronsAssist.get() && currentControlByGyroModeAileronsAssist.get())
  || (isOptAvailableControlByGyroAimMode.get() && currentControlByGyroAimMode.get() != "off")
  || (isOptAvailableControlByGyroDirectControl.get() && currentControlByGyroDirectControl.get()))
let updateAircraftControlByGyro = @() set_aircraft_control_by_gyro(isAircraftControlByGyro.get())
isAircraftControlByGyro.subscribe(@(_) updateAircraftControlByGyro())
updateAircraftControlByGyro()

let currentControlByGyroModeAileronsDeadZone = mkOptionValue(OPT_AIRCRAFT_GYRO_CONTROL_PARAM_DEAD_ZONE, 0.1)
set_aircraft_control_by_gyro_mode_param(CBG_PARAM_DEAD_ZONE, currentControlByGyroModeAileronsDeadZone.get())
currentControlByGyroModeAileronsDeadZone.subscribe(@(v) set_aircraft_control_by_gyro_mode_param(CBG_PARAM_DEAD_ZONE, v))
let controlByGyroModeAileronsDeadZoneSlider = {
  locId = "options/control_by_gyro_ailerons_dead_zone"
  ctrlType = OCT_SLIDER
  value = currentControlByGyroModeAileronsDeadZone
  onChangeValue = @(v) sendChange("control_by_gyro_dead_zone", v)
  valToString = @(v) $"{v}"
  ctrlOverride = {
    min = 0.1
    max = 1.0
    unit = 0.01
  }
}

let currentControlByGyroModeAileronsSensitivity = mkOptionValue(OPT_AIRCRAFT_GYRO_CONTROL_PARAM_SENSITIVITY, 1.0)
set_aircraft_control_by_gyro_mode_param(CBG_PARAM_SENSITIVITY, currentControlByGyroModeAileronsSensitivity.get())
currentControlByGyroModeAileronsSensitivity.subscribe(@(v) set_aircraft_control_by_gyro_mode_param(CBG_PARAM_SENSITIVITY, v))
let controlByGyroModeAileronsSensitivitySlider = {
  locId = "options/control_by_gyro_ailerons_sensitivity"
  ctrlType = OCT_SLIDER
  value = currentControlByGyroModeAileronsSensitivity
  onChangeValue = @(v) sendChange("control_by_gyro_sensitivity", v)
  valToString = @(v) $"{v}"
  ctrlOverride = {
    min = 0.0
    max = 10.0
    unit = 0.1
  }
}

let currentControlByGyroModeElevatorDeadZone = mkOptionValue(OPT_AIRCRAFT_GYRO_CONTROL_PARAM_ELEVATOR_DEAD_ZONE, 0.1)
let controlByGyroModeElevatorDeadZoneSlider = {
  locId = "options/control_by_gyro_elevator_dead_zone"
  ctrlType = OCT_SLIDER
  value = currentControlByGyroModeElevatorDeadZone
  onChangeValue = @(v) sendChange("control_by_gyro_elevator_dead_zone", v)
  valToString = @(v) $"{v}"
  ctrlOverride = {
    min = 0.1
    max = 1.0
    unit = 0.01
  }
}

let currentControlByGyroModeElevatorSensitivity = mkOptionValue(OPT_AIRCRAFT_GYRO_CONTROL_PARAM_ELEVATOR_SENSITIVITY, 3.0)
let controlByGyroModeElevatorSensitivitySlider = {
  locId = "options/control_by_gyro_elevator_sensitivity"
  ctrlType = OCT_SLIDER
  value = currentControlByGyroModeElevatorSensitivity
  onChangeValue = @(v) sendChange("control_by_gyro_elevator_sensitivity", v)
  valToString = @(v) $"{v}"
  ctrlOverride = {
    min = 0.0
    max = 10.0
    unit = 0.1
  }
}

function cameraViscositySlider(visibleWatch, inZoom, locId, optId, cur = 1.0, minVal = 0.03, step = 0.03, maxVal = 3.0) {
  let value = mkOptionValue(optId, cur)
  if (visibleWatch.get())
    if (inZoom)
      set_camera_viscosity_in_zoom(max(maxVal - value.get(), minVal))
    else
      set_camera_viscosity(max(maxVal - value.get(), minVal))
  value.subscribe(@(v) inZoom ? set_camera_viscosity_in_zoom(max(maxVal - v, minVal)) : set_camera_viscosity(max(maxVal - v, minVal)))
  return {
    locId
    value
    ctrlType = OCT_SLIDER
    onChangeValue = @(v) sendChange(locId, v)
    valToString = @(v) $"{(((v-minVal)/(maxVal - minVal))*100 + 0.5).tointeger()}%"
    ctrlOverride = {
      min = minVal
      max = maxVal
      unit = step
    }
    visible = visibleWatch
  }
}

let CAM_VISC_LIMITS = {
  [OPT_CAMERA_VISC_PLANE] = [0.03, 3.0],
  [OPT_CAMERA_VISC_PLANE_STICK] = [0.03, 3.0],
  [OPT_CAMERA_VISC_IN_ZOOM_PLANE] = [0.003, 10.0],
  [OPT_CAMERA_VISC_IN_ZOOM_PLANE_STICK] = [0.003, 10.0]
}

currentAircraftCtrlType.subscribe( function(v) {
  let isMouseAim = v == "mouse_aim"
  set_mouse_aim(isMouseAim)
  let optId = isMouseAim ? OPT_CAMERA_VISC_PLANE : OPT_CAMERA_VISC_PLANE_STICK
  let limits = CAM_VISC_LIMITS[optId]
  let optValue = optionValues?[optId]
  if (optValue != null)
    set_camera_viscosity(max(limits[1] - optValue.get(), limits[0]))

  let optZoomId = isMouseAim ? OPT_CAMERA_VISC_IN_ZOOM_PLANE : OPT_CAMERA_VISC_IN_ZOOM_PLANE_STICK
  let limitsZoom = CAM_VISC_LIMITS[optZoomId]
  let optValueZoom = optionValues?[optZoomId]
  if (optValueZoom != null)
    set_camera_viscosity_in_zoom(max(limitsZoom[1] - optValueZoom.get(), limitsZoom[0]))
})

let targetSelectionList = Computed(@() isGtRace.get() && isInBattle.get() ? ["manual_selection"]
  : ["manual_selection", "tap_selection", "auto_selection"])
let currentTargetSelectionRaw = mkOptionValue(OPT_TARGET_SELECTION_TYPE)
let currentTargetSelection = Computed(@()
  validate(currentTargetSelectionRaw.get() ?? "auto_selection", targetSelectionList.get()))
let updateNativeTargetSelection = @()
  set_target_selection_type(targetSelectionList.get().findindex(@(v) v == currentTargetSelection.get()) ?? 0)
updateNativeTargetSelection()
currentTargetSelection.subscribe(@(_) updateNativeTargetSelection())
targetSelectionList.subscribe(@(_) updateNativeTargetSelection())
let currentTargetSelectionType = {
  locId = "options/target_selection_type"
  ctrlType = OCT_LIST
  value = currentTargetSelection
  setValue = @(v) currentTargetSelectionRaw.set(v)
  onChangeValue = @(v) sendChange("target_selection_type", v)
  list = targetSelectionList
  valToString = airCtrlTypeToString
}

let targetFollowerList = [false, true]
let optTargetFollower = mkOptionValue(OPT_AIRCRAFT_TARGET_FOLLOWER, true, @(v) validate(v, targetFollowerList))
let currentTargetFollower = keepref(Computed( @() overridedOptions.get()?[OPT_AIRCRAFT_TARGET_FOLLOWER] ?? optTargetFollower.get()))

set_aircraft_target_follower(currentTargetFollower.get())
currentTargetFollower.subscribe(@(v) set_aircraft_target_follower(v))
let currentTargetFollowerType = {
  locId = "options/target_follower"
  ctrlType = OCT_LIST
  value = optTargetFollower
  onChangeValue = @(v) sendChange("target_follower", v)
  list = targetFollowerList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/target_follower")
}

let quitZoomAfterKillList = [false, true]
let currentQuitZoomSelection = mkOptionValue(USEROPT_QUIT_ZOOM_AFTER_KILL, false, @(v) validate(v, quitZoomAfterKillList))
set_quit_zoom_after_kill(currentQuitZoomSelection.get())
currentQuitZoomSelection.subscribe(@(v) set_quit_zoom_after_kill(v))
let currentQuitZoomSelectionType = {
  locId = "options/quit_zoom_after_kill"
  ctrlType = OCT_LIST
  value = currentQuitZoomSelection
  onChangeValue = @(v) sendChange("quit_zoom_after_kill", v)
  list = quitZoomAfterKillList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/quit_zoom_after_kill")
}

let isMouseAim = Computed( @() currentAircraftCtrlType.get() == "mouse_aim")
let isStick = Computed( @() currentAircraftCtrlType.get() != "mouse_aim")

return {
  airControlsOptions = [
    aircraftControlType
    currentFixedAimCursorType
    currentinvertedYOptionType
    currentAdditionalFlyControlsType
    cameraSenseSlider(CAM_TYPE_NORMAL_PLANE, "options/cursor_sensitivity", OPT_CAMERA_SENSE_PLANE, getOptValue(OPT_CAMERA_SENSE)?? 1.0, 0.33, 5.67, 0.0267)
    cameraViscositySlider(isMouseAim, false, "options/cursor_folowing_camera_sensitivity", OPT_CAMERA_VISC_PLANE,
      getOptValue(OPT_CAMERA_VISC_PLANE) ?? 1.0,
      CAM_VISC_LIMITS[OPT_CAMERA_VISC_PLANE][0],
      0.03,  
      CAM_VISC_LIMITS[OPT_CAMERA_VISC_PLANE][1])
    cameraViscositySlider(isStick, false, "options/camera_sensitivity_stick", OPT_CAMERA_VISC_PLANE_STICK,
      getOptValue(OPT_CAMERA_VISC_PLANE_STICK) ?? CAM_VISC_LIMITS[OPT_CAMERA_VISC_PLANE_STICK][1],
      CAM_VISC_LIMITS[OPT_CAMERA_VISC_PLANE_STICK][0],
      0.03,  
      CAM_VISC_LIMITS[OPT_CAMERA_VISC_PLANE_STICK][1])
    cameraSenseSlider(CAM_TYPE_BINOCULAR_PLANE, "options/cursor_sensitivity_in_zoom", OPT_CAMERA_SENSE_IN_ZOOM_PLANE, getOptValue(OPT_CAMERA_SENSE_IN_ZOOM)?? 1.0, 0.33, 5.67, 0.0267)
    cameraViscositySlider(isMouseAim, true, "options/camera_sensitivity_in_zoom", OPT_CAMERA_VISC_IN_ZOOM_PLANE,
      getOptValue(OPT_CAMERA_VISC_IN_ZOOM_PLANE) ?? 1.0,
      CAM_VISC_LIMITS[OPT_CAMERA_VISC_IN_ZOOM_PLANE][0],
      0.1,  
      CAM_VISC_LIMITS[OPT_CAMERA_VISC_IN_ZOOM_PLANE][1])
    cameraViscositySlider(isStick, false, "options/camera_sensitivity_in_zoom_stick", OPT_CAMERA_VISC_IN_ZOOM_PLANE_STICK,
      getOptValue(OPT_CAMERA_VISC_IN_ZOOM_PLANE_STICK) ?? CAM_VISC_LIMITS[OPT_CAMERA_VISC_IN_ZOOM_PLANE_STICK][1],
      CAM_VISC_LIMITS[OPT_CAMERA_VISC_IN_ZOOM_PLANE_STICK][0],
      0.1,  
      CAM_VISC_LIMITS[OPT_CAMERA_VISC_IN_ZOOM_PLANE_STICK][1])
    cameraSenseSlider(CAM_TYPE_FREE_PLANE, "options/free_camera_sensitivity_plane", OPT_FREE_CAMERA_PLANE, 0.5, 0.125, 3.875, 0.01875)
    currentContinuousTurnModeType
    controlThrottleStick
    controlByGyroModeAileronsAssist
    controlByGyroAimMode
    controlByGyroDirectControl
    controlByGyroModeAileronsDeadZoneSlider
    controlByGyroModeAileronsSensitivitySlider
    controlByGyroModeElevatorDeadZoneSlider
    controlByGyroModeElevatorSensitivitySlider
    currentTargetSelectionType
    currentTargetFollowerType
    currentQuitZoomSelectionType
    curFreeCamByTouchOptionType
  ].extend(crosshairOptions)
  currentAircraftCtrlType,
  currentThrottleStick,
  currentControlByGyroModeAileronsAssist
  currentControlByGyroAimMode,
  currentControlByGyroDirectControl,
  isAircraftControlByGyro,
  currentControlByGyroModeAileronsDeadZone,
  currentControlByGyroModeAileronsSensitivity,
  currentControlByGyroModeElevatorDeadZone,
  currentControlByGyroModeElevatorSensitivity,
  currentAdditionalFlyControls,
  curFreeCamByTouchOption,
  currentFixedAimCursor
}
