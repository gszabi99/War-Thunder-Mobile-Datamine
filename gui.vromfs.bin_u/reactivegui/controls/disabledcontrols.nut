from "%globalsDarg/darg_library.nut" import *
from  "%sqstd/ecs.nut" import *
let { EventOnShortcutEnable = null, EventOnAxisEnable = null } = require("controls")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let disabledControls = mkWatched(persist, "disabledControls", {})

isInBattle.subscribe(@(v) v ? null : disabledControls.set({}))

if (EventOnShortcutEnable != null && EventOnAxisEnable != null)
  register_es("disabled_shortcuts_monitor_es", {
    [EventOnShortcutEnable] = @(evt, _eid, _comp)
      disabledControls.mutate(@(v) v[evt[0]] <- !evt[1]),
    [EventOnAxisEnable] = @(evt, _eid, _comp)
      disabledControls.mutate(@(v) v[evt[0]] <- !evt[1]),
  })

return disabledControls