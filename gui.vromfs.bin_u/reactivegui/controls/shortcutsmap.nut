from "shortcutConsts.nut" import *
let { isReplayShortcuts } = require("shortcutFlags.nut")

let allShortcuts = isReplayShortcuts ? {}
: {
  
  ID_FLIGHTMENU = "J:Start | Esc" 
  ID_CONTINUE = "J:RT | Space"
  ID_MPSTATSCREEN =  "J:Back | Tab"
  ID_ZOOM_TOGGLE = "J:RS | L.Shift" 
  ID_CHANGE_ZOOM =  "" 
  ID_SHOW_HERO_MODULES = "J:X | 6"

  ID_CAMERA_NEUTRAL =  "J:LS | N" 
  ID_WTM_LAUNCH_AIRCRAFT = "J:D.Down | Q" 

  
  ID_FIRE_GM = "J:RT | Space"
  ID_FIRE_GM_SECONDARY_GUN = "J:LT | L.Ctrl"
  ID_FIRE_GM_SPECIAL_GUN = "J:LB | Z"
  ID_FIRE_GM_MACHINE_GUN = "J:RB | X"
  ID_TOGGLE_TARGET_TRACKING =  "B"

  ID_ACTION_BAR_ITEM_7 = "J:B | 1" 
  ID_ACTION_BAR_ITEM_9 = "J:A | 2" 
  ID_ACTION_BAR_ITEM_5 = "J:D.Down | 3" 
  ID_SMOKE_SCREEN_GENERATOR = "J:D.Right | 4"
  ID_SMOKE_SCREEN = "J:D.Right | 4"
  ID_ACTION_BAR_ITEM_11 = "J:D.Left | 5" 
  ID_ACTION_BAR_ITEM_6 = "J:D.Up | 7" 

  ID_ACTION_BAR_ITEM_10 = "Q" 
  ID_NEXT_BULLET_TYPE = "J:Y | E"

  ID_TRANS_GEAR_UP = "W | Up"
  ID_TRANS_GEAR_DOWN = "S | Down"
  gm_steering_right = "D | Right"
  gm_steering_left = "A | Left"

  
  ship_main_engine_rangeMax = "J:LS.Up | W | Up"
  ship_main_engine_rangeMin = "J:LS.Down | S | Down"
  ship_steering_rangeMin = "J:LS.Right | D | Right"
  ship_steering_rangeMax = "J:LS.Left | A | Left"
  ID_SHIP_WEAPON_PRIMARY = "J:RB | Space" 
  ID_SHIP_WEAPON_SECONDARY = "J:RT | L.Ctrl" 
  ID_SHIP_WEAPON_EXTRA_GUN_1 = "J:LT | Z" 
  ID_SHIP_WEAPON_EXTRA_GUN_2 = "J:LB | T"
  ID_SHIP_WEAPON_EXTRA_GUN_3 = "J:LT | Z"
  ID_SHIP_WEAPON_EXTRA_GUN_4 = "J:LB | T"
  ID_SHIP_WEAPON_MACHINEGUN = "J:RB | Space" 
  ID_SHIP_WEAPON_TORPEDOES = "J:A | X"
  ID_SHIP_WEAPON_MINE = "J:B | C"
  ID_SHIP_WEAPON_MORTAR = "J:B | C"
  ID_SHIP_WEAPON_ROCKETS = "J:Y | V"
  ID_SHIP_WEAPON_ROCKETS_SECONDARY = "J:LS | B"

  ID_SHIP_ACTION_BAR_ITEM_40 = "J:D.Left | 1" 
  ID_SHIP_ACTION_BAR_ITEM_14 = "J:D.Right | 2" 
  ID_SHIP_SMOKE_SCREEN_GENERATOR = "J:D.Right | 2"
  ID_IRCM_SWITCH_SHIP = "J:D.Up | 3"

  
  submarine_main_engine_rangeMax = "J:LS.Up | W | Up"
  submarine_main_engine_rangeMin = "J:LS.Down | S | Down"
  submarine_depth_inc = "J:LT | F"
  submarine_depth_dec = "J:LB | R"
  ID_SUBMARINE_WEAPON_TORPEDOES = "J:A | X"
  ID_SUBMARINE_WEAPON_ROCKETS = "J:Y | V"
  ID_DIVING_LOCK = "J:LS | B"

  ID_SUBMARINE_ACTION_BAR_ITEM_40 = "J:D.Left | 1" 
  ID_SUBMARINE_ACOUSTIC_COUNTERMEASURES = "J:D.Right | 2"

  
  ID_CAMERA_VIEW_BACK = "J:D.Left | B"
  ID_CAMERA_VIEW_STICK = "J:D.Right | M"
  ID_CTRL_PIE_STICK = "J:D.Up | K"
  ID_BOMBS = "J:B | Z"
  ID_FIRE_COURSE_GUNS = "J:RT | Space"
  ID_FIRE_CANNONS = "J:RT | Space"
  ID_FIRE_MGUNS = "J:RB | L.Ctrl"
  ID_LOCK_TARGET = "J:LB | L.Alt"
  ID_ROCKETS = "J:A | X"
  ID_WTM_AIRCRAFT_TORPEDOES = "J:Y | C"
}

let gamepadAxes = {
  
  gm_mouse_aim_x = JOY_XBOX_REAL_AXIS_R_THUMB_H
  gm_mouse_aim_y = JOY_XBOX_REAL_AXIS_R_THUMB_V
  gm_throttle = JOY_XBOX_REAL_AXIS_L_THUMB_V
  gm_steering = JOY_XBOX_REAL_AXIS_L_THUMB_H

  
  ship_mouse_aim_x = JOY_XBOX_REAL_AXIS_R_THUMB_H
  ship_mouse_aim_y = JOY_XBOX_REAL_AXIS_R_THUMB_V

  
  submarine_mouse_aim_x = JOY_XBOX_REAL_AXIS_R_THUMB_H
  submarine_mouse_aim_y = JOY_XBOX_REAL_AXIS_R_THUMB_V

  
  ailerons = JOY_XBOX_REAL_AXIS_L_THUMB_H
  mouse_aim_x = JOY_XBOX_REAL_AXIS_R_THUMB_H
  mouse_aim_y = JOY_XBOX_REAL_AXIS_R_THUMB_V
  throttle_axis = JOY_XBOX_REAL_AXIS_L_THUMB_V
  rudder = JOY_XBOX_REAL_AXIS_R_THUMB_H
  elevator = JOY_XBOX_REAL_AXIS_R_THUMB_V
  turret_x = JOY_XBOX_REAL_AXIS_R_THUMB_H
  turret_y = JOY_XBOX_REAL_AXIS_R_THUMB_V
}

let imuAxes = {
  gravityLeft = GRAVITY_AXIS_Y
  gravityForward = GRAVITY_AXIS_Z
  gravityUp = GRAVITY_AXIS_X
}

return {
  allShortcuts
  gamepadAxes
  imuAxes
  allShortcutsUp = allShortcuts.map(@(s) $"^{s}")
  gamepadShortcuts = allShortcuts.map(@(s) s.split(" | ").findvalue(@(v) v.startswith("J:")))
    .filter(@(s) s != null)
}