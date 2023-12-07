from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { send, subscribe } = require("eventbus")
let { get_common_local_settings_blk } = require("blkGetters")
let { get_maximum_frames_per_second, is_broken_grass_flag_set, is_texture_uhq_supported, should_notify_about_restart
} = require("graphicsOptions")
let { inline_raytracing_available, get_user_system_info } = require("sysinfo")
let { OPT_GRAPHICS_QUALITY, OPT_FPS, OPT_RAYTRACING, mkOptionValue
} = require("%rGui/options/guiOptions.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { is_pc, is_android } = require("%sqstd/platform.nut")
let { has_additional_graphics_content } = require("%appGlobals/permissions.nut")

let qualitiesListDev = ["movie"]
let minMemory = 4096
let qualitiesList = is_android && (get_user_system_info()?.physicalMemory ?? minMemory) < minMemory
  ? ["low", "medium"]
  : ["low", "medium", "high", "max"].extend(is_pc ? qualitiesListDev : [])
let validateQuality = @(q) qualitiesList.contains(q) ? q : qualitiesList[0]
let qualityValue = mkOptionValue(OPT_GRAPHICS_QUALITY, qualitiesList[0], validateQuality)
let optQuality = {
  locId = "options/graphicQuality"
  ctrlType = OCT_LIST
  value = qualityValue
  list = qualitiesList
  valToString = @(v) loc($"options/quality_{v}")
  function setValue(v) {
    qualityValue(v)
    if (is_broken_grass_flag_set() && (v == "high" || v == "max"))
      openFMsgBox({ text = loc("msg/qualityNotFullySupported") })
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
    if (v == 120)
      openFMsgBox({ text = loc("msg/deviceMayStartToWarmUp") })
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
subscribe("presets.scaleChanged", @(params) needShowRestartNotify(params?.status ?? false))

let restartTxt = @() !needShowRestartNotify.get() ? { watch = needShowRestartNotify }
: {
    watch = needShowRestartNotify
    hplace = ALIGN_CENTER
    rendObj = ROBJ_TEXT
    text = loc("msg/needRestartToApplySettings")
}.__update(fontTiny)

let needUhqTextures = Computed(@() needUhqTexturesRaw.value && has_additional_graphics_content.value)
let function setNeedUhqTextures(v) {
  get_common_local_settings_blk().uhqTextures = v
  needUhqTexturesRaw(v)
  send("saveProfile", {})
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
    optFpsLimit
    inline_raytracing_available() ? optRayTracing : null
    isUhqSupported ? optUhqTextures : null
  ]
  isUhqAllowed = Computed(@() isUhqSupported && has_additional_graphics_content.value)
  needUhqTextures
  setNeedUhqTextures
}