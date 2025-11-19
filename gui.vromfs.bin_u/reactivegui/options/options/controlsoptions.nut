from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { eventbus_send } = require("eventbus")
let { DBGLEVEL } = require("dagor.system")
let { OPT_HAPTIC_INTENSITY, OPT_HAPTIC_INTENSITY_ON_SHOOT, OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT,
  OPT_HAPTIC_INTENSITY_ON_COLLISION, OPT_CAMERA_ROTATION_ASSIST, mkOptionValue
} = require("%rGui/options/guiOptions.nut")
let { set_camera_sens, set_camera_rotation_assist } = require("controlsOptions")
let { setHapticIntensity, ON_SHOOT, ON_HERO_GET_SHOT, ON_COLLISION } = require("hapticVibration")
let { get_option_multiplier, set_option_multiplier, OPTION_FREE_CAMERA_INERTIA } = require("gameOptions")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { openTuningRecommended } = require("%rGui/hudTuning/hudTuningState.nut")
let { openVoiceMsgPieEditor } = require("%rGui/hud/voiceMsg/voiceMsgPieEditor.nut")
let { hudReloadStyleOption } = require("%rGui/options/options/hudStyleOptions.nut")

function cameraSenseSlider(camType, locId, optId, cur = 1.0, minVal = 0.03, maxVal = 5.97, stepVal = 0.0297) {
  let value = mkOptionValue(optId, cur)
  set_camera_sens(camType, value.get())
  value.subscribe(@(v) set_camera_sens(camType, v))
  return {
    locId
    value
    ctrlType = OCT_SLIDER
    valToString = @(v) $"{(((v-minVal)/(maxVal - minVal))*200 + 0.5).tointeger()}%"
    ctrlOverride = {
      min = minVal
      max = maxVal
      unit = stepVal
    }
  }
}

function hapticIntensitySlider(locId, optId, intensityType = -1) {
  let value = mkOptionValue(optId, 1.0)
  setHapticIntensity(value.get(), intensityType)
  value.subscribe(@(v) setHapticIntensity(v, intensityType))
  return {
    locId
    value
    ctrlType = OCT_SLIDER
    valToString = @(v) $"{(v*100 + 0.5).tointeger()}%"
    ctrlOverride = {
      min = 0
      max = 1
      unit = 0.01
    }
  }
}

let freeCameraInertia = Watched(get_option_multiplier(OPTION_FREE_CAMERA_INERTIA))
isOnlineSettingsAvailable.subscribe(@(_) freeCameraInertia.set(get_option_multiplier(OPTION_FREE_CAMERA_INERTIA)))
let optFreeCameraInertia = {
  locId = "options/free_camera_inertia"
  value = freeCameraInertia
  function setValue(v) {
    freeCameraInertia.set(v)
    set_option_multiplier(OPTION_FREE_CAMERA_INERTIA, v)
    eventbus_send("saveProfile", {})
  }
  ctrlType = OCT_SLIDER
  valToString = @(v) $"{(100 * v + 0.5).tointeger()}%"
  ctrlOverride = {
    min = 0
    max = 1.0
    unit = 0.01
  }
}

let validate = @(val, list) list.contains(val) ? val : list[0]

let cameraRotationAssistList = [false, true]
let currentCameraRotationAssist = mkOptionValue(OPT_CAMERA_ROTATION_ASSIST, true, @(v) validate(v, cameraRotationAssistList))
set_camera_rotation_assist(currentCameraRotationAssist.get())
currentCameraRotationAssist.subscribe(@(v) set_camera_rotation_assist(v))
let cameraRotationAssist = {
  locId = "options/camera_rotation_assist"
  ctrlType = OCT_LIST
  value = currentCameraRotationAssist
  list = cameraRotationAssistList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/camera_rotation_assist")
}

return {
  cameraSenseSlider
  controlsOptions = [
    [
      {
        locId = "hudTuning/open"
        ctrlType = OCT_BUTTON
        onClick = openTuningRecommended
      }
      {
        locId = "radio_messages_menu/editor"
        ctrlType = OCT_BUTTON
        onClick = openVoiceMsgPieEditor
      }
    ]
    hapticIntensitySlider("options/vibration", OPT_HAPTIC_INTENSITY)
    hapticIntensitySlider("options/vibration_on_shoot", OPT_HAPTIC_INTENSITY_ON_SHOOT, ON_SHOOT)
    hapticIntensitySlider("options/vibration_on_hero_get_shot", OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT, ON_HERO_GET_SHOT)
    hapticIntensitySlider("options/vibration_on_collision", OPT_HAPTIC_INTENSITY_ON_COLLISION, ON_COLLISION)
    DBGLEVEL > 0 ? optFreeCameraInertia : null
    cameraRotationAssist
    hudReloadStyleOption
  ]
}
