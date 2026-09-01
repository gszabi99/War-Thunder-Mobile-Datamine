from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/gameModes/gameModes.nut" import gameModeQueueGroups, getGameModeQueueGroup
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/squadState.nut" import isInSquad, squadLeaderCampaign
from "%appGlobals/updater/addonsState.nut" import hasAddons, unitSizes
from "%appGlobals/updater/gameModeAddons.nut" import getModeAddonsInfo, allBattleUnits, missingUnitResourcesByRank,
  maxReleasedUnitRanks
from "%rGui/gameModes/gameModeState.nut" import randomBattleMode


let EMPTY_ADDONS_INFO = freeze({ addons = [], units = [] })

let requiredRandomBattleAddons = Computed(function() {
  if (randomBattleMode.get() == null)
    return EMPTY_ADDONS_INFO
  let { addonsToDownload, unitsToDownload } = getModeAddonsInfo({
    modeList = getGameModeQueueGroup(randomBattleMode.get(), gameModeQueueGroups.get()),
    unitNames = allBattleUnits.get(),
    serverConfigsV = serverConfigs.get(),
    hasAddonsV = hasAddons.get(),
    missingUnitResourcesByRankV = missingUnitResourcesByRank.get(),
    maxReleasedUnitRanksV = maxReleasedUnitRanks.get(),
    unitSizesV = unitSizes.get(),
  })
  return { addons = addonsToDownload, units = unitsToDownload }
})

let isNeedAddonsForRandomBattle = Computed(function() {
  let { addons, units } = requiredRandomBattleAddons.get()
  return addons.len() + units.len() > 0
})

let requiredSquadAddons = Computed(@() isInSquad.get() && squadLeaderCampaign.get() == curCampaign.get()
  ? requiredRandomBattleAddons.get()
  : EMPTY_ADDONS_INFO)

return {
  isNeedAddonsForRandomBattle
  requiredSquadAddons
}