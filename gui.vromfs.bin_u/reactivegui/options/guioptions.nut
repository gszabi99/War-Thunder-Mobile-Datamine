let { addUserOption, get_gui_option, set_gui_option } = require("guiOptions")
let { send } = require("eventbus")
let { Watched } = require("frp")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")

//options should have full list on get profile for correct load
let optList = [
  "OPT_TANK_MOVEMENT_CONTROL"
  // "OPT_TANK_TARGETING_CONTROL"
  "OPT_GRAPHICS_QUALITY"
  "OPT_CAMERA_SENSE"
  "OPT_CAMERA_SENSE_IN_ZOOM"
  "OPT_HAPTIC_INTENSITY"
  "OPT_HAPTIC_INTENSITY_ON_SHOOT"
  "OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT"
  "OPT_HAPTIC_INTENSITY_ON_COLLISION"
  "OPT_FPS"
  "OPT_RAYTRACING"
  "OPT_TARGET_TRACKING"
  "OPT_SHOW_MOVE_DIRECTION"
  "OPT_ARMOR_PIERCING_FIXED"
]

let export = {}
foreach (id in optList)
  export[id] <- addUserOption(id)

let function mkOptionValue(id, defValue = null, validate = @(v) v) {
  let getSaved = @() validate(get_gui_option(id) ?? defValue)
  let value = Watched(isOnlineSettingsAvailable.value ? getSaved() : validate(defValue))
  isOnlineSettingsAvailable.subscribe(@(_) value(getSaved()))
  value.subscribe(function(v) {
    set_gui_option(id, v)
    send("saveProfile", {})
  })
  return value
}

return export.__update({
  mkOptionValue
})