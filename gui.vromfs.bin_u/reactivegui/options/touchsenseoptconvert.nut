from "%globalsDarg/darg_library.nut" import *
let logOP = log_with_prefix("[OPTIONS_COMPATIBILITY] ")
let { get_base_game_version_str } = require("app")
let { fabs, round } = require("math")
let { register_command } = require("console")
let { eventbus_send } = require("eventbus")
let { get_game_params_blk, get_local_custom_settings_blk } = require("blkGetters")
let { get_user_system_info } = require("sysinfo")
let { get_platform_window_resolution } = require("graphicsOptions")
let { is_ios, is_android } = require("%sqstd/platform.nut")
let { check_version } = require("%sqstd/version_compare.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { optionValues, OPT_CAMERA_SENSE_TANK, OPT_CAMERA_SENSE_IN_ZOOM_TANK, OPT_CAMERA_SENSE_SHIP, OPT_CAMERA_SENSE_IN_ZOOM_SHIP,
} = require("%rGui/options/guiOptions.nut")

const SAVE_ID_TOUCH_SENSE_OPT_CONVERTED = "touchSenseOptConverted202410"
let DEFAULT_PPI = 360.0

let DEF_VAL = 1.0
let MIN_VAL = 0.03
let MAX_VAL = 3.0
let STEP_VAL = 0.03
let FLT_EPSILON = 0.005

let { getScreenPPI = @() DEFAULT_PPI } = is_ios ? require("ios.platform")
  : is_android ? require("android.platform")
  : null

// Need to convert options AFTER "isSettingsAvailable", because
// on "isSettingsAvailable" every option reads its value from profile settings.
let isReadyToConvert = isLoggedIn

let cameraSenseOptionsCfg = [
  OPT_CAMERA_SENSE_TANK
  OPT_CAMERA_SENSE_IN_ZOOM_TANK
  OPT_CAMERA_SENSE_SHIP
  OPT_CAMERA_SENSE_IN_ZOOM_SHIP
]

let normalizeVal = @(v) clamp(round(v / STEP_VAL) * STEP_VAL, MIN_VAL, MAX_VAL)
let isApproxEqual = @(v1, v2) fabs(v1 - v2) < FLT_EPSILON
let isNearDefault = @(v) fabs(v - normalizeVal(DEF_VAL)) < STEP_VAL + FLT_EPSILON

function convertCameraSenseOptionsToV202410() {
  let isConverted = get_local_custom_settings_blk()?[SAVE_ID_TOUCH_SENSE_OPT_CONVERTED] != null
  if (isConverted)
    return
  let isNewTouchSenseSupported = check_version(">=1.10.0.69", get_base_game_version_str())
  let isNewTouchSenseEnabled = get_game_params_blk()?.touchSensMultShip != null
  if (!isNewTouchSenseSupported || ! isNewTouchSenseEnabled)
    return
  let scrW = get_user_system_info()?.gameResolution.split(" x ")[0].tointeger() ?? 0
  let wndW = get_platform_window_resolution().width
  let ppi = getScreenPPI()
  logOP($"Converting Camera Sense options to v.202410 ({scrW}, {wndW}, {ppi} ppi)")
  if (is_android && (scrW <= 0 || wndW <= 0))
    logOP("Conversion skipped completely (unknown scrW or wndW, failed)")
  else if (is_android && scrW == wndW)
    logOP("Conversion skipped completely (scrW = wndW, no changes required)")
  else if (is_ios && ppi <= 0.0)
    logOP("Conversion skipped completely (unknown PPI, failed)")
  else if (is_ios && ppi == DEFAULT_PPI)
    logOP("Conversion skipped completely (default PPI, no changes required)")
  else {
    foreach (id in cameraSenseOptionsCfg) {
      let prevVal = optionValues?[id].get()
      if (prevVal == null) {
        logOP($"  {id} - Skipped (is null)")
        continue
      }
      if (isNearDefault(prevVal)) {
        logOP($"  {id} - Skipped ({prevVal}, is default)")
        continue
      }
      let newValRaw = is_android ? (prevVal * scrW / wndW)
        : is_ios ? (prevVal * ppi / DEFAULT_PPI)
        : prevVal
      let newVal = normalizeVal(newValRaw)
      if (isApproxEqual(prevVal, newVal)) {
        logOP($"  {id} - Skipped ({newVal}, no change required)")
        continue
      }
      optionValues[id].set(newVal)
      logOP($"  {id} - Converted: {prevVal} -> {newValRaw} -> {newVal}")
    }
  }
  get_local_custom_settings_blk()[SAVE_ID_TOUCH_SENSE_OPT_CONVERTED] = true
  eventbus_send("saveProfile", {})
}

function tryConvertOptions() {
  if (!isReadyToConvert.get())
    return
  convertCameraSenseOptionsToV202410()
}

isReadyToConvert.subscribe(@(v) v ? tryConvertOptions() : null)
tryConvertOptions()

register_command(function() {
    let isConverted = get_local_custom_settings_blk()?[SAVE_ID_TOUCH_SENSE_OPT_CONVERTED] != null
    console_print($"Applied conversion: {isConverted}") // warning disable: -forbidden-function
    foreach (id in cameraSenseOptionsCfg) {
      let val = optionValues?[id].get()
      let isDefault = val == DEF_VAL
      console_print($"    {id} = {val}{isDefault ? " (default)" : ""}") // warning disable: -forbidden-function
    }
  }, "ui.debug.camera_sense_options.print")

register_command(function() {
    foreach (id in cameraSenseOptionsCfg)
      if (optionValues?[id].get() != null)
        optionValues?[id].set(DEF_VAL)
    get_local_custom_settings_blk()[SAVE_ID_TOUCH_SENSE_OPT_CONVERTED] = null
    eventbus_send("saveProfile", {})
    console_print($"Camera Sense options reset to defaults") // warning disable: -forbidden-function
  }, "ui.debug.camera_sense_options.reset_to_defaults")
