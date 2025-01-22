from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *

let { isDebugTouchesActive } = require("%rGui/debugTools/debugTouches.nut")
let { OPT_SHOW_TOUCHES_ENABLED, mkOptionValue } = require("%rGui/options/guiOptions.nut")
let { isGameAutoUpdateVisible, isGameAutoUpdateEnabled, gameAutoUpdateList } = require("gameAutoUpdateOption.nut")
let { isBackgroundUpdateVisible, isBackgroundUpdateEnabled, backgroundUpdateList } = require("backgroundUpdateOption.nut")
let { allow_background_resource_update, allow_apk_update } = require("%appGlobals/permissions.nut")

let autoUpdateSetting = {
  locId = "options/autoUpdate"
  ctrlType = OCT_LIST
  value = isGameAutoUpdateEnabled
  list = Computed(@() allow_apk_update.get() ? gameAutoUpdateList : [])
  valToString = @(v) loc($"options/autoUpdate/{v}")
}

let backgroundUpdateSetting = {
  locId = "options/backgroundUpdate"
  ctrlType = OCT_LIST
  value = isBackgroundUpdateEnabled
  list = Computed(@() allow_background_resource_update.get() ? backgroundUpdateList : [])
  valToString = @(v) loc (v ? "options/enable" : "options/disable")
}

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
    isGameAutoUpdateVisible ? autoUpdateSetting : null
    isBackgroundUpdateVisible ? backgroundUpdateSetting : null
    showTouchesSetting
  ]
}