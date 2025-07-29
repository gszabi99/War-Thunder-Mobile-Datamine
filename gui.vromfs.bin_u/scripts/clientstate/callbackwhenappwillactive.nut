from "%scripts/dagui_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { windowActive } = require("%appGlobals/windowState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let cbs = hardPersistWatched("callbackWhenAppWillActive", [])

function popCbs() {
  let list = cbs.value
  cbs([])
  foreach(eventFn in list)
    eventFn()
}

windowActive.subscribe(function(v) {
  if (v && cbs.value.len() != 0)
    deferOnce(popCbs)
})

let callbackWhenAppWillActive = @(eventFn) cbs.mutate(@(v) v.append(eventFn))

return callbackWhenAppWillActive
