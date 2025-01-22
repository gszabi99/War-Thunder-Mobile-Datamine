from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { /* OPT_TANK_TARGETING_CONTROL,  */
  OPT_TARGET_TRACKING, OPT_SHOW_MOVE_DIRECTION, OPT_SHOW_MOVE_DIRECTION_IN_SIGHT, OPT_ARMOR_PIERCING_FIXED,
  OPT_AUTO_ZOOM_TANK, OPT_GEAR_DOWN_ON_STOP_BUTTON, OPT_CAMERA_SENSE_IN_ZOOM_TANK, OPT_CAMERA_SENSE,
  OPT_CAMERA_SENSE_IN_ZOOM, OPT_CAMERA_SENSE_TANK, OPT_FREE_CAMERA_TANK,
  OPT_SHOW_RETICLE, OPT_HUD_TANK_SHOW_SCORE, OPT_SHOW_GRASS_IN_TANK_VISION, mkOptionValue, getOptValue
} = require("%rGui/options/guiOptions.nut")
let { set_should_target_tracking, set_armor_piercing_fixed, set_show_reticle,
  set_auto_zoom, CAM_TYPE_NORMAL_TANK, CAM_TYPE_BINOCULAR_TANK, CAM_TYPE_FREE_TANK
} = require("controlsOptions")
let { sendSettingChangeBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { sharedStats } = require("%appGlobals/pServer/campaign.nut")
let { tankMoveCtrlTypesList, currentTankMoveCtrlType, ctrlTypeToString
} = require("%rGui/options/chooseMovementControls/tankMoveControlType.nut")
let { openChooseMovementControls
} = require("%rGui/options/chooseMovementControls/chooseMovementControlsState.nut")
let {cameraSenseSlider} =  require("%rGui/options/options/controlsOptions.nut")

let autoZoomDefaultTrueStart = 1699894800 //13.11.23
let sendChange = @(id, v) sendSettingChangeBqEvent(id, "tanks", v)

let validate = @(val, list) list.contains(val) ? val : list[0]

let tankMoveControlType = {
  locId = "options/tank_movement_control"
  ctrlType = OCT_LIST
  value = currentTankMoveCtrlType
  onChangeValue = @(v) sendChange("tank_movement_control", v)
  list = tankMoveCtrlTypesList
  valToString = ctrlTypeToString
  openInfo = openChooseMovementControls
}

let gearDownOnStopButtonList = [false, true]
let showGearDownControl = Computed(@() currentTankMoveCtrlType.value == "arrows")
let currentGearDownOnStopButtonTouch =
  mkOptionValue(OPT_GEAR_DOWN_ON_STOP_BUTTON, true, @(v) validate(v, gearDownOnStopButtonList))
let gearDownOnStopButtonTouch = {
    locId = "options/gear_down_on_stop_button"
    ctrlType = OCT_LIST
    value = currentGearDownOnStopButtonTouch
    onChangeValue = @(v) sendChange("gear_down_on_stop_button", v)
    list = Computed(@() showGearDownControl.value ? gearDownOnStopButtonList : [])
    valToString = @(v) loc(v ? "options/on_touch" : "options/on_hold")
}

let showReticleButtonList = [false, true]
let currentShowReticle =
  mkOptionValue(OPT_SHOW_RETICLE, false, @(v) validate(v, showReticleButtonList))
set_show_reticle(currentShowReticle.value)
currentShowReticle.subscribe(@(v) set_show_reticle(v))
let showReticleButtonTouch = {
    locId = "options/show_reticle"
    ctrlType = OCT_LIST
    value = currentShowReticle
    onChangeValue = @(v) sendChange("show_reticle", v)
    list = showReticleButtonList
    valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

// let tankTargetControlTypesList = ["autoAim", "directAim"]
// let tankTargetControlType = {
//   locId = "options/tank_targeting_control"
//   ctrlType = OCT_LIST
//   value = mkOptionValue(OPT_TANK_TARGETING_CONTROL, null, @(v) validate(v, tankTargetControlTypesList))
//   list = tankTargetControlTypesList
//   valToString = @(v) loc($"options/{v}")
// }

let targetTrackingList = [false, true]
let currentTargetTrackingType = mkOptionValue(OPT_TARGET_TRACKING, true, @(v) validate(v, targetTrackingList))
set_should_target_tracking(currentTargetTrackingType.value)
currentTargetTrackingType.subscribe(@(v) set_should_target_tracking(v))
let targetTrackingType = {
  locId = "options/target_tracking"
  ctrlType = OCT_LIST
  value = currentTargetTrackingType
  function setValue(v){
    currentTargetTrackingType(v)
    sendChange("target_tracking", v)
  }
  list = targetTrackingList
  valToString = @(v) loc(v ? "options/auto" : "options/manual")
  description = loc("options/desc/target_tracking")
}

let armorPiercingFixedList = [false, true]
let currentArmorPiercingFixedRaw = mkOptionValue(OPT_ARMOR_PIERCING_FIXED)
let currentArmorPiercingFixed = Computed(@()
  validate(currentArmorPiercingFixedRaw.get() ?? true, armorPiercingFixedList))
set_armor_piercing_fixed(currentArmorPiercingFixed.value)
currentArmorPiercingFixed.subscribe(@(v) set_armor_piercing_fixed(v))
let currentArmorPiercingType = {
  locId = "options/armor_piercing_fixed"
  ctrlType = OCT_LIST
  value = currentArmorPiercingFixed
  setValue = @(v) currentArmorPiercingFixedRaw(v)
  onChangeValue = @(v) sendChange("armor_piercing_fixed", v)
  list = armorPiercingFixedList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/armor_piercing_fixed")
}

let autoZoomList = [false, true]
let autoZoomDefault = Computed(@() (sharedStats.get()?.firstLoginTime ?? 0) > autoZoomDefaultTrueStart)
let currentAutoZoomRaw = mkOptionValue(OPT_AUTO_ZOOM_TANK)
let currentAutoZoom = Computed(@()
  validate(currentAutoZoomRaw.value
      ?? autoZoomDefault.value,
    autoZoomList))
set_auto_zoom(currentAutoZoom.value, false)
currentAutoZoom.subscribe(@(v) set_auto_zoom(v, false))
let currentAutoZoomType = {
  locId = "options/auto_zoom"
  ctrlType = OCT_LIST
  value = currentAutoZoom
  setValue = @(v) currentAutoZoomRaw(v)
  onChangeValue = @(v) sendChange("auto_zoom", v)
  list = autoZoomList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/auto_zoom")
}

let moveDirectionList = [false, true]
let currentShowMoveDirection = mkOptionValue(OPT_SHOW_MOVE_DIRECTION, true, @(v) validate(v, moveDirectionList))
let showMoveDirection = {
  locId = "options/show_move_direction"
  ctrlType = OCT_LIST
  value = currentShowMoveDirection
  onChangeValue = @(v) sendChange("show_move_direction", v)
  list = moveDirectionList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/show_move_direction")
}

let moveDirectionInSightList = [false, true]
let currentShowMoveDirectionInSight = mkOptionValue(OPT_SHOW_MOVE_DIRECTION_IN_SIGHT, true,
  @(v) validate(v, moveDirectionInSightList))
let showModeDirectionInSight = {
  locId = "options/show_move_direction_in_sight"
  ctrlType = OCT_LIST
  value = currentShowMoveDirectionInSight
  onChangeValue = @(v) sendChange("show_move_direction_in_sight", v)
  list = moveDirectionInSightList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/show_move_direction_in_sight")
}

let grassInTankVisionList = [false, true]
let currentGrassInTankVision = mkOptionValue(OPT_SHOW_GRASS_IN_TANK_VISION, true, @(v) validate(v, grassInTankVisionList))
let showGrassInTankVision = {
  locId = "options/grass_in_tank_vision"
  ctrlType = OCT_LIST
  value = currentGrassInTankVision
  onChangeValue = @(v) sendChange("grass_in_tank_vision", v)
  list = grassInTankVisionList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/grass_in_tank_vision")
}

let hudScoreTankList = ["score", "kills"]
let hudScoreTankRaw = mkOptionValue(OPT_HUD_TANK_SHOW_SCORE)
let hudScoreTank = Computed(@() validate(hudScoreTankRaw.get() ?? "kills", hudScoreTankList))
let optHudScoreTank = {
  locId = "options/tankHudScores"
  ctrlType = OCT_LIST
  value = hudScoreTank
  setValue = @(v) hudScoreTankRaw(v)
  onChangeValue = @(v) sendChange("tankHudScores", v)
  list = hudScoreTankList
  valToString = @(v) loc($"multiplayer/{v}")
}

return {
  currentGearDownOnStopButtonTouch
  currentTargetTrackingType
  currentArmorPiercingFixed
  hudScoreTank
  tankControlsOptions = [
    tankMoveControlType
    cameraSenseSlider(CAM_TYPE_NORMAL_TANK, "options/camera_sensitivity", OPT_CAMERA_SENSE_TANK, getOptValue(OPT_CAMERA_SENSE)?? 1.0)
    cameraSenseSlider(CAM_TYPE_FREE_TANK, "options/free_camera_sensitivity_tank", OPT_FREE_CAMERA_TANK, 2.0, 0.5, 8.0)
    cameraSenseSlider(CAM_TYPE_BINOCULAR_TANK, "options/camera_sensitivity_in_zoom", OPT_CAMERA_SENSE_IN_ZOOM_TANK, getOptValue(OPT_CAMERA_SENSE_IN_ZOOM)?? 1.0)
    gearDownOnStopButtonTouch
    targetTrackingType
    // tankTargetControlType
    showMoveDirection
    showModeDirectionInSight
    showGrassInTankVision
    currentArmorPiercingType
    showReticleButtonTouch
    currentAutoZoomType
    optHudScoreTank
  ]
}
