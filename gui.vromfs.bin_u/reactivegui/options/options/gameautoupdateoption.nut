from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { OPT_AUTO_UPDATE_ENABLED, mkOptionValue } = require("%rGui/options/guiOptions.nut")

let AU_NOT_ALLOW = "not_allow"
let AU_ALLOW_ONLY_WIFI = "allow_only_wifi"
let AU_ALLOW_ALWAYS = "allow_always"

let validate = @(val, list) list.contains(val) ? val : list[0]
let gameAutoUpdateList = [AU_NOT_ALLOW, AU_ALLOW_ONLY_WIFI, AU_ALLOW_ALWAYS]
let isGameAutoUpdateEnabled = mkOptionValue(OPT_AUTO_UPDATE_ENABLED, AU_NOT_ALLOW, @(v) validate(v, gameAutoUpdateList))

return {
  AU_NOT_ALLOW
  AU_ALLOW_ONLY_WIFI
  AU_ALLOW_ALWAYS

  gameAutoUpdateList
  isGameAutoUpdateEnabled
}
