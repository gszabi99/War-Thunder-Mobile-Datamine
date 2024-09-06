from "%scripts/dagui_library.nut" import *
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")


function mkCommonExtras(battleResult) {
  let res = {}
  if ((battleResult?.reward.playerExp.totalExp ?? 0) > 0) {
    let { unitResearchExp = null } = serverConfigs.get()
    // For campaigns with campaign level progress unit rewards
    if (!isCampaignWithUnitsResearch.get()) {
      let nextLevel = (battleResult?.player.level ?? 0) + 1
      let nextLevelUnits = allUnitsCfg.get().filter(@(u) u.rank == nextLevel
        && !u.isHidden
        && u.costWp > 0
        && u.name not in unitResearchExp)
      res.__update({ nextLevelUnits })
    }
  }
  return res
}

return mkCommonExtras
