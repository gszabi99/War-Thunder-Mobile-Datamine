from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { OPT_BACKGROUND_UPDATE_ENABLED, mkOptionValue } = require("%rGui/options/guiOptions.nut")
let { is_android, is_pc } = require("%sqstd/platform.nut")

let validate = @(val, list) list.contains(val) ? val : list[0]
let backgroundUpdateList = [false, true]
let isBackgroundUpdateEnabled = mkOptionValue(OPT_BACKGROUND_UPDATE_ENABLED, false, @(v) validate(v, backgroundUpdateList))

return {
  isBackgroundUpdateVisible = is_android || is_pc
  backgroundUpdateList
  isBackgroundUpdateEnabled
}
