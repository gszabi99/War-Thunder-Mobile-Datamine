//pseudo-module for native code

let r = getroottable()

return freeze({
  reload_main_script_module = @() r?["reload_main_script_module"]()
  check_login_pass = r["check_login_pass"]
  in_flight_menu = r["in_flight_menu"]
  pause_game = r["pause_game"]
  is_game_paused = r["is_game_paused"]
  get_cur_gui_scene = r["get_cur_gui_scene"]
  disable_flight_menu = r["disable_flight_menu"]
  hud_request_hud_tank_debuffs_state = r["hud_request_hud_tank_debuffs_state"]
  hud_request_hud_crew_state = r["hud_request_hud_crew_state"]
  hud_request_hud_ship_debuffs_state = r["hud_request_hud_ship_debuffs_state"]
  exit_game = r["exit_game"]
  is_online_available = r["is_online_available"]
  toggle_freecam = r?["toggle_freecam"]
  is_freecam_enabled = r["is_freecam_enabled"]
  is_respawn_screen = r["is_respawn_screen"]
  send_error_log = r["send_error_log"]
  get_config_name = r["get_config_name"]
  save_profile = r["save_profile"]
  sign_out = r["sign_out"]
  disable_network = r["disable_network"]
  get_mission_progress = r["get_mission_progress"]
  set_hue = r["set_hue"]
  is_camera_not_flight = r["is_camera_not_flight"]
  is_player_can_bailout = r["is_player_can_bailout"]
  do_player_bailout = r["do_player_bailout"]
  close_ingame_gui = r["close_ingame_gui"]
  add_light = r["add_light"]
  destroy_light = r["destroy_light"]
  set_light_col = r["set_light_col"]
  set_light_pos = r["set_light_pos"]
  set_light_radius = r["set_light_radius"]
  set_language = r["set_language"]
  get_localization_blk_copy = r["get_localization_blk_copy"]
  get_language = r["get_language"]
  make_invalid_user_id = r["make_invalid_user_id"]
  run_reactive_gui = r["run_reactive_gui"]
  set_mute_sound_in_flight_menu = r["set_mute_sound_in_flight_menu"]
  is_player_unit_alive = r["is_player_unit_alive"]
  set_aircraft_accepted_cb = r["set_aircraft_accepted_cb"]
  request_aircraft_and_weapon = r["request_aircraft_and_weapon"]
  get_cur_circuit_name = r["get_cur_circuit_name"]
  save_common_local_settings = r["save_common_local_settings"]
  set_presence_to_player = r["set_presence_to_player"]
  update_objects_under_windows_state = r["update_objects_under_windows_state"]
  is_hud_visible = r["is_hud_visible"]
  hud_is_in_cutscene = r["hud_is_in_cutscene"]
  set_hud_width_limit = r["set_hud_width_limit"]
  set_option_hud_screen_safe_area = r["set_option_hud_screen_safe_area"]
  get_login_pass = r["get_login_pass"]
  get_two_step_code_async2 = r["get_two_step_code_async2"]
  get_player_user_id = r["get_player_user_id"]
  get_cur_rank_info = r["get_cur_rank_info"]
  get_online_client_cur_state = r["get_online_client_cur_state"]
  set_login_pass = r["set_login_pass"]
  set_host_cb = r["set_host_cb"]
  script_net_assert = r["script_net_assert"]
  connect_to_host_list = r["connect_to_host_list"]
  is_mission_favorite = r["is_mission_favorite"]
  toggle_fav_mission = r["toggle_fav_mission"]
  scan_user_missions = r["scan_user_missions"]
  get_player_army_for_hud = r["get_player_army_for_hud"]
  set_show_attachables = r["set_show_attachables"]
  save_short_token = r["save_short_token"]
  restart_game = r["restart_game"]
})