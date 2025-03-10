from "%globalsDarg/darg_library.nut" import *

let unitsDataCache = {}

let clearDmViewerUnitDataCache = @() unitsDataCache.clear()

function getDmViewerUnitData(unitName) {
  if (unitName not in unitsDataCache)
    unitsDataCache[unitName] <- {}
  return unitsDataCache[unitName]
}

return {
  getDmViewerUnitData
  clearDmViewerUnitDataCache
}
