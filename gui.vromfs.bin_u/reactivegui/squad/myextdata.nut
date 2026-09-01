from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/gameModes/gameModes.nut" import gameModeQueueGroups, getGameModeQueueGroup
from "%appGlobals/pServer/battleMods.nut" import activeBattleMods
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/pServer/slots.nut" import curSlots
from "%appGlobals/queueState.nut" import myQueueToken, jwtUserstat
from "%appGlobals/squadState.nut" import myClustersRTT, queueDataCheckTime, isInSquad
from "%appGlobals/updater/addonsState.nut" import hasAddons, unitSizes
from "%appGlobals/updater/gameModeAddons.nut" import missingUnitResourcesByRank, allUnitsRanks, getModeAddonsInfo,
  maxReleasedUnitRanks
from "%rGui/decorators/decoratorState.nut" import chosenDecoratorsHash
from "%rGui/gameModes/gameModeState.nut" import ovrUnitsGameModes
from "%rGui/squad/downloadCheck.nut" import wantedModeId, downloadCheckTime
from "%rGui/squad/mRankCheck.nut" import mRankCheckTime
from "%rGui/squad/readyCheck.nut" import readyCheckTime
from "%rGui/squad/squadManager.nut" import bindSquadROVar


let curUnitInfos = keepref(Computed(function(prev) {
  let { allUnits = null, campaignCfg = {} } = serverConfigs.get()
  let { units = null } = servProfile.get()
  if (units == null || allUnits == null)
    return null

  let mkInfo = @(name) { name, isUpgraded = units?[name].isUpgraded ?? false }

  let res = {}
  foreach (u in units) {
    if (!u?.isCurrent)
      continue
    let campaign = allUnits?[u.name].campaign
    if (campaign != null && campaign not in res)
      res[campaign] <- [{ name = u.name, isUpgraded = u?.isUpgraded ?? false }]
  }
  foreach (campaign, cfg in campaignCfg)
    if (cfg.totalSlots > 0)
      res[campaign] <- curSlots.get()
        .filter(@(s) s.name != "")
        .map(@(s) mkInfo(s.name))
        ?? []
  return prevIfEqual(prev, res)
}))

let curUnits = keepref(Computed(@(prev) prevIfEqual(prev,
  curUnitInfos.get()?.map(@(infos) infos.map(@(u) u.name))))) 

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
      modeList = getGameModeQueueGroup(mode, gameModeQueueGroups.get()),
      unitNames = [],
      serverConfigsV = serverConfigs.get(),
      hasAddonsV = hasAddons.get(),
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
bindSquadROVar("unitInfos", curUnitInfos)
bindSquadROVar("missingAddons", missingAddons)
bindSquadROVar("queueToken", myQueueToken)
bindSquadROVar("statsToken", jwtUserstat)
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
