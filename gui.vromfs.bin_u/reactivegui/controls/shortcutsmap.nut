from "shortcutConsts.nut" import *

let allShortcuts = {
  ID_FLIGHTMENU = "J:Start" //can't be changed. Need here for correct show in the controls help.
  ID_CONTINUE = "J:RT | Space"
  ID_CAMERA_NEUTRAL =  "J:LS | N"

  //TANK shortcuts:
  ID_FIRE_GM = "J:RT | Space"
  ID_FIRE_GM_SECONDARY_GUN = "J:LT | L.Ctrl"
  ID_FIRE_GM_SPECIAL_GUN = "J:LB | Z"
  ID_FIRE_GM_MACHINE_GUN = "J:RB | X"
  ID_ZOOM_TOGGLE = "J:RS | V"
  ID_TOGGLE_TARGET_TRACKING =  "J:LT | B"

  ID_ACTION_BAR_ITEM_7 = "J:B | 1" //fighter
  ID_ACTION_BAR_ITEM_9 = "J:A | 2" //bomber
  ID_ACTION_BAR_ITEM_5 = "J:D.Down | 3" //artillery
  ID_SMOKE_SCREEN_GENERATOR = "J:D.Right | 4"
  ID_SMOKE_SCREEN = "J:D.Right | 4"
  ID_ACTION_BAR_ITEM_11 = "J:D.Left | 5" //toolkit
  ID_ACTION_BAR_ITEM_6 = "J:D.Left | 5" //extinguisher
  ID_SHOW_HERO_MODULES = "J:X | 6"

  ID_ACTION_BAR_ITEM_10 = "J:D.Up | Q" //winch
  ID_NEXT_BULLET_TYPE = "J:Y | E"

  ID_TRANS_GEAR_UP = "W | Up"
  ID_TRANS_GEAR_DOWN = "S | Down"
  gm_steering_right = "D | Right"
  gm_steering_left = "A | Left"

  //SHIP shortcuts:
  ship_main_engine_rangeMax = "J:LS.Up | W | Up"
  ship_main_engine_rangeMin = "J:LS.Down | S | Down"
  ship_steering_rangeMin = "J:LS.Right | D | Right"
  ship_steering_rangeMax = "J:LS.Left | A | Left"
  ID_SHIP_WEAPON_PRIMARY = "J:RB | Space" //primary gun
  ID_SHIP_WEAPON_SECONDARY = "J:RT | L.Ctrl" //secondary gun
  ID_SHIP_WEAPON_EXTRA_GUN_1 = "J:LT | Z" //minigun
  ID_SHIP_WEAPON_EXTRA_GUN_2 = "J:LB | T"
  ID_SHIP_WEAPON_TORPEDOES = "J:A | X"
  ID_SHIP_WEAPON_MINE = "J:X | C"
  ID_WTM_LAUNCH_AIRCRAFT = "J:D.Down | Q" //also used for aircraft return to ship


  ID_SHIP_ACTION_BAR_ITEM_11 = "J:D.Left | 1" //toolkit
  ID_SHIP_ACTION_BAR_ITEM_14 = "J:D.Right | 2" //smoke screen
  ID_SHIP_SMOKE_SCREEN_GENERATOR = "J:D.Right | 2"


  //SUBMARINE shortcuts:
  submarine_main_engine_rangeMax = "J:LS.Up | W | Up"
  submarine_main_engine_rangeMin = "J:LS.Down | S | Down"
  submarine_depth_inc = "J:LT | F"
  submarine_depth_dec = "J:LB | R"
  ID_SUBMARINE_WEAPON_TORPEDOES = "J:A | Z"
  ID_DIVING_LOCK = "J:LS | B"

  ID_SUBMARINE_ACTION_BAR_ITEM_11 = "J:D.Left | 1" //toolkit


  //AIRCRAFT shortcuts:
  ID_BOMBS = "J:B | Z"
  ID_FIRE_CANNONS = "J:RT | Space"
  ID_FIRE_MGUNS = "J:RB | L.Ctrl"
  ID_LOCK_TARGET = "J:LB | E"
  ID_ROCKETS = "J:X | X"
  ID_WTM_AIRCRAFT_LAUNCH_TORPEDOES = "J:Y | C"
}

let gamepadAxes = {
  //TANK
  gm_mouse_aim_x = JOY_XBOX_REAL_AXIS_R_THUMB_H
  gm_mouse_aim_y = JOY_XBOX_REAL_AXIS_R_THUMB_V
  gm_throttle = JOY_XBOX_REAL_AXIS_L_THUMB_V
  gm_steering = JOY_XBOX_REAL_AXIS_L_THUMB_H

  //SHIP
  ship_mouse_aim_x = JOY_XBOX_REAL_AXIS_R_THUMB_H
  ship_mouse_aim_y = JOY_XBOX_REAL_AXIS_R_THUMB_V

  //SUBMARINE
  submarine_mouse_aim_x = JOY_XBOX_REAL_AXIS_R_THUMB_H
  submarine_mouse_aim_y = JOY_XBOX_REAL_AXIS_R_THUMB_V

  //AIRCRAFT
  ailerons = JOY_XBOX_REAL_AXIS_L_THUMB_H
  mouse_aim_x = JOY_XBOX_REAL_AXIS_R_THUMB_H
  mouse_aim_y = JOY_XBOX_REAL_AXIS_R_THUMB_V
  throttle_axis = JOY_XBOX_REAL_AXIS_L_THUMB_V
}

return {
  allShortcuts
  gamepadAxes
  allShortcutsUp = allShortcuts.map(@(s) $"^{s}")
  gamepadShortcuts = allShortcuts.map(@(s) s.split(" | ").findvalue(@(v) v.startswith("J:")))
    .filter(@(s) s != null)
}