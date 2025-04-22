from "%scripts/dagui_natives.nut" import is_freecam_enabled, set_option_hud_screen_safe_area, set_hud_width_limit
from "%scripts/dagui_library.nut" import *
from "hudState" import hud_is_in_cutscene, is_hud_visible

let { eventbus_subscribe } = require("eventbus")
let { safeArea } = require("%appGlobals/safeArea.nut")
let { broadcastEvent } = require("%sqStdLibs/helpers/subscriptions.nut")
let initOptions = require("%scripts/options/initOptions.nut")
let { isInRespawn } = require("%appGlobals/clientState/respawnStateBase.nut")
let { isInBattle, isHudVisible } = require("%appGlobals/clientState/clientState.nut")
let { curHudType, HT_HUD, HT_FREECAM, HT_CUTSCENE, HT_BENCHMARK, HT_NONE
} = require("%appGlobals/clientState/hudState.nut")
let updateClientStates = require("%scripts/clientState/updateClientStates.nut")
let { is_benchmark_game_mode } = require("mission")
let { g_hud_event_manager } = require("%scripts/hud/hudEventManager.nut")

isHudVisible(is_hud_visible())

function getHudType() {
  if (!isHudVisible.value)
    return HT_NONE
  if (hud_is_in_cutscene())
    return HT_CUTSCENE
  if (is_benchmark_game_mode())
    return HT_BENCHMARK
  if (is_freecam_enabled())
    return HT_FREECAM
  return HT_HUD
}

function updateHudType() {
  curHudType(getHudType())
}

if (isHudVisible.value) {
  updateHudType()
}

local isInited = false
function initHudOptionsOnce() {
  if (isInited)
    return

  initOptions()
  g_hud_event_manager.init()
  g_hud_event_manager.subscribe("ReinitHud", @(_) updateHudType())
  g_hud_event_manager.subscribe("Cutscene", @(_) updateHudType())
  set_hud_width_limit(safeArea)
  set_option_hud_screen_safe_area(safeArea)
  isInited = true
}

isInBattle.subscribe(@(_) isInited = false)

function startHud(...) {
  updateClientStates()
  initHudOptionsOnce()
  updateHudType()
  isInRespawn.update(false)
}

eventbus_subscribe("gui_start_hud", startHud)
eventbus_subscribe("gui_start_hud_no_chat", startHud) 
eventbus_subscribe("preload_ingame_scenes", startHud)

eventbus_subscribe("on_show_hud", function on_show_hud(payload) {
  let {show = true} = payload
  isHudVisible(show)
  updateHudType()
  broadcastEvent("ShowHud", { show })
})
