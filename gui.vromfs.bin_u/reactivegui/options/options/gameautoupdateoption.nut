from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { OPT_AUTO_UPDATE_ENABLED, mkOptionValue } = require("%rGui/options/guiOptions.nut")
let { isDownloadedFromGooglePlay } = require("android.platform")
let { is_android, is_pc } = require("%sqstd/platform.nut")
let { allow_apk_update } = require("%appGlobals/permissions.nut")

let validate = @(val, list) list.contains(val) ? val : list[0]
let gameAutoUpdateList = [false, true]
let isGameAutoUpdateEnabled = mkOptionValue(OPT_AUTO_UPDATE_ENABLED, false, @(v) validate(v, gameAutoUpdateList))

return {
  isGameAutoUpdateVisible = (is_android || is_pc) && !isDownloadedFromGooglePlay() && allow_apk_update.get()
  gameAutoUpdateList
  isGameAutoUpdateEnabled
}
