from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
from "controlsOptions" import set_camera_sens, set_camera_rotation_assist
from "dagor.system" import DBGLEVEL
from "dagor.workcycle" import defer
from "eventbus" import eventbus_send
from "gameOptions" import get_option_multiplier, set_option_multiplier, OPTION_FREE_CAMERA_INERTIA
from "hapticVibration" import setHapticIntensity, ON_SHOOT, ON_HERO_GET_SHOT, ON_COLLISION, useGamepadHaptic
from "%appGlobals/loginState.nut" import isOnlineSettingsAvailable, isSettingsAvailable
from "%rGui/controlsMenu/gamepadVendor.nut" import hasGamepadConnected
from "%rGui/hud/voiceMsg/voiceMsgPieEditor.nut" import openVoiceMsgPieEditor
from "%rGui/hudTuning/hudTuningState.nut" import openTuningRecommended
from "%rGui/options/guiOptions.nut" import OPT_HAPTIC_INTENSITY, OPT_HAPTIC_INTENSITY_ON_SHOOT,
  OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT, OPT_HAPTIC_INTENSITY_ON_COLLISION, OPT_CAMERA_ROTATION_ASSIST, mkOptionValue,
  OPT_GAMEPAD_VIBRATION
from "%rGui/options/options/hudStyleOptions.nut" import hudReloadStyleOption


function cameraSenseSlider(camType, locId, optId, defVal = 1.0, minVal = 0.03, maxVal = 5.97, stepVal = 0.0297) {
  let value = mkOptionValue(optId, defVal)
  set_camera_sens(camType, value.get())
  value.subscribe(@(v) set_camera_sens(camType, v))
  isSettingsAvailable.subscribe(function(v) {
    if (v)
      defer(@() set_camera_sens(camType, value.get()))
  })
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
  isSettingsAvailable.subscribe(function(v) {
    if (v)
      defer(@() setHapticIntensity(value.get(), intensityType))
  })
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

let gamepadVibrationValue = mkOptionValue(OPT_GAMEPAD_VIBRATION, true)
gamepadVibrationValue.subscribe(useGamepadHaptic)
useGamepadHaptic(gamepadVibrationValue.get())

let gamepadHaptic = {
  locId = "options/vibration_on_gamepad"
  ctrlType = OCT_LIST
  value = gamepadVibrationValue
  list = [false, true]
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  visible = hasGamepadConnected
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
    gamepadHaptic
    hapticIntensitySlider("options/vibration", OPT_HAPTIC_INTENSITY)
    hapticIntensitySlider("options/vibration_on_shoot", OPT_HAPTIC_INTENSITY_ON_SHOOT, ON_SHOOT)
    hapticIntensitySlider("options/vibration_on_hero_get_shot", OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT, ON_HERO_GET_SHOT)
    hapticIntensitySlider("options/vibration_on_collision", OPT_HAPTIC_INTENSITY_ON_COLLISION, ON_COLLISION)
    DBGLEVEL > 0 ? optFreeCameraInertia : null
    cameraRotationAssist
    hudReloadStyleOption
  ]
}
