from "%appGlobals/unitConst.nut" import *

let sameLoc = @(locId, scList) scList.map(@(value) { locId, value })
let cLoc = @(locId, value) { locId, value }

let shortcutsByUnitTypes = {
  [SHIP] = {
    shortcuts = [
      "ID_FLIGHTMENU", "ID_ZOOM_TOGGLE",
      cLoc("flightmenu/btnStats", "ID_MPSTATSCREEN"),
      "ship_main_engine_rangeMax", "ship_main_engine_rangeMin",
      cLoc("hotkeys/primaryGun", "ID_SHIP_WEAPON_PRIMARY"),
      cLoc("hotkeys/secondaryGun", "ID_SHIP_WEAPON_SECONDARY"),
      cLoc("hotkeys/extraGun", "ID_SHIP_WEAPON_EXTRA_GUN_1"),
      cLoc("hotkeys/extraGun", "ID_SHIP_WEAPON_EXTRA_GUN_2"),
      cLoc("HUD/TXT_IRCM", "ID_IRCM_SWITCH_SHIP"),
      cLoc("hotkeys/ID_SHIP_WEAPON_DEPTH_CHARGE", "ID_SHIP_WEAPON_MORTAR"),
      "ID_SHIP_WEAPON_TORPEDOES", "ID_SHIP_SMOKE_SCREEN_GENERATOR", "ID_WTM_LAUNCH_AIRCRAFT",
      "ID_SHIP_WEAPON_MINE", "ID_SHIP_ACTION_BAR_ITEM_11", "ID_SHOW_HERO_MODULES",
      "ID_SHIP_STRATEGY_MODE_TOGGLE", "ID_SHIP_WEAPON_ROCKETS", "ID_SHIP_WEAPON_ROCKETS_SECONDARY"
    ]
      .extend(sameLoc("hotkeys/steering", ["ship_steering_rangeMin", "ship_steering_rangeMax"]))
    axes = sameLoc("hotkeys/ID_PLANE_MOUSE_AIM_HEADER", ["ship_mouse_aim_x", "ship_mouse_aim_y"])
  },
  [SUBMARINE] = {
    shortcuts = [
      "ID_FLIGHTMENU", "ID_ZOOM_TOGGLE",
      cLoc("flightmenu/btnStats", "ID_MPSTATSCREEN"),
      "submarine_main_engine_rangeMax", "submarine_main_engine_rangeMin",
      "ID_SUBMARINE_WEAPON_TORPEDOES", "ID_DIVING_LOCK", "ID_SHIP_WEAPON_MINE",
      "ID_SUBMARINE_WEAPON_ROCKETS", "ID_SUBMARINE_ACOUSTIC_COUNTERMEASURES",
      "ID_SUBMARINE_ACTION_BAR_ITEM_11", "ID_SHOW_HERO_MODULES",
      cLoc("hotkeys/submarine_depth_rangeInc", "submarine_depth_inc"),
      cLoc("hotkeys/submarine_depth_rangeDec", "submarine_depth_dec"),
    ]
      .extend(sameLoc("hotkeys/steering", ["ship_steering_rangeMin", "ship_steering_rangeMax"]))
    axes = sameLoc("hotkeys/ID_PLANE_MOUSE_AIM_HEADER", ["submarine_mouse_aim_x", "submarine_mouse_aim_y"])
  },
  [AIR] = {
    shortcuts = [
      "ID_FLIGHTMENU", "ID_ZOOM_TOGGLE",
      cLoc("flightmenu/btnStats", "ID_MPSTATSCREEN"),
      "ID_BOMBS", "ID_ROCKETS", "ID_FIRE_COURSE_GUNS", "ID_FIRE_CANNONS", "ID_FIRE_MGUNS",
      "ID_LOCK_TARGET", "ID_CAMERA_VIEW_BACK",
      cLoc("hotkeys/ID_SHIP_WEAPON_TORPEDOES", "ID_WTM_AIRCRAFT_LAUNCH_TORPEDOES"),
    ]
    axes = [cLoc("controls/walker_throttle", "throttle_axis"), "ailerons", "elevator", "rudder"]
      .extend(sameLoc("controls/help/movement_direction_control", ["mouse_aim_x", "mouse_aim_y"]),
        sameLoc("controls/help/turret_aiming_control", ["turret_x", "turret_y"]))
  },
  [TANK] = {
    shortcuts = [
      "ID_FLIGHTMENU", "ID_ZOOM_TOGGLE",
      cLoc("flightmenu/btnStats", "ID_MPSTATSCREEN"),
      "ID_FIRE_GM", "ID_FIRE_GM_SPECIAL_GUN", "ID_FIRE_GM_MACHINE_GUN",
      "ID_ACTION_BAR_ITEM_5", "ID_ACTION_BAR_ITEM_7", "ID_ACTION_BAR_ITEM_9", "ID_ACTION_BAR_ITEM_6",
      "ID_ACTION_BAR_ITEM_10", "ID_SMOKE_SCREEN_GENERATOR", "ID_SMOKE_SCREEN", "ID_SHOW_HERO_MODULES",
      "ID_CAMERA_NEUTRAL", "ID_TOGGLE_TARGET_TRACKING", "ID_NEXT_BULLET_TYPE",
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