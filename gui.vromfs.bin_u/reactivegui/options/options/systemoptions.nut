from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *

let { isDownloadedFromSite } = require("%appGlobals/clientState/clientState.nut")
let { isDebugTouchesActive } = require("%rGui/debugTools/debugTouches.nut")
let { OPT_SHOW_TOUCHES_ENABLED, mkOptionValue, optionsVersion } = require("%rGui/options/guiOptions.nut")
let { isGameAutoUpdateEnabled, gameAutoUpdateList } = require("gameAutoUpdateOption.nut")
let { allow_apk_update } = require("%appGlobals/permissions.nut")
let { reset_gui_options } = require("controlsOptions")
let { reset_volumes } = require("soundOptions")
let { openMsgBox } = require("%rGui/components/msgBox.nut")

let autoUpdateSetting = {
  locId = "options/autoUpdate"
  ctrlType = OCT_LIST
  value = isGameAutoUpdateEnabled
  list = Computed(@() allow_apk_update.get() ? gameAutoUpdateList : [])
  valToString = @(v) loc($"options/autoUpdate/{v}")
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

let resetButton = @() openMsgBox({
  text = loc("msgbox/resetDefaults")
  buttons = [
    { id = "cancel", isCancel = true }
    { id = "ok", styleId = "PRIMARY",cb = function() {
      reset_gui_options()
      reset_volumes()
      optionsVersion(optionsVersion.get() + 1)
    } }
  ]
})

let resetControlsButton = {
  locId = "options/reset"
  ctrlType = OCT_BUTTON
  onClick = resetButton
}

return {
  systemOptions = [
    isDownloadedFromSite ? autoUpdateSetting : null
    showTouchesSetting
    resetControlsButton
  ]
}