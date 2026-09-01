from "%globalsDarg/darg_library.nut" import *
from "colorCorrector" import TARGET_HUE_ALLY, TARGET_HUE_ENEMY
from "controls" import loadAsCurrentPreset, getDefaultPresetPath
from "eventbus" import eventbus_subscribe, eventbus_send
from "postFxSettings" import setTonemappingMode, getTonemappingMode
from "%sqstd/globalState.nut" import hardPersistWatched
from "guiScriptUtils" import set_show_attachables
from "rendering" import set_hue
let saveProfile = @() eventbus_send("saveProfile", {})


let failedLoadPreset = hardPersistWatched("options.failedLoadPreset", null)

function initOptions() {
  
  set_hue(TARGET_HUE_ALLY, -1)
  set_hue(TARGET_HUE_ENEMY, -1)

  
  set_show_attachables(true)

  if (failedLoadPreset.get() != null) {
    let preset = failedLoadPreset.get()
    let defPath = getDefaultPresetPath()
    failedLoadPreset.set(null)
    if (preset == defPath)
      log("[SQ_CTRL] Ignore controls.presetLoadFailed because of failed to load default preset")
    else {
      log("[SQ_CTRL] Load default preset by controls.presetLoadFailed event")
      loadAsCurrentPreset(defPath)
      saveProfile()
    }
  }
}

eventbus_subscribe("controls.presetLoadFailed", @(p) failedLoadPreset.set(p.basePresetPath))

eventbus_subscribe("on_renderer_init_environment", @(_) setTonemappingMode(getTonemappingMode()))

return initOptions
