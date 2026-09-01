from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
from "controlsOptions" import reset_gui_options
from "soundOptions" import reset_volumes
from "%appGlobals/clientState/clientState.nut" import isDownloadedFromSite
from "%appGlobals/permissions.nut" import allow_apk_update
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/debugTools/debugTouches.nut" import isDebugTouchesActive
from "%rGui/options/guiOptions.nut" import OPT_SHOW_TOUCHES_ENABLED, mkOptionValue, optionsVersion
from "%rGui/options/options/gameAutoUpdateOption.nut" import isGameAutoUpdateEnabled, gameAutoUpdateList


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
    { id = "ok", styleId = "PRIMARY",
      function cb() {
        reset_gui_options()
        reset_volumes()
        optionsVersion.set(optionsVersion.get() + 1)
      }
    }
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