from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { prevIfEqual } = require("%sqstd/underscore.nut")
let { myQueueToken } = require("%appGlobals/queueState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { myClustersRTT, queueDataCheckTime, isInSquad } = require("%appGlobals/squadState.nut")
let { hasAddons, addonsExistInGameFolder, addonsVersions, unitSizes
} = require("%appGlobals/updater/addonsState.nut")
let { missingUnitResourcesByRank, allUnitsRanks, getModeAddonsInfo, maxReleasedUnitRanks
} = require("%appGlobals/updater/gameModeAddons.nut")
let { activeBattleMods } = require("%appGlobals/pServer/battleMods.nut")
let { bindSquadROVar } = require("%rGui/squad/squadManager.nut")
let { readyCheckTime } = require("%rGui/squad/readyCheck.nut")
let { mRankCheckTime } = require("%rGui/squad/mRankCheck.nut")
let { chosenDecoratorsHash } = require("%rGui/decorators/decoratorState.nut")
let { ovrUnitsGameModes } = require("%rGui/gameModes/gameModeState.nut")
let { wantedModeId, downloadCheckTime } = require("%rGui/squad/downloadCheck.nut")


let curUnits = keepref(Computed(function(prev) {
  let { allUnits = null, campaignCfg = {} } = serverConfigs.get()
  let { units = null } = servProfile.get()
  if (units == null || allUnits == null)
    return null
  let res = {}
  foreach(u in units) {
    if (!u?.isCurrent)
      continue
    let campaign = allUnits?[u.name].campaign
    if (campaign != null && campaign not in res)
      res[campaign] <- [u.name]
  }
  foreach(campaign, cfg in campaignCfg)
    if (cfg.totalSlots > 0)
      res[campaign] <- curSlots.get()
        .filter(@(s) s.name != "")
        .map(@(s) s.name)
        ?? []
  return prevIfEqual(prev, res)
}))

let missingAddons = keepref(Computed(function(prev) {
  let res = hasAddons.get().filter(@(v) !v)
    .keys()
    .sort()
  return prevIfEqual(prev, res)
}))

let myBattleMods = keepref(Computed(function(prev) {
  let res = activeBattleMods.get().filter(@(v) v)
    .keys()
    .sort()
  return prevIfEqual(prev, res)
}))

let readyBattleRanks = Computed(function(prev) {
  let res = allUnitsRanks.get().map(@(list) list.reduce(@(res, v) max(res, v + 1), 0)) 
  foreach (camp, list in missingUnitResourcesByRank.get())
    foreach (rank, _ in list)
      res[camp] = min(res[camp], rank - 1)
  return prevIfEqual(prev, res)
})

let readyOvrGameModes = Computed(function(prev) {
  if (!isInSquad.get())
    return prevIfEqual(prev, {})
  let t = get_time_msec()
  let res = {}
  foreach (modeId, mode in ovrUnitsGameModes.get()) {
    let { addonsToDownload, unitsToDownload } = getModeAddonsInfo({
      mode,
      unitNames = [],
      serverConfigsV = serverConfigs.get(),
      hasAddonsV = hasAddons.get(),
      addonsExistInGameFolderV = addonsExistInGameFolder.get(),
      addonsVersionsV = addonsVersions.get(),
      missingUnitResourcesByRankV = missingUnitResourcesByRank.get(),
      maxReleasedUnitRanksV = maxReleasedUnitRanks.get(),
      unitSizesV = unitSizes.get(),
    })
    res[modeId.tostring()] <- addonsToDownload.len() + unitsToDownload.len() == 0
  }

  log($"Calc readyOvrGameModes ({res.len()}) time: {get_time_msec() - t}msec")
  return prevIfEqual(prev, res)
})

bindSquadROVar("campaign", curCampaign)
bindSquadROVar("units", curUnits)
bindSquadROVar("missingAddons", missingAddons)
bindSquadROVar("queueToken", myQueueToken)
bindSquadROVar("inBattle", isInBattle)
bindSquadROVar("readyCheckTime", readyCheckTime)
bindSquadROVar("mRankCheckTime", mRankCheckTime)
bindSquadROVar("queueDataCheckTime", queueDataCheckTime)
bindSquadROVar("clustersRTT", myClustersRTT)
bindSquadROVar("battleMods", myBattleMods)
bindSquadROVar("chosenDecoratorsHash", chosenDecoratorsHash)
bindSquadROVar("readyBattleRanks", readyBattleRanks)
bindSquadROVar("readyOvrGameModes", readyOvrGameModes)
bindSquadROVar("wantedModeId", wantedModeId)
bindSquadROVar("downloadCheckTime", downloadCheckTime)
