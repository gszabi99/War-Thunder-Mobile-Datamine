from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "hudState" import hud_is_in_cutscene, is_hud_visible
from "mission" import is_benchmark_game_mode
from "%appGlobals/clientState/clientState.nut" import isInBattle, isHudVisible
from "%appGlobals/clientState/hudState.nut" import curHudType, HT_HUD, HT_FREECAM, HT_CUTSCENE, HT_BENCHMARK, HT_NONE
from "%appGlobals/clientState/respawnStateBase.nut" import isInRespawn
from "%appGlobals/safeArea.nut" import safeAreaW
import "%appGlobals/clientState/updateClientStates.nut" as updateClientStates
from "app" import is_freecam_enabled
from "gameplayOptions" import set_option_hud_screen_safe_area, set_hud_width_limit
from "%rGui/hud/hudEventManager.nut" import initHudEventMgr, subscribeHudEvent
let initOptions = require("%rGui/options/initOptions.nut")


isHudVisible.set(is_hud_visible())

function getHudType() {
  if (!isHudVisible.get())
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
  curHudType.set(getHudType())
}

if (isHudVisible.get()) {
  updateHudType()
}

subscribeHudEvent("ReinitHud", @(_) updateHudType())
subscribeHudEvent("Cutscene", @(_) updateHudType())

local isInited = false
function initHudOptionsOnce() {
  if (isInited)
    return

  initOptions()
  initHudEventMgr()
  set_hud_width_limit(safeAreaW)
  set_option_hud_screen_safe_area(safeAreaW)
  isInited = true
}

isInBattle.subscribe(@(_) isInited = false)

function startHud(...) {
  updateClientStates()
  initHudOptionsOnce()
  updateHudType()
  isInRespawn.set(false)
}

eventbus_subscribe("gui_start_hud", startHud)
eventbus_subscribe("gui_start_hud_no_chat", startHud) 
eventbus_subscribe("preload_ingame_scenes", startHud)

eventbus_subscribe("on_show_hud", function on_show_hud(payload) {
  let {show = true} = payload
  isHudVisible.set(show)
  updateHudType()
})
