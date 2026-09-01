from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/battleMods.nut" import blockedResearchByBattleMods, activeBattleMods
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs


let blockedCountries = Computed(@() blockedResearchByBattleMods.get()?[curCampaign.get()]
  .filter(@(battleMod) battleMod not in activeBattleMods.get()) ?? {})

let unitsBlockedByBattleMode = Computed(function() {
  let blocks = blockedResearchByBattleMods.get()
  if (blocks.len() == 0 || blockedCountries.get().len() == 0)
    return {}
  let res = {}
  let { unitTreeNodes = {} } = serverConfigs.get()
  foreach (camp, bList in blocks)
    foreach (country, mode in bList)
      foreach (name, node in unitTreeNodes?[camp] ?? {})
        if (node.country == country && country in blockedCountries.get())
          res[name] <- mode
  return res
})

return {
  unitsBlockedByBattleMode
  blockedCountries
}