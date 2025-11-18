

let r = getroottable()

return freeze({
  reload_main_script_module = @() r?["reload_main_script_module"]()
  get_cur_gui_scene = r["get_cur_gui_scene"]
  is_online_available = r["is_online_available"]
  toggle_freecam = r?["toggle_freecam"]
  is_freecam_enabled = r["is_freecam_enabled"]
  send_error_log = r["send_error_log"]
  disable_network = r["disable_network"]
  get_mission_progress = r["get_mission_progress"]
  set_hue = r["set_hue"]
  set_language = r["set_language"]
  get_localization_blk_copy = r["get_localization_blk_copy"]
  get_language = r["get_language"]
  run_reactive_gui = r["run_reactive_gui"]
  set_aircraft_accepted_cb = r["set_aircraft_accepted_cb"]
  get_cur_circuit_name = r["get_cur_circuit_name"]
  update_objects_under_windows_state = r["update_objects_under_windows_state"]
  set_hud_width_limit = r["set_hud_width_limit"]
  set_option_hud_screen_safe_area = r["set_option_hud_screen_safe_area"]
  get_player_user_id = r["get_player_user_id"]
  get_cur_rank_info = r["get_cur_rank_info"]
  get_online_client_cur_state = r["get_online_client_cur_state"]
  set_host_cb = r["set_host_cb"]
  script_net_assert = r["script_net_assert"]
  connect_to_host_list = r["connect_to_host_list"]
  get_player_army_for_hud = r["get_player_army_for_hud"]
  set_show_attachables = r["set_show_attachables"]
  save_short_token = r["save_short_token"]
  restart_game = r["restart_game"]
})
