from "%scripts/dagui_library.nut" import *
from "eventbus" import eventbus_send, eventbus_subscribe
from "graphicsOptions" import onRendererSettingsChange
from "dagor.workcycle" import deferOnce
from "%sqstd/platform.nut" import is_pc

let IS_ENABLED = is_pc

local needReloadGui = false
local cbFunc = null











function applyRendererSettingsChange(shouldReloadScene = false, cb = null) {
  if (!IS_ENABLED)
    return
  needReloadGui = shouldReloadScene
  cbFunc = cb
  onRendererSettingsChange()
}







function onRendererSettingsApplied(evt) {
  let forceReloadGui = evt.need_reload
  deferOnce(function() {
    needReloadGui = needReloadGui || forceReloadGui
    if (needReloadGui)
      eventbus_send("reloadDargVM", { msg = "debug resolution changed" })
    cbFunc?()
    needReloadGui = false
    cbFunc = null
  })
}

if (IS_ENABLED)
  eventbus_subscribe("on_renderer_settings_applied", onRendererSettingsApplied)

return applyRendererSettingsChange
