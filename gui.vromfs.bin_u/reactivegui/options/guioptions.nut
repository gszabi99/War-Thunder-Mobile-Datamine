from "%globalsDarg/darg_library.nut" import *
let { addUserOption, addLocalUserOption, get_gui_option, set_gui_option } = require("guiOptions")
let { eventbus_send } = require("eventbus")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")

let optionsVersion = Watched(0)


let optListNative = [
  "OPT_TANK_MOVEMENT_CONTROL"
  "OPT_CAMERA_SENSE"
  "OPT_FREE_CAMERA_TANK"
  "OPT_FREE_CAMERA_PLANE"
  "OPT_SHOW_MOVE_DIRECTION"
  "OPT_SHOW_MOVE_DIRECTION_IN_SIGHT"
  "OPT_SHOW_GRASS_IN_TANK_VISION"
  "OPT_TARGET_TRACKING"
  "OPT_SHOW_RETICLE"
  "USEROPT_ENABLE_AUTO_HEALING"
]

let optListLocalNative = [
  "OPT_GRAPHICS_QUALITY"
  "OPT_FPS"
  "OPT_RAYTRACING"
  "OPT_GRAPHICS_SCENE_RESOLUTION"
  "OPT_AA"
]

let optListScriptOnly = [
  
  "OPT_CAMERA_SENSE_TANK"
  "OPT_CAMERA_SENSE_SHIP"
  "OPT_CAMERA_SENSE_PLANE"
  "OPT_CAMERA_SENSE_IN_ZOOM"
  "OPT_CAMERA_SENSE_IN_ZOOM_TANK"
  "OPT_CAMERA_SENSE_IN_ZOOM_SHIP"
  "OPT_CAMERA_SENSE_IN_ZOOM_PLANE"
  "OPT_HAPTIC_INTENSITY"
  "OPT_HAPTIC_INTENSITY_ON_SHOOT"
  "OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT"
  "OPT_HAPTIC_INTENSITY_ON_COLLISION"
  "OPT_ARMOR_PIERCING_FIXED"
  "OPT_AUTO_ZOOM_TANK"
  "OPT_AUTO_ZOOM_SHIP"
  "OPT_GEAR_DOWN_ON_STOP_BUTTON"
  "OPT_CAMERA_ROTATION_ASSIST"
  "OPT_HUD_TANK_SHOW_SCORE"
  "OPT_HUD_SHOW_UNIT_MODEL_NAME_ONLINE"
  "OPT_AIRCRAFT_FIXED_AIM_CURSOR"
  "OPT_STRATEGY_CAMERA_BY_DRAG"
  "OPT_AIRCRAFT_CONTINUOUS_TURN_MODE"
  "OPT_AIRCRAFT_THROTTLE_STICK"
  "OPT_AIRCRAFT_GYRO_CONTROL_FLAG_AILERONS"
  "OPT_AIRCRAFT_GYRO_CONTROL_AIM_MODE"
  "OPT_AIRCRAFT_GYRO_CONTROL_FLAG_DIRECT_CONTROL"
  "OPT_AIRCRAFT_GYRO_CONTROL_PARAM_DEAD_ZONE"
  "OPT_AIRCRAFT_GYRO_CONTROL_PARAM_SENSITIVITY"
  "OPT_AIRCRAFT_GYRO_CONTROL_PARAM_ELEVATOR_DEAD_ZONE"
  "OPT_AIRCRAFT_GYRO_CONTROL_PARAM_ELEVATOR_SENSITIVITY"
  "OPT_CAMERA_VISC_PLANE"
  "OPT_CAMERA_VISC_IN_ZOOM_PLANE"
  "OPT_CAMERA_VISC_PLANE_STICK"
  "OPT_CAMERA_VISC_IN_ZOOM_PLANE_STICK"
  "OPT_AIRCRAFT_INVERTED_Y"
  "OPT_AIRCRAFT_MOVEMENT_CONTROL"
  "OPT_TARGET_SELECTION_TYPE"
  "OPT_AIRCRAFT_ADDITIONAL_FLY_CONTROLS"
  "OPT_AIRCRAFT_TARGET_FOLLOWER"
  "USEROPT_QUIT_ZOOM_AFTER_KILL"
  "OPT_AIRCRAFT_FREE_CAMERA_BY_TOUCH"
  "USEROPT_ALLOW_JIP"
]

let optListLocalScriptOnly = [
  "OPT_AUTO_UPDATE_ENABLED"
  "OPT_SHOW_TOUCHES_ENABLED"
  "OPT_BACKGROUND_UPDATE_ENABLED"
]

let export = {}
let nativeOptions = {}
foreach (id in optListNative) {
  export[id] <- addUserOption(id)
  nativeOptions[export[id]] <- true
}
foreach (id in optListLocalNative) {
  export[id] <- addLocalUserOption(id)
  nativeOptions[export[id]] <- true
}
foreach (id in optListScriptOnly)
  export[id] <- addUserOption(id)
foreach (id in optListLocalScriptOnly)
  export[id] <- addLocalUserOption(id)

function mkOptionValueNative(id, defValue, validate) {
  let getSaved = @() validate(get_gui_option(id) ?? defValue)
  let value = Watched(isSettingsAvailable.value ? getSaved() : validate(defValue))
  function updateSaved() {
    if (!isSettingsAvailable.value || get_gui_option(id) == value.value)
      return
    set_gui_option(id, value.value)
    eventbus_send("saveProfile", {})
  }
  updateSaved()
  isSettingsAvailable.subscribe(function(_) {
    value(getSaved())
    updateSaved()
  })

  optionsVersion.subscribe(function(_) {
    value(validate(defValue))
    updateSaved()
  })

  value.subscribe(@(_) updateSaved())
  return value
}

function mkOptionValueScriptOnly(id, defValue, validate) {
  let getSaved = @() validate(get_gui_option(id) ?? defValue)
  let value = Watched(isSettingsAvailable.value ? getSaved() : validate(defValue))
  local isInit = false
  isSettingsAvailable.subscribe(function(_) {
    let v = getSaved()
    if (value.value == v)
      return
    isInit = true
    value(v)
  })

  optionsVersion.subscribe(function(_) {
    let v = validate(defValue)
    if (value.value == v)
      return
    isInit = true
    value(v)
  })

  value.subscribe(function(v) {
    if (isInit) {
      isInit = false
      return
    }
    set_gui_option(id, v)
    eventbus_send("saveProfile", {})
  })
  return value
}

let optionValues = {}
function mkOptionValue(id, defValue = null, validate = @(v) v) {
  if (id in optionValues) {
    logerr($"Try to init option value twice")
    return optionValues[id]
  }
  let ctor = (id in nativeOptions) ? mkOptionValueNative : mkOptionValueScriptOnly
  optionValues[id] <- ctor(id, defValue, validate)
  return optionValues[id]
}

let getOptValue = @(id) isSettingsAvailable.get() ? get_gui_option(id) : null

return export.__update({
  mkOptionValue
  getOptValue
  optionValues
  optionsVersion
})