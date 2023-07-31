
from "%globalScripts/logs.nut" import *
let { Computed } = require("frp")
let { DBGLEVEL } = require("dagor.system")
let { trim } = require("%sqstd/string.nut")
let { rights } = require("permissions/userRights.nut")

let defaults = {
  can_debug_configs = DBGLEVEL > 0
  can_debug_missions = DBGLEVEL > 0
  can_debug_units = DBGLEVEL > 0
  can_debug_shop = DBGLEVEL > 0
  allow_online_purchases = false
  can_use_debug_console = DBGLEVEL > 0
  can_receive_dedic_logerr = DBGLEVEL > 0
  allow_players_online_info = false
  can_use_internal_support_form = false
  allow_review_cue = false
}

let allPermissions = Computed(function() {
  let res = clone defaults
  foreach (id in rights.value?.permissions.value ?? []) {
    if (trim(id) != id)
      logerr($"Permission ID with whitespace detected: \"{id}\"")
    res[id] <- true
  }
  return res
})

return {
  allPermissions
}.__merge(defaults.map(@(_, key) Computed(@() allPermissions.value[key])))
