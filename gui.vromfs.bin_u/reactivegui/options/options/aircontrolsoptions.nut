from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { OPT_AIRCRAFT_FIXED_AIM_CURSOR, mkOptionValue} = require("%rGui/options/guiOptions.nut")
let { set_aircraft_fixed_aim_cursor } = require("controlsOptions")

let validate = @(val, list) list.contains(val) ? val : list[0]

let fixedAimCursorList = [false, true]
let currentFixedAimCursor = mkOptionValue(OPT_AIRCRAFT_FIXED_AIM_CURSOR, false, @(v) validate(v, fixedAimCursorList))
set_aircraft_fixed_aim_cursor(currentFixedAimCursor.value)
currentFixedAimCursor.subscribe(@(v) set_aircraft_fixed_aim_cursor(v))
let currentFixedAimCursorType = {
  locId = "options/fixed_aim_cursor"
  ctrlType = OCT_LIST
  value = currentFixedAimCursor
  list = fixedAimCursorList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/fixed_aim_cursor")
}

return {
  airControlsOptions = [
    currentFixedAimCursorType
  ]
}
