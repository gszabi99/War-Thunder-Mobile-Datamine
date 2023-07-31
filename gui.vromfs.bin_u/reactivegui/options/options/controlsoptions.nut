from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { send } = require("eventbus")
let { DBGLEVEL } = require("dagor.system")
let { OPT_CAMERA_SENSE_IN_ZOOM, OPT_FREE_CAMERA_TANK, OPT_FREE_CAMERA_PLANE,
  OPT_CAMERA_SENSE, OPT_HAPTIC_INTENSITY, OPT_HAPTIC_INTENSITY_ON_SHOOT, OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT,
  OPT_HAPTIC_INTENSITY_ON_COLLISION, mkOptionValue
} = require("%rGui/options/guiOptions.nut")
let { CAM_TYPE_NORMAL, CAM_TYPE_BINOCULAR, CAM_TYPE_FREE_TANK=2, CAM_TYPE_FREE_PLANE=3, set_camera_sens } = require("controlsOptions")
let { setHapticIntensity, ON_SHOOT, ON_HERO_GET_SHOT, ON_COLLISION } = require("hapticVibration")
let { get_option_multiplier, set_option_multiplier, OPTION_FREE_CAMERA_INERTIA } = require("gameOptions")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { openTuningRecommended } = require("%rGui/hudTuning/hudTuningState.nut")

let function cameraSenseSlider(camType, locId, optId, cur = 1.0, minVal = 0.03, maxVal = 3.0) {
  let value = mkOptionValue(optId, cur)
  set_camera_sens(camType, value.value)
  value.subscribe(@(v) set_camera_sens(camType, v))
  return {
    locId
    value
    ctrlType = OCT_SLIDER
    valToString = @(v) $"{(((v-minVal)/(maxVal - minVal))*100 + 0.5).tointeger()}%"
    ctrlOverride = {
      min = minVal
      max = maxVal
      unit = 0.03 //step
    }
  }
}

let function hapticIntensitySlider(locId, optId, intensityType = -1) {
  let value = mkOptionValue(optId, 1.0)
  setHapticIntensity(value.value, intensityType)
  value.subscribe(@(v) setHapticIntensity(v, intensityType))
  return {
    locId
    value
    ctrlType = OCT_SLIDER
    valToString = @(v) $"{((v/3)*100 + 0.5).tointeger()}%"
    ctrlOverride = {
      min = 0
      max = 3
      unit = 0.03 //step
    }
  }
}

let freeCameraInertia = Watched(get_option_multiplier(OPTION_FREE_CAMERA_INERTIA))
isOnlineSettingsAvailable.subscribe(@(_) freeCameraInertia(get_option_multiplier(OPTION_FREE_CAMERA_INERTIA)))
let optFreeCameraInertia = {
  locId = "options/free_camera_inertia"
  value = freeCameraInertia
  function setValue(v) {
    freeCameraInertia(v)
    set_option_multiplier(OPTION_FREE_CAMERA_INERTIA, v)
    send("saveProfile", {})
  }
  ctrlType = OCT_SLIDER
  valToString = @(v) $"{(100 * v + 0.5).tointeger()}%"
  ctrlOverride = {
    min = 0
    max = 1.0
    unit = 0.01 //step
  }
}

return {
  controlsOptions = [
    {
      locId = "hudTuning/open"
      ctrlType = OCT_BUTTON
      onClick = openTuningRecommended
    }
    hapticIntensitySlider("options/vibration", OPT_HAPTIC_INTENSITY)
    hapticIntensitySlider("options/vibration_on_shoot", OPT_HAPTIC_INTENSITY_ON_SHOOT, ON_SHOOT)
    hapticIntensitySlider("options/vibration_on_hero_get_shot", OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT, ON_HERO_GET_SHOT)
    hapticIntensitySlider("options/vibration_on_collision", OPT_HAPTIC_INTENSITY_ON_COLLISION, ON_COLLISION)
    cameraSenseSlider(CAM_TYPE_NORMAL, "options/camera_sensitivity", OPT_CAMERA_SENSE)
    cameraSenseSlider(CAM_TYPE_BINOCULAR, "options/camera_sensitivity_in_zoom", OPT_CAMERA_SENSE_IN_ZOOM)
    cameraSenseSlider(CAM_TYPE_FREE_TANK, "options/free_camera_sensitivity_tank", OPT_FREE_CAMERA_TANK, 2.0, 0.5, 8.0)
    cameraSenseSlider(CAM_TYPE_FREE_PLANE, "options/free_camera_sensitivity_plane", OPT_FREE_CAMERA_PLANE, 0.5, 0.125, 2.0)
    DBGLEVEL > 0 ? optFreeCameraInertia : null
  ]
}
