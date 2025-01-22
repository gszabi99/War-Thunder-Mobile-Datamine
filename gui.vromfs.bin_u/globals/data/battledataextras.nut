from "%globalScripts/logs.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { campUnitsCfg } = require("%appGlobals/pServer/profile.nut")

function mkResearchingUnitForBattleData() {
  if (!isCampaignWithUnitsResearch.get())
    return null
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
