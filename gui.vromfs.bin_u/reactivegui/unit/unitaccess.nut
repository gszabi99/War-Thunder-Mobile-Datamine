from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/battleMods.nut" import blockedResearchByBattleMods, activeBattleMods, accessResearchCfg
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/gameModes/newbieOfflineMissions.nut" import hasFirstBattleRewards


let battleModsByBlockedCountries = Computed(@() blockedResearchByBattleMods.get()?[curCampaign.get()]
  .filter(@(battleMod) !activeBattleMods.get()?[battleMod]) ?? {})
let newbieBlockedCountries = Computed(@() !hasFirstBattleRewards.get() ? {}
  : (accessResearchCfg.get()?[curCampaign.get()] ?? {}).filter(@(v) !activeBattleMods.get()?[v.battleMod]))

let blockedCountries = Computed(function() {
  let res = {}
  foreach (country, _ in newbieBlockedCountries.get())
    res[country] <- true
  foreach (country, _ in battleModsByBlockedCountries.get())
    res[country] <- true
  return res
})

let byBlockedUnits = Computed(function() {
  let battleModsByCountries = battleModsByBlockedCountries.get()
  let newbieCountries = newbieBlockedCountries.get()
  if (battleModsByCountries.len() == 0 && newbieCountries.len() == 0)
    return {}
  let res = {}
  let { unitTreeNodes = {} } = serverConfigs.get()
  foreach (name, node in unitTreeNodes?[curCampaign.get()] ?? {})
    if (node.country in battleModsByCountries)
      res[name] <- battleModsByCountries[node.country]
    else if (node.country in newbieCountries)
      res[name] <- null
  return res
})

return {
  byBlockedUnits
  blockedCountries
}