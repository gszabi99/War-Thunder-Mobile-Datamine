from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { register_command } = require("console")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { 
  OPT_TARGET_TRACKING, OPT_SHOW_MOVE_DIRECTION, OPT_SHOW_MOVE_DIRECTION_IN_SIGHT, OPT_ARMOR_PIERCING_FIXED,
  OPT_AUTO_ZOOM_TANK, OPT_CAMERA_SENSE_IN_ZOOM_TANK, OPT_CAMERA_SENSE, OPT_TANK_ALTERNATIVE_CONTROL_TYPE,
  OPT_CAMERA_SENSE_IN_ZOOM, OPT_CAMERA_SENSE_TANK, OPT_FREE_CAMERA_TANK,
  OPT_SHOW_RETICLE, OPT_HUD_TANK_SHOW_SCORE, OPT_SHOW_GRASS_IN_TANK_VISION, USEROPT_ENABLE_AUTO_HEALING, mkOptionValue, getOptValue
} = require("%rGui/options/guiOptions.nut")
let { set_should_target_tracking, set_armor_piercing_fixed, set_show_reticle, set_enable_auto_healing, get_enable_auto_healing,
  set_auto_zoom, CAM_TYPE_NORMAL_TANK, CAM_TYPE_BINOCULAR_TANK, CAM_TYPE_FREE_TANK
} = require("controlsOptions")
let { has_option_tank_alternative_control } = require("%appGlobals/permissions.nut")
let { sendSettingChangeBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { abTests, firstLoginTime } = require("%appGlobals/pServer/campaign.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { cameraSenseSlider } =  require("%rGui/options/options/controlsOptions.nut")
let { tankMoveCtrlTypesList, currentTankMoveCtrlType, ctrlTypeToString
} = require("%rGui/options/chooseMovementControls/tankMoveControlType.nut")
let { gearDownOnStopButtonList, currentGearDownOnStopButtonTouch, showGearDownControl
} = require("%rGui/options/chooseMovementControls/gearDownControl.nut")
let { openChooseMovementControls
} = require("%rGui/options/chooseMovementControls/chooseMovementControlsState.nut")

let autoZoomDefaultTrueStart = 1699894800 
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

let isDebugTankAltControlType = hardPersistWatched("options.isDebugTankAltControlType", false)
let tankAltControlTypeButtonList = [false, true]
let tankAltControlTypeDefault = Computed(@()
  (isDebugTankAltControlType.get() == ((abTests.get()?.tankAltControlType ?? "false") == "true"))
    ? tankAltControlTypeButtonList[0]
    : tankAltControlTypeButtonList[1])
let currentTankAltControlTypeRaw = mkOptionValue(OPT_TANK_ALTERNATIVE_CONTROL_TYPE)
let setDefaultValueTankAltControlType = @() currentTankAltControlTypeRaw.get() == null
  ? currentTankAltControlTypeRaw.set(tankAltControlTypeDefault.get())
  : null
if (isLoggedIn.get())
  setDefaultValueTankAltControlType()
isLoggedIn.subscribe(@(v) v ? setDefaultValueTankAltControlType() : null)
let currentTankAltControlType = Computed(@()
  validate(currentTankAltControlTypeRaw.get() ?? tankAltControlTypeDefault.get(), tankAltControlTypeButtonList))
let tankAltControlType = {
  locId = "options/tank_alternative_control_type"
  ctrlType = OCT_LIST
  value = currentTankAltControlType
  setValue = @(v) currentTankAltControlTypeRaw(v)
  onChangeValue = @(v) sendChange("tank_alternative_control_type", v)
  list = tankAltControlTypeButtonList
  valToString = @(v) loc(v ? "options/controlType/alternative" : "options/controlType/default")
  visible = has_option_tank_alternative_control
  description = "\n".join([loc("options/desc/tank_alternative_control_type")].extend([
    "us_m4a3e8_76w_sherman",
    "germ_pzkpfw_V_ausf_d_panther",
    "ussr_is_2_1943"].map(@(v) $"- {loc(v)}")))
}

let gearDownOnStopButtonTouch = {
  locId = "options/gear_down_on_stop_button"
  ctrlType = OCT_LIST
  value = currentGearDownOnStopButtonTouch
  onChangeValue = @(v) sendChange("gear_down_on_stop_button", v)
  list = Computed(@() showGearDownControl.get() ? gearDownOnStopButtonList : [])
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
let autoZoomDefault = Computed(@() firstLoginTime.get() > autoZoomDefaultTrueStart)
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

let enableCrewAutoHealingList = [false, true]
let currentEnableCrewAutoHealing = mkOptionValue(USEROPT_ENABLE_AUTO_HEALING, get_enable_auto_healing(), @(v) validate(v, enableCrewAutoHealingList))
set_enable_auto_healing(currentEnableCrewAutoHealing.get())
currentEnableCrewAutoHealing.subscribe(@(v) set_enable_auto_healing(v))
let enableCrewAutoHealingType = {
  locId = "options/enable_auto_healing"
  ctrlType = OCT_LIST
  value = currentEnableCrewAutoHealing
  onChangeValue = @(v) sendChange("enable_auto_healing", v)
  list = enableCrewAutoHealingList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

register_command(function() {
  currentTankAltControlTypeRaw(null)
  isDebugTankAltControlType.set(!isDebugTankAltControlType.get())
}, "debug.toggleAbTest.tankAltControlType")

return {
  currentTargetTrackingType
  currentArmorPiercingFixed
  hudScoreTank
  tankControlsOptions = [
    tankMoveControlType
    tankAltControlType
    cameraSenseSlider(CAM_TYPE_NORMAL_TANK, "options/camera_sensitivity", OPT_CAMERA_SENSE_TANK, getOptValue(OPT_CAMERA_SENSE)?? 1.0)
    cameraSenseSlider(CAM_TYPE_FREE_TANK, "options/free_camera_sensitivity_tank", OPT_FREE_CAMERA_TANK, 2.0, 0.5, 15.5, 0.075)
    cameraSenseSlider(CAM_TYPE_BINOCULAR_TANK, "options/camera_sensitivity_in_zoom", OPT_CAMERA_SENSE_IN_ZOOM_TANK, getOptValue(OPT_CAMERA_SENSE_IN_ZOOM)?? 1.0)
    gearDownOnStopButtonTouch
    targetTrackingType
    
    showMoveDirection
    showModeDirectionInSight
    showGrassInTankVision
    currentArmorPiercingType
    showReticleButtonTouch
    currentAutoZoomType
    optHudScoreTank
    enableCrewAutoHealingType
  ]
}
