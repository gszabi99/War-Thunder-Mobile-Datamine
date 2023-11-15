from "%globalsDarg/darg_library.nut" import *
let { addUserOption, addLocalUserOption, get_gui_option, set_gui_option } = require("guiOptions")
let { send } = require("eventbus")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")

//options should have full list on get profile for correct load
let optListNative = [
  "OPT_TANK_MOVEMENT_CONTROL"
  "OPT_CAMERA_SENSE"
  "OPT_FREE_CAMERA_TANK"
  "OPT_FREE_CAMERA_PLANE"
  "OPT_SHOW_MOVE_DIRECTION"
  "OPT_TARGET_TRACKING"
  "OPT_SHOW_RETICLE"
]

let optListLocalNative = [
  "OPT_GRAPHICS_QUALITY"
  "OPT_FPS"
  "OPT_RAYTRACING"
]

let optListScriptOnly = [
  // "OPT_TANK_TARGETING_CONTROL"
  "OPT_CAMERA_SENSE_IN_ZOOM"
  "OPT_HAPTIC_INTENSITY"
  "OPT_HAPTIC_INTENSITY_ON_SHOOT"
  "OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT"
  "OPT_HAPTIC_INTENSITY_ON_COLLISION"
  "OPT_ARMOR_PIERCING_FIXED"
  "OPT_AUTO_ZOOM" // 1.3.0 compatibility
  "OPT_AUTO_ZOOM_TANK"
  "OPT_AUTO_ZOOM_SHIP"
  "OPT_GEAR_DOWN_ON_STOP_BUTTON"
  "OPT_CAMERA_ROTATION_ASSIST"
  "OPT_HUD_TANK_SHOW_SCORE"
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

let function mkOptionValueNative(id, defValue, validate) {
  let getSaved = @() validate(get_gui_option(id) ?? defValue)
  let value = Watched(isSettingsAvailable.value ? getSaved() : validate(defValue))
  let function updateSaved() {
    if (!isSettingsAvailable.value || get_gui_option(id) == value.value)
      return
    set_gui_option(id, value.value)
    send("saveProfile", {})
  }
  updateSaved()
  isSettingsAvailable.subscribe(function(_) {
    value(getSaved())
    updateSaved()
  })
  value.subscribe(@(_) updateSaved())
  return value
}

let function mkOptionValueScriptOnly(id, defValue, validate) {
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
  value.subscribe(function(v) {
    if (isInit) {
      isInit = false
      return
    }
    set_gui_option(id, v)
    send("saveProfile", {})
  })
  return value
}

let optionValues = {}
let function mkOptionValue(id, defValue = null, validate = @(v) v) {
  if (id in optionValues) {
    logerr($"Try to init option value twice")
    return optionValues[id]
  }
  let ctor = (id in nativeOptions || id in optListLocalNative) ? mkOptionValueNative : mkOptionValueScriptOnly
  optionValues[id] <- ctor(id, defValue, validate)
  return optionValues[id]
}

return export.__update({
  mkOptionValue
})