from "dagor.workcycle" import deferOnce
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/windowState.nut" import windowActive


let cbs = hardPersistWatched("callbackWhenAppWillActive", [])

function popCbs() {
  let list = cbs.get()
  cbs.set([])
  foreach(eventFn in list)
    eventFn()
}

windowActive.subscribe(function(v) {
  if (v && cbs.get().len() != 0)
    deferOnce(popCbs)
})

let callbackWhenAppWillActive = @(eventFn) cbs.mutate(@(v) v.append(eventFn))

return callbackWhenAppWillActive
