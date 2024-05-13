from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { get_common_local_settings_blk, get_settings_blk } = require("blkGetters")
let { get_maximum_frames_per_second, is_broken_grass_flag_set, is_texture_uhq_supported, should_notify_about_restart,
  get_platform_window_resolution, get_default_graphics_preset
} = require("graphicsOptions")
let { inline_raytracing_available, get_user_system_info } = require("sysinfo")
let { OPT_GRAPHICS_QUALITY, OPT_FPS, OPT_RAYTRACING, OPT_GRAPHICS_SCENE_RESOLUTION, mkOptionValue
} = require("%rGui/options/guiOptions.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { is_pc, is_android, is_ios } = require("%sqstd/platform.nut")
let { has_additional_graphics_content } = require("%appGlobals/permissions.nut")

let qualitiesListDev = ["movie"]
let minMemory = 4096
let deviceSH = get_platform_window_resolution().height
let qualitiesList = (get_settings_blk()?.graphics.forceLowPreset ?? false) ? ["low"]
  : (is_android && (get_user_system_info()?.physicalMemory ?? minMemory) < minMemory) ? ["low", "medium"]
  : (is_android && deviceSH < 1080) ? ["low", "medium", "high"]
  : ["low", "medium", "high", "max"].extend(is_pc ? qualitiesListDev : [])
let validateQuality = @(q) qualitiesList.contains(q) ? q : qualitiesList[0]
let defaultQuality = validateQuality(get_default_graphics_preset())
let graphicsQuality = mkOptionValue(OPT_GRAPHICS_QUALITY, defaultQuality, validateQuality)

let resolutionList = (get_settings_blk()?.graphics.forceLowPreset ?? false) ? ["low"]
  : (is_android && (get_user_system_info()?.physicalMemory ?? minMemory) < minMemory) ? ["low", "medium"]
  : ["low", "medium", "high"]

let validateResolution = @(q) resolutionList.contains(q) ? q : resolutionList[0]

function getResolutionByQuality(quality) {
  let graphicsPresets = (is_android || is_pc) ? (get_settings_blk()?.android_presets) : get_settings_blk()?.ios_presets
  return validateResolution(graphicsPresets?[quality].graphics.sceneResolutionPreset ?? "medium")
}

let resolutionValue = mkOptionValue(OPT_GRAPHICS_SCENE_RESOLUTION,
  getResolutionByQuality(get_default_graphics_preset()),
  validateResolution)

function setGraphicsQuality(v) {
  if (!qualitiesList.contains(v))
    return

  graphicsQuality(v)
  resolutionValue(getResolutionByQuality(v))

  if (is_broken_grass_flag_set() && (v == "high" || v == "max"))
    openFMsgBox({ text = loc("msg/qualityNotFullySupported") })
}

let optQuality = {
  locId = "options/graphicQuality"
  ctrlType = OCT_LIST
  value = graphicsQuality
  list = qualitiesList
  valToString = @(v) loc($"options/quality_{v}")
  setValue = setGraphicsQuality
}

let optResolution = {
  locId = "options/graphicResolution"
  ctrlType = OCT_LIST
  value = resolutionValue
  list = resolutionList
  valToString = @(v) loc($"options/resolution_{v}")
  function setValue(v) {
    resolutionValue(v)
  }
}

let allFpsValues = [30, 60, 120]
let fpsValue = mkOptionValue(OPT_FPS, allFpsValues[0])
let maxFps = get_maximum_frames_per_second()
let optFpsLimit = {
  locId = "options/fps_limit"
  ctrlType = OCT_LIST
  value = fpsValue
  list = maxFps < allFpsValues[0] ? allFpsValues : allFpsValues.filter(@(v) v <= maxFps)
  function setValue(v) {
    fpsValue(v)
    if (v == 120) {
      if (is_ios)
        resolutionValue(validateResolution(get_settings_blk()?.sceneResolutionPresetAt120 ?? "low"))

      openFMsgBox({ text = loc("msg/deviceMayStartToWarmUp") })
    }
  }
}

let rayTracingValues = [0, 1, 2]
let optRayTracing = {
  locId = "options/raytracing"
  ctrlType = OCT_LIST
  value = mkOptionValue(OPT_RAYTRACING, 0)
  list = rayTracingValues
  valToString = @(v) loc(v == 0 ? "options/off"
    : v == 1 ? $"options/quality_medium"
    : $"options/quality_high")
}
let isUhqSupported = is_texture_uhq_supported()
let needUhqTexturesRaw = Watched(isUhqSupported
  && !!get_common_local_settings_blk()?.uhqTextures) //machine storage

let needShowRestartNotify = Watched(should_notify_about_restart())
eventbus_subscribe("presets.scaleChanged", @(params) needShowRestartNotify(params?.status ?? false))

let restartTxt = @() !needShowRestartNotify.get() ? { watch = needShowRestartNotify }
: {
    watch = needShowRestartNotify
    hplace = ALIGN_CENTER
    rendObj = ROBJ_TEXT
    text = loc("msg/needRestartToApplySettings")
}.__update(fontTiny)

let needUhqTextures = Computed(@() needUhqTexturesRaw.value && has_additional_graphics_content.value)
function setNeedUhqTextures(v) {
  get_common_local_settings_blk().uhqTextures = v
  needUhqTexturesRaw(v)
  eventbus_send("saveProfile", {})
  if (v)
    openFMsgBox({ text = loc("msg/needRestartToApplyTextures") })
}
let optUhqTextures = {
  locId = "options/uhq_textures"
  ctrlType = OCT_LIST
  value = needUhqTextures
  setValue = setNeedUhqTextures
  list = Computed(@() has_additional_graphics_content.value ? [false, true] : [])
  valToString = @(v) loc(v ? "msgbox/btn_download" : "options/off")
}

return {
  graphicOptions = [
    optQuality
    { comp = restartTxt }
    optResolution
    optFpsLimit
    inline_raytracing_available() ? optRayTracing : null
    isUhqSupported ? optUhqTextures : null
  ]
  isUhqAllowed = Computed(@() isUhqSupported && has_additional_graphics_content.value)
  needUhqTextures
  setNeedUhqTextures
  graphicsQuality = Computed(@() graphicsQuality.get())
  setGraphicsQuality
}