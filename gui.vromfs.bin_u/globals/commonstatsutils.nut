from "%globalScripts/logs.nut" import *
let { allUnitsCfgFlat } = require("%appGlobals/pServer/profile.nut")

// Compatibility with Dedicated before 2024-07-29 (commit https://cvs1.gaijin.lan/c/dagor4/+/494651)
function compatibilityConvertCommonStats(data) {
  if (("units" in data) || ("unit" not in data))
    return data

  data = clone data
  let unitInfo = clone data.unit
  data.$rawdelete("unit")
  let { name = "", platoonUnits = {} } = unitInfo
  unitInfo.$rawdelete("name")
  unitInfo.$rawdelete("platoonUnits")
  local unitCfg = allUnitsCfgFlat.get()?[name]
  unitInfo.__update({
    country = unitCfg?.country ?? ""
    isCollectible = unitCfg?.isCollectible ?? false
  })
  let units = { [name] = unitInfo }
  foreach (puName, _ in platoonUnits) {
    unitCfg = allUnitsCfgFlat.get()?[puName] ?? unitInfo
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
