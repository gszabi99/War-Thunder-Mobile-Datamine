from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { get_default_graphics_preset, get_default_fps_limit, get_maximum_frames_per_second
} = require("graphicsOptions")
let { OPT_GRAPHICS_QUALITY, OPT_FPS, OPT_RAYTRACING, mkOptionValue
} = require("%rGui/options/guiOptions.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { is_ios } = require("%sqstd/platform.nut")
let { inline_raytracing_available } = require("sysinfo")

let qualitiesList = ["low", "medium", "high", "max"]
let validateQuality = @(q) qualitiesList.contains(q) ? q : qualitiesList[0]
let optQuality = {
  locId = "options/graphicQuality"
  ctrlType = OCT_LIST
  value = mkOptionValue(OPT_GRAPHICS_QUALITY, get_default_graphics_preset(), validateQuality)
  list = qualitiesList
  valToString = @(v) loc($"options/quality_{v}")
}

let fpsValue = mkOptionValue(OPT_FPS, get_default_fps_limit())
let allFpsValues = [30, 60, 120]
let maxFps = get_maximum_frames_per_second()
let optFpsLimit = {
  locId = "options/fps_limit"
  ctrlType = OCT_LIST
  value = fpsValue
  list = maxFps < allFpsValues[0] ? allFpsValues : allFpsValues.filter(@(v) v <= maxFps)
  function setValue(v) {
    fpsValue(v)
    if (v == 120)
      openMsgBox({ text = loc("msg/deviceMayStartToWarmUp") })
  }
}

let optRayTracing = {
  locId = "options/raytracing"
  ctrlType = OCT_LIST
  value = mkOptionValue(OPT_RAYTRACING, false)
  list = [0, 1, 2]
  valToString = @(v) loc(v == 0 ? "options/off" : (v == 1 ? $"options/quality_medium" : $"options/quality_high"))
}

return [
  is_ios ? null : optQuality,
  optFpsLimit,
  (inline_raytracing_available() && !is_ios) ? optRayTracing : null
]