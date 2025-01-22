from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { OPT_AUTO_UPDATE_ENABLED, mkOptionValue } = require("%rGui/options/guiOptions.nut")
let { allow_apk_update } = require("%appGlobals/permissions.nut")
let { isDownloadedFromSite } = require("%appGlobals/clientState/clientState.nut")

let validate = @(val, list) list.contains(val) ? val : list[0]
let gameAutoUpdateList = ["not_allow", "allow_only_wifi", "allow_always"]
let isGameAutoUpdateEnabled = mkOptionValue(OPT_AUTO_UPDATE_ENABLED, "allow_only_wifi", @(v) validate(v, gameAutoUpdateList))

return {
  isGameAutoUpdateVisible = isDownloadedFromSite && allow_apk_update.get()
  gameAutoUpdateList
  isGameAutoUpdateEnabled
}
