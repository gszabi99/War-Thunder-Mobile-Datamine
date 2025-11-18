from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { set_hud_show_unit_model_name_online } = require("gameOptions")
let { can_view_jip_setting, has_decals } = require("%appGlobals/permissions.nut")
let { USEROPT_ALLOW_JIP, mkOptionValue, OPT_HUD_SHOW_UNIT_MODEL_NAME_ONLINE, USEROPT_IS_ORIGINAL_DECALS } = require("%rGui/options/guiOptions.nut")


let validate = @(val, list) list.contains(val) ? val : list[0]
let allowJipList = [false, true]
let isAllowJipEnabled = mkOptionValue(USEROPT_ALLOW_JIP, true, @(v) validate(v, allowJipList))

let allowJipSetting = {
  locId = "options/allow_jip"
  ctrlType = OCT_LIST
  value = isAllowJipEnabled
  list = Computed(@() can_view_jip_setting.get() ? allowJipList : [])
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/allow_jip_description")
}


let hudShowUnitModelNameOnlineList = [false, true]
let currentShowModelNameSelection = mkOptionValue(OPT_HUD_SHOW_UNIT_MODEL_NAME_ONLINE, false, @(v) validate(v, hudShowUnitModelNameOnlineList))
set_hud_show_unit_model_name_online(currentShowModelNameSelection.get())
currentShowModelNameSelection.subscribe(@(v) set_hud_show_unit_model_name_online(v))
let showUnitModelNameSetting = {
  ctrlType = OCT_LIST
  value = currentShowModelNameSelection
  list = hudShowUnitModelNameOnlineList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  locId = "options/hud_show_unit_model_name_online"
  description = loc("options/desc/hud_show_unit_model_name_online")
}

let originalDecalsList = [false, true]
let isOriginalDecalsEnabled = mkOptionValue(USEROPT_IS_ORIGINAL_DECALS, false, @(v) validate(v, originalDecalsList))

let isOriginalDecaSetting = {
  ctrlType = OCT_LIST
  value = isOriginalDecalsEnabled
  list = Computed(@() has_decals.get() ? originalDecalsList : [])
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  locId = "options/hud_show_original_decals"
  description = loc("options/desc/hud_show_original_decals", {
    optionName = colorize("@mark", loc("options/hud_show_original_decals"))
    optionValue = colorize("@mark", loc("options/enable"))
  })
}

return {
  gameOptions = [
    allowJipSetting
    showUnitModelNameSetting
    isOriginalDecaSetting
  ]
}
