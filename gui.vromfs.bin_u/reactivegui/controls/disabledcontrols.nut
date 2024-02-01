from "%globalsDarg/darg_library.nut" import *
from  "%sqstd/ecs.nut" import *
let { EventOnShortcutEnable, EventOnAxisEnable, EventOnAllShortcutsEnable } = require("controls")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let enabledControls = mkWatched(persist, "enabledControls", {})
let isAllControlsEnabled = mkWatched(persist, "isAllControlsEnabled", true)

isInBattle.subscribe(function(v) {
  if (v)
    return
  enabledControls.set({})
  isAllControlsEnabled.set(true)
})

register_es("disabled_shortcuts_monitor_es", {
  [EventOnShortcutEnable] = @(evt, _eid, _comp)
    enabledControls.mutate(@(v) v[evt[0]] <- evt[1]),
  [EventOnAxisEnable] = @(evt, _eid, _comp)
    enabledControls.mutate(@(v) v[evt[0]] <- evt[1]),
  [EventOnAllShortcutsEnable] = function(evt, _eid, _comp) {
    isAllControlsEnabled.set(evt[0])
    if (enabledControls.get().len() != 0)
      enabledControls.set({})
  },
})

let isControlEnabled = @(id, enabledControlsV, isAllControlsEnabledV)
  enabledControlsV?[id] ?? isAllControlsEnabledV

let mkIsControlDisabled = @(id)
  Computed(@() !(enabledControls.get()?[id] ?? isAllControlsEnabled.get()))

return {
  enabledControls
  isAllControlsEnabled
  isControlEnabled
  mkIsControlDisabled
}