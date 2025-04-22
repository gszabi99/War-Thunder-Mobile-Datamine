from "%scripts/dagui_natives.nut" import set_show_attachables, set_hue
from "%scripts/dagui_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { TARGET_HUE_ALLY, TARGET_HUE_ENEMY } = require("colorCorrector")
let { loadAsCurrentPreset, getDefaultPresetPath } = require("controls")
let { saveProfile } = require("%scripts/clientState/saveProfile.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let failedLoadPreset = hardPersistWatched("options.failedLoadPreset", null)

function initOptions() {
  
  set_hue(TARGET_HUE_ALLY, -1)
  set_hue(TARGET_HUE_ENEMY, -1)

  
  set_show_attachables(true)

  if (failedLoadPreset.value != null) {
    let preset = failedLoadPreset.value
    let defPath = getDefaultPresetPath()
    failedLoadPreset(null)
    if (preset == defPath)
      log("[SQ_CTRL] Ignore controls.presetLoadFailed because of failed to load default preset")
    else {
      log("[SQ_CTRL] Load default preset by controls.presetLoadFailed event")
      loadAsCurrentPreset(defPath)
      saveProfile()
    }
  }
}

eventbus_subscribe("controls.presetLoadFailed", @(p) failedLoadPreset(p.basePresetPath))

return initOptions
