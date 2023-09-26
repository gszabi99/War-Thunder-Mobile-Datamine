from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { /* OPT_TANK_TARGETING_CONTROL,  */
  OPT_TARGET_TRACKING, OPT_SHOW_MOVE_DIRECTION, OPT_ARMOR_PIERCING_FIXED,
  OPT_AUTO_ZOOM, OPT_GEAR_DOWN_ON_STOP_BUTTON, OPT_CAMERA_ROTATION_ASSIST,
  OPT_SHOW_RETICLE, OPT_HUD_TANK_SHOW_SCORE, mkOptionValue
} = require("%rGui/options/guiOptions.nut")
let { set_should_target_tracking, set_camera_rotation_assist, set_armor_piercing_fixed, set_show_reticle,
  set_auto_zoom
} = require("controlsOptions")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { abTests } = require("%appGlobals/pServer/campaign.nut")
let { tankMoveCtrlTypesList, currentTankMoveCtrlType, ctrlTypeToString
} = require("%rGui/options/chooseMovementControls/tankMoveControlType.nut")
let { openChooseMovementControls
} = require("%rGui/options/chooseMovementControls/chooseMovementControlsState.nut")

let validate = @(val, list) list.contains(val) ? val : list[0]

let tankMoveControlType = {
  locId = "options/tank_movement_control"
  ctrlType = OCT_LIST
  value = currentTankMoveCtrlType
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
  list = targetTrackingList
  valToString = @(v) loc(v ? "options/auto" : "options/manual")
  description = loc("options/desc/target_tracking")
}

let armorPiercingFixedList = [false, true]
let piercingIndicatorDefault = Computed(@() (abTests.value?.fixedPiercingIndicator ?? "true") == "true")
let currentArmorPiercingFixedRaw = mkOptionValue(OPT_ARMOR_PIERCING_FIXED)
let currentArmorPiercingFixed = Computed(@()
  validate(currentArmorPiercingFixedRaw.value ?? piercingIndicatorDefault.value, armorPiercingFixedList))
set_armor_piercing_fixed(currentArmorPiercingFixed.value)
currentArmorPiercingFixed.subscribe(@(v) set_armor_piercing_fixed(v))
let currentArmorPiercingType = {
  locId = "options/armor_piercing_fixed"
  ctrlType = OCT_LIST
  value = currentArmorPiercingFixed
  setValue = @(v) currentArmorPiercingFixedRaw(v)
  list = armorPiercingFixedList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/armor_piercing_fixed")
}

let autoZoomList = [false, true]
let autoZoomDefault = Computed(@() (abTests.value?.tankAutoZoom ?? "false") == "true")
let currentAutoZoomRaw = mkOptionValue(OPT_AUTO_ZOOM)
let currentAutoZoom = Computed(@()
  validate(currentAutoZoomRaw.value ?? autoZoomDefault.value, autoZoomList))
set_auto_zoom(currentAutoZoom.value)
currentAutoZoom.subscribe(@(v) set_auto_zoom(v))
let currentAutoZoomType = {
  locId = "options/auto_zoom"
  ctrlType = OCT_LIST
  value = currentAutoZoom
  setValue = function(v) {
    sendUiBqEvent("options_changed_tank_auto_zoom", { id = v ? "true" : "false" })
    currentAutoZoomRaw(v)
  }
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
  list = moveDirectionList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/show_move_direction")
}


let cameraRotationAssistList = [false, true]
let cameraRotationAssistDefault = Computed(@() (abTests.value?.tankCameraRotationAssist ?? "true") == "true")
let currentCameraRotationAssistRaw = mkOptionValue(OPT_CAMERA_ROTATION_ASSIST)
let currentCameraRotationAssist = Computed(@() validate(
  currentCameraRotationAssistRaw.value ?? cameraRotationAssistDefault
  cameraRotationAssistList))
set_camera_rotation_assist(currentCameraRotationAssist.value)
currentCameraRotationAssist.subscribe(@(v) set_camera_rotation_assist(v))
let cameraRotationAssist = {
  locId = "options/camera_rotation_assist"
  ctrlType = OCT_LIST
  value = currentCameraRotationAssist
  function setValue(v) {
    currentCameraRotationAssistRaw(v)
    sendUiBqEvent("camera_rotation_assist_change", { id = v ? "true" : "false" })
  }
  list = cameraRotationAssistList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/camera_rotation_assist")
}

let hudScoreTankList = ["score", "kills"]
let hudScoreTankDefault = Computed(@() validate(abTests.value?.tankHudScores, hudScoreTankList))
let hudScoreTankRaw = mkOptionValue(OPT_HUD_TANK_SHOW_SCORE)
let hudScoreTank = Computed(@()
  validate(hudScoreTankRaw.value ?? hudScoreTankDefault.value, hudScoreTankList))
let optHudScoreTank = {
  locId = "options/tankHudScores"
  ctrlType = OCT_LIST
  value = hudScoreTank
  function setValue(v) {
    hudScoreTankRaw(v)
    sendUiBqEvent("tank_hud_scores_change", { id = v })
  }
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
    gearDownOnStopButtonTouch
    targetTrackingType
    // tankTargetControlType
    cameraRotationAssist
    showMoveDirection
    currentArmorPiercingType
    showReticleButtonTouch
    currentAutoZoomType
    optHudScoreTank
  ]
}
