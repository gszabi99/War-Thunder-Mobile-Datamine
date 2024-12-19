from "%scripts/dagui_library.nut" import *
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")


function mkCommonExtras(battleResult, srvConfigs) {
  let res = {}
  if ((battleResult?.reward.playerExp.totalExp ?? 0) > 0) {
    let { unitResearchExp = null, unitTreeNodes = null } = srvConfigs
    let isCampaignWithResearch = battleResult?.campaign in unitTreeNodes
    // For campaigns with campaign level progress unit rewards
    if (!isCampaignWithResearch) {
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
