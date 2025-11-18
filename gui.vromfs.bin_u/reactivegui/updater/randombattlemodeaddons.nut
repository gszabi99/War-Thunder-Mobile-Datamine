from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { hasAddons, addonsExistInGameFolder, addonsVersions, unitSizes
} = require("%appGlobals/updater/addonsState.nut")
let { isInSquad, squadLeaderCampaign } = require("%appGlobals/squadState.nut")
let { randomBattleMode } = require("%rGui/gameModes/gameModeState.nut")
let { getModeAddonsInfo, allBattleUnits, missingUnitResourcesByRank, maxReleasedUnitRanks
} = require("%appGlobals/updater/gameModeAddons.nut")


let EMPTY_ADDONS_INFO = freeze({ addons = [], units = [] })

let requiredRandomBattleAddons = Computed(function() {
  if (randomBattleMode.get() == null)
    return EMPTY_ADDONS_INFO
  let { addonsToDownload, unitsToDownload } = getModeAddonsInfo({
    mode = randomBattleMode.get(),
    unitNames = allBattleUnits.get(),
    serverConfigsV = serverConfigs.get(),
    hasAddonsV = hasAddons.get(),
    addonsExistInGameFolderV = addonsExistInGameFolder.get(),
    addonsVersionsV = addonsVersions.get(),
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