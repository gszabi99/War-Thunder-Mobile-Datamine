from "%globalScripts/logs.nut" import *
let { getPlatoonUnitCfgNonUpdatable } = require("%appGlobals/pServer/allMainUnitsByPlatoon.nut")

// Compatibility with Dedicated before 2024-07-29
function compatibilityConvertCommonStats(data) {
  if (("units" in data) || ("unit" not in data))
    return data

  data = clone data
  let unitInfo = clone data.unit
  data.$rawdelete("unit")
  let { name = "", platoonUnits = {} } = unitInfo
  unitInfo.$rawdelete("name")
  unitInfo.$rawdelete("platoonUnits")
  local unitCfg = getPlatoonUnitCfgNonUpdatable(name)
  unitInfo.__update({
    country = unitCfg?.country ?? ""
    isCollectible = unitCfg?.isCollectible ?? false
  })
  let units = { [name] = unitInfo }
  foreach (puName, _ in platoonUnits) {
    unitCfg = getPlatoonUnitCfgNonUpdatable(puName) ?? unitInfo
    units[puName] <- unitInfo.map(@(v, k) unitCfg?[k] ?? v)
  }
  data.__update({
    mainUnitName = name
    units
  })

  return data
}

return {
  compatibilityConvertCommonStats
}
