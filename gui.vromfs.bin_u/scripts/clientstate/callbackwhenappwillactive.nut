from "%scripts/dagui_library.nut" import *
let { send } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { windowActive } = require("%globalScripts/windowState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let cbs = hardPersistWatched("callbackWhenAppWillActive", [])

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
