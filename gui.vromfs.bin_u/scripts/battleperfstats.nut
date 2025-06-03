from "%scripts/dagui_library.nut" import *
import "%globalScripts/ecs.nut" as ecs
let { get_platform_string_id } = require("platform")
let { get_mp_session_id_int } = require("multiplayer")
let { EventOnSetupFrameTimes } = require("gameEvents")
let { get_game_version_str, get_base_game_version_str } = require("app")
let { get_common_local_settings_blk } = require("blkGetters")
let { is_texture_uhq_supported } = require("graphicsOptions")
let { get_gui_option, addLocalUserOption } = require("guiOptions")
let { has_additional_graphics_content } = require("%appGlobals/permissions.nut")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")


let OPT_GRAPHICS_QUALITY = addLocalUserOption("OPT_GRAPHICS_QUALITY")
let OPT_FPS = addLocalUserOption("OPT_FPS")
let OPT_RAYTRACING = addLocalUserOption("OPT_RAYTRACING")
let OPT_AA = addLocalUserOption("OPT_AA")

let segments = [
  [0, 5],
  [5, 15],
  [15, 25],
  [25, 30],
  [30, 35],
  [35, 40],
  [40, 50],
  [50, 60],
  [60, 80],
  [80, 100],
  [100, 110],
  [110, 120],
  [120, 130],
  [130, 150],
  [150, 200],
  [200, "plus"],
]

let segmentName = @(minFps, maxFps) $"battle_perfstat__segment_{minFps}_{maxFps}"

let isUhq = @() has_additional_graphics_content.get()
  && is_texture_uhq_supported()
  && !!get_common_local_settings_blk()?.uhqTextures

ecs.register_es("battle_pefstats_es", {
  [EventOnSetupFrameTimes] = function (_eid, comp) {
    let battle_perfstat__segments = {}
    foreach (segment in segments)
      battle_perfstat__segments[$"segment_{segment[0]}_{segment[1]}"] <- comp[segmentName(segment[0], segment[1])]

    let data = battle_perfstat__segments.__update({
      platform = get_platform_string_id()
      fpsLimit = get_gui_option(OPT_FPS)
      videoSetting = get_gui_option(OPT_GRAPHICS_QUALITY)
      raytracing = get_gui_option(OPT_RAYTRACING)
      sessionId = get_mp_session_id_int()
      gameVersion = get_game_version_str()
      apkVersion = get_base_game_version_str()
      isUltraHigh = isUhq()
      aa = get_gui_option(OPT_AA)
      peakMemory = comp.battle_perfstat__peakMemoryKb
    })
    sendCustomBqEvent("battle_perfstat_1", data)
  }
}, {
  comps_ro = [
    ["battle_perfstat__peakMemoryKb", ecs.TYPE_INT]
  ].extend(segments.map(@(v) [segmentName(v[0], v[1]), ecs.TYPE_FLOAT]))
})