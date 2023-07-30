from "%appGlobals/unitConst.nut" import *

let sameLoc = @(locId, scList) scList.map(@(value) { locId, value })
let cLoc = @(locId, value) { locId, value }

let shortcutsByUnitTypes = {
  [SHIP] = {
    shortcuts = [
      "ID_FLIGHTMENU", "ship_main_engine_rangeMax", "ship_main_engine_rangeMin",
      cLoc("hotkeys/primaryGun", "ID_SHIP_WEAPON_PRIMARY"),
      cLoc("hotkeys/secondaryGun", "ID_SHIP_WEAPON_SECONDARY"),
      cLoc("hotkeys/extraGun", "ID_SHIP_WEAPON_EXTRA_GUN_1"),
      "ID_SHIP_WEAPON_TORPEDOES", "ID_SHIP_SMOKE_SCREEN_GENERATOR", "ID_WTM_LAUNCH_AIRCRAFT",
      "ID_SHIP_WEAPON_MINE", "ID_NEXT_BULLET_TYPE", "ID_SHIP_ACTION_BAR_ITEM_11",
    ]
      .extend(sameLoc("hotkeys/steering", ["ship_steering_rangeMin", "ship_steering_rangeMax"]))
    axes = sameLoc("hotkeys/ID_PLANE_MOUSE_AIM_HEADER", ["ship_mouse_aim_x", "ship_mouse_aim_y"])
  },
  [SUBMARINE] = {
    shortcuts = [
      "ID_FLIGHTMENU", "submarine_main_engine_rangeMax", "submarine_main_engine_rangeMin",
      "ID_SUBMARINE_WEAPON_TORPEDOES", "ID_DIVING_LOCK", "ID_SHIP_WEAPON_MINE",
      "ID_SUBMARINE_ACTION_BAR_ITEM_11",
      cLoc("hotkeys/submarine_depth_rangeInc", "submarine_depth_inc"),
      cLoc("hotkeys/submarine_depth_rangeDec", "submarine_depth_dec"),
    ]
      .extend(sameLoc("hotkeys/steering", ["ship_steering_rangeMin", "ship_steering_rangeMax"]))
    axes = sameLoc("hotkeys/ID_PLANE_MOUSE_AIM_HEADER", ["submarine_mouse_aim_x", "submarine_mouse_aim_y"])
  },
  [AIR] = {
    shortcuts = [
      "ID_FLIGHTMENU", "ID_BOMBS", "ID_ROCKETS", "ID_FIRE_CANNONS", "ID_FIRE_MGUNS",
      "ID_LOCK_TARGET", "ID_ZOOM_TOGGLE",
      cLoc("hotkeys/ID_SHIP_WEAPON_TORPEDOES", "ID_WTM_AIRCRAFT_LAUNCH_TORPEDOES"),
    ]
    axes = [cLoc("controls/walker_throttle", "throttle_axis"), "ailerons"]
      .extend(sameLoc("controls/help/movement_direction_control", ["mouse_aim_x", "mouse_aim_y"]))
  },
  [TANK] = {
    shortcuts = [
      "ID_FLIGHTMENU", "ID_FIRE_GM", "ID_FIRE_GM_MACHINE_GUN", "ID_ZOOM_TOGGLE", "ID_NEXT_BULLET_TYPE",
      "ID_ACTION_BAR_ITEM_5", "ID_ACTION_BAR_ITEM_7", "ID_ACTION_BAR_ITEM_9", "ID_ACTION_BAR_ITEM_6",
      "ID_ACTION_BAR_ITEM_10", "ID_SMOKE_SCREEN_GENERATOR", "ID_SMOKE_SCREEN",
      cLoc("hotkeys/ID_SHIP_ACTION_BAR_ITEM_11", "ID_ACTION_BAR_ITEM_11"),
    ]
    axes = ["gm_throttle", "gm_steering"]
      .extend(sameLoc("hotkeys/ID_PLANE_MOUSE_AIM_HEADER", ["gm_mouse_aim_x", "gm_mouse_aim_y"]))
  }
}

return {
  shortcutsByUnitTypes
  pages = unitTypeOrder.filter(@(ut) ut in shortcutsByUnitTypes)
}