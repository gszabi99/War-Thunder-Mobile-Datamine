from "%globalsDarg/darg_library.nut" import *
let sharedWatches = require("%rGui/dmViewer/sharedWatches.nut")

let unitsDataCollection = {}
let dmViewerUnitDataVer = Watched(0)

function clearDmViewerUnitDataCollection() {
  if (unitsDataCollection.len() == 0)
    return
  unitsDataCollection.clear()
  dmViewerUnitDataVer.set(dmViewerUnitDataVer.get() + 1)
}

function getDmViewerUnitData(unitName) {
  if (unitName not in unitsDataCollection)
    unitsDataCollection[unitName] <- {}
  return unitsDataCollection[unitName]
}

let onNeedReset = @(_) clearDmViewerUnitDataCollection()
sharedWatches.each(@(w) w.subscribe(onNeedReset))

return {
  getDmViewerUnitData
  dmViewerUnitDataVer
  clearDmViewerUnitDataCollection
}
