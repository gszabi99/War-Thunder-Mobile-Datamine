from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *

let { isDebugTouchesActive } = require("%rGui/debugTools/debugTouches.nut")
let { OPT_SHOW_TOUCHES_ENABLED, mkOptionValue } = require("%rGui/options/guiOptions.nut")

let validate = @(val, list) list.contains(val) ? val : list[0]
let showTouchesList = [false, true]
let isShowTouchesEnabled = mkOptionValue(OPT_SHOW_TOUCHES_ENABLED, false, @(v) validate(v, showTouchesList))

isShowTouchesEnabled.subscribe(@(v) isDebugTouchesActive.set(v))
let showTouchesSetting = {
  locId = "options/showTouches"
  ctrlType = OCT_LIST
  value = isShowTouchesEnabled
  list = showTouchesList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}
isDebugTouchesActive.set(isShowTouchesEnabled.get())

return {
  systemOptions = [
    showTouchesSetting
  ]
}