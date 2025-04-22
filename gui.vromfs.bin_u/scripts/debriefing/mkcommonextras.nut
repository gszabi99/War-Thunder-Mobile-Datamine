from "%scripts/dagui_library.nut" import *

function mkCommonExtras(battleResult, serverConfigsV) {
  let res = {}
  if ((battleResult?.reward.playerExp.totalExp ?? 0) > 0) {
    let { unitResearchExp = null, unitTreeNodes = null, allUnits = {} } = serverConfigsV
    let { campaign = null } = battleResult
    let isCampaignWithResearch = campaign in unitTreeNodes
    
    if (!isCampaignWithResearch) {
      let nextLevel = (battleResult?.player.level ?? 0) + 1
      let nextLevelUnits = allUnits.filter(@(u)
        u.campaign == campaign
        && u.rank == nextLevel
        && !u.isHidden
        && u.costWp > 0
        && u.name not in unitResearchExp)
      res.__update({ nextLevelUnits })
    }
  }
  return res
}

return mkCommonExtras
