from "%globalsDarg/darg_library.nut" import *

let sizeIncDef = hdpx(2)
let rotatedBtnSizeInc = hdpx(40)
let circleWithCountSizeInc = hdpx(10)
let pushedArrowColor = 0xFF7EE2FF

let rotated = @(objs) { objs, sizeInc = rotatedBtnSizeInc }
let circle = @(objs) { objs, sizeInc = circleWithCountSizeInc }
let elements = {
  air_throttle_slider = [["air_throttle_slider", "air_throttle_slider_text"]]
  air_throttle_slider_text = ["air_throttle_slider_text"]
  plane_course_guns = ["air_course_guns_main", "air_course_guns_second", "air_cannon", "air_minigun"]
  plane_lock_target = ["plane_lock_target"]
  plane_speed_indicator = ["plane_speed_indicator"]
  plane_altitude_indicator = ["plane_altitude_indicator"]
  btn_forward = ["ship_main_engine_rangeMax", "submarine_main_engine_rangeMax", "ID_TRANS_GEAR_UP"]
  btn_left_right = ["ship_steering_rangeMax", "ship_steering_rangeMin", "gm_steering_right", "gm_steering_left"]
  btn_left = ["ship_steering_rangeMax", "gm_steering_left"]
  btn_right = ["ship_steering_rangeMin", "gm_steering_right"]
  btn_backward = ["ship_main_engine_rangeMin", "submarine_main_engine_rangeMin", "ID_TRANS_GEAR_DOWN"]
  tank_move_stick_zone = ["tank_move_stick_zone"]
  btn_zoom = [rotated("btn_zoom"), "btn_zoom_circle"]
  btn_weapon_primary = [rotated($"btn_weapon_{TRIGGER_GROUP_PRIMARY}"), circle("btn_weapon_primary")]
  btn_weapon_primary_alt = [circle("btn_weapon_primary_alt")]
  btn_weapon_secondary = [circle("btn_weapon_primary_alt")]
  btn_machinegun = [circle("btn_machinegun")]
  btn_repair = ["btn_repair"]
  tactical_map = ["tactical_map"]
  hit_camera = ["hit_camera"]
  btn_extinguisher = ["btn_extinguisher"]
  btn_special_unit = ["EII_SPECIAL_UNIT"]
  btn_special_unit2 = ["EII_SPECIAL_UNIT_2"]
  crew_active = ["crew_active"]
  crew_injured = ["crew_injured"]
  mission_hint = [{isDouble = true, objs = "mission_hint" }]
  mission_objective = [{isDouble = true, objs = "mission_objective" }]
  capture_zones = [{isDouble = true, arrowOffset = [0, -hdpx(25)] objs = "capture_zones" }]
  score_board = [{isDouble = true, objs = "score_board" }]
  capture_zone_indicator_0 = ["capture_zone_indicator_0"]
  capture_zone_indicator_1 = ["capture_zone_indicator_1"]
  capture_zone_indicator_2 = ["capture_zone_indicator_2"]
}

return {
  elements
  sizeIncDef
  pushedArrowColor
}
