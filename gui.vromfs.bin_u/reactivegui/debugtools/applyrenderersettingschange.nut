from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_send, eventbus_subscribe
from "graphicsOptions" import onRendererSettingsChange
from "%sqstd/platform.nut" import is_pc

let IS_ENABLED = is_pc

local needReloadGui = false
let printStatusStr = mkWatched(persist, "printStatusStr", "")











function applyRendererSettingsChange(shouldReloadScene = false, statusStr = "") {
  if (!IS_ENABLED)
    return
  needReloadGui = shouldReloadScene
  printStatusStr.set(statusStr)
  deferOnce(onRendererSettingsChange)
}







function onRendererSettingsApplied(_evt) {
  
  deferOnce(function() {
    if (needReloadGui)
      eventbus_send("reloadDargVM", { msg = "debug resolution changed" })
    let statusStr = printStatusStr.get()
    if (statusStr != "")
      console_print(statusStr) 
    needReloadGui = false
    printStatusStr.set("")
  })
}

if (IS_ENABLED)
  eventbus_subscribe("on_renderer_settings_applied", onRendererSettingsApplied)

return applyRendererSettingsChange
