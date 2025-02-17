
from "%globalScripts/logs.nut" import *
let { Computed } = require("frp")
let { DBGLEVEL } = require("dagor.system")
let { trim } = require("%sqstd/string.nut")
let { rights } = require("permissions/userRights.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let defaults = {
  can_debug_configs = DBGLEVEL > 0
  can_debug_missions = DBGLEVEL > 0
  can_debug_units = DBGLEVEL > 0
  can_debug_shop = DBGLEVEL > 0
  can_use_debug_console = DBGLEVEL > 0
  can_receive_dedic_logerr = DBGLEVEL > 0
  allow_players_online_info = false
  allow_review_cue = false
  can_view_replays = DBGLEVEL > 0 || isOfflineMenu
  can_write_replays = DBGLEVEL > 0
  can_link_to_gaijin_account = DBGLEVEL > 0
  can_link_email_for_gaijin_login = DBGLEVEL > 0
  has_additional_graphics_content = DBGLEVEL > 0
  has_leaderboard = DBGLEVEL > 0
  has_strategy_mode = DBGLEVEL > 0
  has_offline_battle_access = DBGLEVEL > 0
  can_view_player_uids = DBGLEVEL > 0
  can_view_update_suggestion = false
  allow_chat = DBGLEVEL > 0
  can_skip_consent = false
  has_payments_blocked_web_page = false
  request_firebase_consent_eu_only = false
  has_att_warmingup_scene = false
  allow_apk_update = false
  allow_background_resource_update = DBGLEVEL > 0
  allow_subscriptions = DBGLEVEL > 0
}

let dbgPermissions = sharedWatched("dbgPermissions", @() {})

let allPermissions = Computed(function() {
  let res = clone defaults
  foreach (id in rights.value?.permissions.value ?? []) {
    if (trim(id) != id)
      logerr($"Permission ID with whitespace detected: \"{id}\"")
    res[id] <- true
  }
  foreach(id, v in dbgPermissions.value)
    if (v && (id in res))
      res[id] = !res[id]
  return res
})

return {
  allPermissions
  dbgPermissions
}.__merge(defaults.map(@(_, key) Computed(@() allPermissions.value[key])))
