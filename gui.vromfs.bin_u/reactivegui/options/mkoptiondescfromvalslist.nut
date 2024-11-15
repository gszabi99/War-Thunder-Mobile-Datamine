from "%globalsDarg/darg_library.nut" import *

function mkOptionDescFromValsList(listVal, locIdPrefix, valToLocIdMap = null) {
  let descs = []
  let knownIds = {}
  foreach (v in listVal) {
    let id = valToLocIdMap?[v] ?? v
    if (id in knownIds)
      continue
    knownIds[id] <- true
    descs.append(loc($"{locIdPrefix}/{id}"))
  }
  return "\n".join(descs, true)
}

return mkOptionDescFromValsList
