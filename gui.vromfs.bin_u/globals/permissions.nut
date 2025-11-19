from "%globalScripts/logs.nut" import *
let { get_cur_circuit_name } = require("app")
let { Computed } = require("frp")
let { DBGLEVEL } = require("dagor.system")
let { trim } = require("%sqstd/string.nut")
let { rights } = require("permissions/userRights.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let isDevBuild = DBGLEVEL > 0
let isCircuitDev = get_cur_circuit_name().contains("dev")

let defaults = {
  can_debug_configs = isDevBuild
  can_debug_missions = isDevBuild
  can_debug_units = isDevBuild
  can_debug_shop = isDevBuild
  can_use_debug_console = isDevBuild
  can_receive_dedic_logerr = isDevBuild
  allow_players_online_info = false
  allow_review_cue = false
  can_view_replays = isDevBuild || isOfflineMenu
  can_write_replays = isDevBuild
  can_link_to_gaijin_account = isDevBuild
  can_link_email_for_gaijin_login = isDevBuild
  has_additional_graphics_content = isDevBuild
  has_leaderboard = isDevBuild
  has_strategy_mode = isDevBuild
  has_offline_battle_access = isDevBuild
  can_view_player_uids = isDevBuild
  can_view_update_suggestion = false
  allow_chat = isDevBuild
  can_skip_consent = false
  has_payments_blocked_web_page = false
  request_firebase_consent_eu_only = false
  has_att_warmingup_scene = false
  allow_apk_update = false
  allow_subscriptions = false
  can_upgrade_subscription = isDevBuild
  allow_dm_viewer = isDevBuild && isCircuitDev
  allow_dm_viewer_ships_armor = isDevBuild && isCircuitDev
  allow_protection_analysis = isDevBuild
  can_view_jip_setting = isDevBuild
  can_use_alternative_payment_ios_usa = isDevBuild
  has_option_tank_alternative_control = isDevBuild
  has_decals = isDevBuild
  has_extended_sound = isDevBuild
  has_game_center = isDevBuild
  allow_hdr_on_ios = isDevBuild
}

let dbgPermissions = sharedWatched("dbgPermissions", @() {})

let allPermissions = Computed(function() {
  let res = clone defaults
  foreach (id in rights.get()?.permissions.value ?? []) {
    if (trim(id) != id)
      logerr($"Permission ID with whitespace detected: \"{id}\"")
    res[id] <- true
  }
  foreach(id, v in dbgPermissions.get())
    if (v && (id in res))
      res[id] = !res[id]
  return res
})

return {
  allPermissions
  dbgPermissions
}.__merge(defaults.map(@(_, key) Computed(@() allPermissions.get()[key])))
