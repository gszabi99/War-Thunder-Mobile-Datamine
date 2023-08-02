from "%globalsDarg/darg_library.nut" import *
from "hitCamera" import *

let hitResultCfg = {
  [DM_HIT_RESULT_RICOSHET]    = { locId = "hitcamera/result/ricochet",  styleId = "miss" }, // 1
  [DM_HIT_RESULT_BOUNCE]      = { locId = "hitcamera/result/bounce",    styleId = "miss" }, // 2
  [DM_HIT_RESULT_HIT]         = { locId = "hitcamera/result/hit",       styleId = "hit"  }, // 3
  [DM_HIT_RESULT_BURN]        = { locId = "hitcamera/result/burn",      styleId = "crit" }, // 4
  [DM_HIT_RESULT_CRITICAL]    = { locId = "hitcamera/result/critical",  styleId = "crit" }, // 5
  [DM_HIT_RESULT_KILL]        = { locId = "hitcamera/result/kill",      styleId = "kill" }, // 6
  [DM_HIT_RESULT_METAPART]    = { locId = "hitcamera/result/hull",      styleId = "kill" }, // 7
  [DM_HIT_RESULT_AMMO]        = { locId = "hitcamera/result/ammo",      styleId = "kill" }, // 8
  [DM_HIT_RESULT_FUEL]        = { locId = "hitcamera/result/fuel",      styleId = "kill" }, // 9
  [DM_HIT_RESULT_CREW]        = { locId = "hitcamera/result/crew",      styleId = "kill" }, // 10
  [DM_HIT_RESULT_TORPEDO]     = { locId = "hitcamera/result/torpedo",   styleId = "kill" }, // 11
  [DM_HIT_RESULT_DESTRUCTION] = { locId = "hitcamera/result/kill",      styleId = "kill" }, // 12
  [DM_HIT_RESULT_BREAKING]    = { locId = "hitcamera/result/breaking",  styleId = "hit"  }, // 13
}

let defPartPriority = 1

let partsPriority = {
  //ammo
  ammunition_storage = 101
  torpedo = 100

  //weaponry
  ship_main_caliber_gun = 55
  ship_main_caliber_turret = 55
  ship_auxiliary_caliber_gun = 54
  ship_auxiliary_caliber_turret = 54
  ship_aa_gun = 52
  ship_aa_turret = 52
  ship_torpedo_tube = 51

  //movement
  ship_engine_room = 39
  ship_steering_gear = 38
  ship_bridge = 37
  ship_coal_bunker = 33
  ship_fuel_tank = 33
  ship_funnel = 31

  //armor
  ship_armor_belt_r = 25
  ship_armor_belt_l = 25
  ship_armor_cit_r = 23
  ship_armor_cit_l = 23
  ship_compartment = 21
}

let hitCameraWidth = hdpx(530)
let hitCameraRenderSize = [ hitCameraWidth, hdpx(260) ]

let hitResultStyle = {
  miss = { text = { color = 0xFFC0C0C0 }, bg = { color = 0x20000000 }, plate = { color = 0xD93F3E37 } }
  hit  = { text = { color = 0xFF9EE000 }, bg = { color = 0x00181800 }, plate = { color = 0xD90D5E80 } }
  crit = { text = { color = 0xFFFF6E6E }, bg = { color = 0x003F0100 }, plate = { color = 0xD98B5221 } }
  kill = { text = { color = 0xFFFF4040 }, bg = { color = 0x32000000 }, plate = { color = 0xD97A0000 } }
}

return {
  hitResultCfg
  defPartPriority
  partsPriority

  hitCameraWidth
  hitCameraRenderSize
  hitResultStyle
}