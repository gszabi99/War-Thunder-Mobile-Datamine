from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this
let { send } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { windowActive } = require("%globalScripts/windowState.nut")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")

let cbs = mkHardWatched("callbackWhenAppWillActive", [])

let function popCbs() {
  let list = cbs.value
  cbs([])
  foreach(eventId in list)
    send(eventId, {})
}

windowActive.subscribe(function(v) {
  if (v && cbs.value.len() != 0)
    deferOnce(popCbs)
})

let callbackWhenAppWillActive = @(eventId) cbs.mutate(@(v) v.append(eventId))

return callbackWhenAppWillActive
