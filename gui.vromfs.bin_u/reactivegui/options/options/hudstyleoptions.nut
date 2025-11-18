from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { OPT_HUD_RELOAD_STYLE, mkOptionValue } = require("%rGui/options/guiOptions.nut")

let validate = @(val, list) list.contains(val) ? val : list[0]

let hudReloadStyleList = [false, true]
let isHudPrimaryStyle = mkOptionValue(OPT_HUD_RELOAD_STYLE, false, @(v) validate(v, hudReloadStyleList))
let hudReloadStyleOption = {
  locId = "options/hud_reload_style"
  ctrlType = OCT_LIST
  value = isHudPrimaryStyle
  list = hudReloadStyleList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  tooltipCtorId = OPT_HUD_RELOAD_STYLE
}

return {
  isHudPrimaryStyle
  hudReloadStyleOption
}
