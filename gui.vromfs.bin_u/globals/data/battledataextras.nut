from "%globalScripts/logs.nut" import *
from "%appGlobals/pServer/profile.nut" import campUnitsCfg
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile


function mkResearchingUnitForBattleData() {
  let { unitsResearch = {} } = servProfile.get()
  let { unitResearchExp = {} } = serverConfigs.get()
  let researchingUnitId = unitsResearch.findindex(@(v) v?.isCurrent)
  let exp = unitsResearch?[researchingUnitId].exp ?? 0
  let reqExp = unitResearchExp?[researchingUnitId] ?? 0
  let unit = campUnitsCfg.get()?[researchingUnitId]
  return unit != null && reqExp > 0 ? { exp, reqExp, unit } : null
}

return {
  mkResearchingUnitForBattleData
}
