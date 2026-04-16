from "%globalScripts/logs.nut" import *
from "math" import max, min
from "frp" import Computed
let { get_unittags_blk } = require("blkGetters")
let { tostring_r } = require("%sqstd/string.nut")
let { prevIfEqual } = require("%sqstd/underscore.nut")
let { kwarg } = require("%sqstd/functools.nut")
let { isNewbieMode, isNewbieModeSingle } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { getCampaignPkgsForOnlineBattle, getCampaignPkgsForNewbieCoop, getCampaignPkgsForNewbieSingle,
  getCampaignOrig
} = require("%appGlobals/updater/campaignAddons.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { unitSizes } = require("%appGlobals/updater/addonsState.nut")
let { gameModeAddonToAddonSetMap, knownAddons
} = require("%appGlobals/updater/addons.nut")
let { curCampaignSlotUnits } = require("%appGlobals/pServer/slots.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let unreleasedUnits = require("%appGlobals/pServer/unreleasedUnits.nut")
let { squadMembers, squadLeaderCampaign } = require("%appGlobals/squadState.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { getMGameModeMissionUnitsAndAddons, getBotUnits, addSupportUnits, getHighestRankRange
} = require("%appGlobals/updater/missionUnits.nut")
let { isReadyToFullLoad } = require("%appGlobals/loginState.nut")
let { battleRentInfo } = require("%appGlobals/rentalState.nut")


function addToCampRank(res, camp, name, rank) {
  if (camp not in res)
    res[camp] <- {}
  res[camp][name] <- min(rank, res[camp]?[name] ?? rank)
}

let allUnitsRanks = Computed(function() {
  if (!isReadyToFullLoad.get())
    return {}
  let { allUnits = {} } = serverConfigs.get()
  let res = {}
  foreach (u in allUnits) {
    let { campaign, mRank, name, platoonUnits } = u
    addToCampRank(res, getCampaignOrig(campaign), getTagsUnitName(name), mRank)
    foreach (p in platoonUnits)
      addToCampRank(res, getCampaignOrig(campaign), getTagsUnitName(p.name), mRank)
  }
  let tagsBlk = get_unittags_blk()
  return res.map(@(list) addSupportUnits(list.filter(@(_, u) u in tagsBlk)))
})

let maxReleasedUnitRanks = Computed(function(prev) {
  let unreleased = unreleasedUnits.get()
  let { allUnits = {} } = serverConfigs.get()
  let res = {}
  foreach (u in allUnits) {
    let { campaign, mRank, name } = u
    if (name not in unreleased)
      res[campaign] <- max(res?[campaign] ?? 0, mRank)
  }
  return prevIfEqual(prev, res)
})

let unreleasedUnitTags = Computed(@()
  unreleasedUnits.get().reduce(@(res, v, name) res.$rawset(getTagsUnitName(name), v), {}))

let missingUnitResourcesByRank = Computed(function(prev) {
  let sizes = unitSizes.get()
  let unreleased = unreleasedUnitTags.get()
  let res = {}
  foreach (camp, list in allUnitsRanks.get())
    foreach (name, rank in list) {
      if ((sizes?[name] ?? -1) == 0 || name in unreleased)
        continue
      if (camp not in res)
        res[camp] <- {}
      if (rank not in res[camp])
        res[camp][rank] <- {}
      res[camp][rank][name] <- true
    }
  return prevIfEqual(prev, res)
})

function getMissingUnitsForRank(campaign, mRank, missingList) {
  let res = {}
  foreach (rank, list in missingList?[getCampaignOrig(campaign)] ?? {})
    if (rank <= mRank)
      res.__update(list)
  return res
}

let getModeAddonsDbgString = @(mode)
  $"only_override_units = {mode?.only_override_units ?? false}, reqPkg = {tostring_r(mode?.reqPkg ?? {})}"

let getModeAddonsInfo = kwarg(function getModeAddonsInfoImpl(modeList, unitNames, serverConfigsV, hasAddonsV,
    missingUnitResourcesByRankV, maxReleasedUnitRanksV, unitSizesV
) {
  let allReqAddons = {}
  let allReqUnits = {}
  foreach (mode in modeList) {
    let { reqPkg = {}, campaign = "", name = "", only_override_units = false } = mode

    foreach (addon, _ in reqPkg) {
      allReqAddons[addon] <- true
      let addonHq = $"{addon}_hq"
      if (addonHq in knownAddons)
        allReqAddons[addonHq] <- true
    }

    local mRank = 1
    foreach(uName in unitNames)
      mRank = max(mRank, serverConfigsV?.allUnits[uName].mRank ?? 1)
    let maxRank = only_override_units ? mRank
      : min(getHighestRankRange(mode, mRank, mRank).to, maxReleasedUnitRanksV?[campaign] ?? (mRank + 1))

    if (!only_override_units) {
      let campAddons = isNewbieModeSingle(name) ? getCampaignPkgsForNewbieSingle(campaign)
        : isNewbieMode(name) ? getCampaignPkgsForNewbieCoop(campaign, mRank)
        : getCampaignPkgsForOnlineBattle(campaign, mRank)
      foreach (addon in campAddons)
        allReqAddons[addon] <- true

      if (isNewbieModeSingle(name))
        allReqUnits.__update(unitNames
          .map(getTagsUnitName)
          .reduce(@(res, u) res.$rawset(u, true), {}))
      else
        allReqUnits.__update(
          getMissingUnitsForRank(campaign, isNewbieMode(name) ? mRank : maxRank, missingUnitResourcesByRankV))
    }

    let { misAddons, misUnits } = getMGameModeMissionUnitsAndAddons(mode, mRank, mRank) 
    foreach (a, _ in misAddons)
      allReqAddons[a] <- true

    allReqUnits.__update(misUnits)
    let botUnits = isNewbieMode(name)
        ? getBotUnits(mode, campaign, mRank, mRank)
        : getBotUnits(mode, campaign, mRank - 1, maxRank)
    allReqUnits.__update(botUnits)
  }

  let allReqAddonsFinal = {}
  foreach (addon, _ in allReqAddons) {
    if (addon in hasAddonsV)
      allReqAddonsFinal[addon] <- true
    let list = gameModeAddonToAddonSetMap?[addon]
    if (list == null)
      continue
    foreach (a in list)
      if (a in hasAddonsV)
        allReqAddonsFinal[a] <- true
  }

  let addonsToDownload = allReqAddonsFinal.filter(@(_, a) !hasAddonsV[a])
  let unitsToDownload = allReqUnits.filter(@(_, u) (unitSizesV?[u] ?? -1) != 0)

  return {
    addonsToDownload = addonsToDownload.keys(),
    allReqAddons = allReqAddonsFinal,
    unitsToDownload = unitsToDownload.keys()
  }
})

let allMyBattleUnits = Computed(function() {
  let res = {}
  let { unit = null, unitList = null } = battleRentInfo.get()
  if (unit != null)
    res[unit] <- true
  if (unitList != null)
    unitList.each(@(name) res[name] <- true)
  if (curCampaignSlotUnits.get() != null)
    curCampaignSlotUnits.get().each(@(name) res[name] <- true)
  else if (curUnit.get() != null)
    res[curUnit.get().name] <- true
  return res
})

let allBattleUnits = Computed(function() {
  let res = clone (allMyBattleUnits.get())
  if (squadLeaderCampaign.get() == curCampaign.get())
    foreach(m in squadMembers.get()) {
      let list = m?.units[squadLeaderCampaign.get()]
      if (type(list) == "array")
        foreach(name in list)
          res[name] <- true
    }
  return res.keys()
})

return {
  getModeAddonsInfo
  getModeAddonsDbgString
  getMissingUnitsForRank

  allMyBattleUnits
  allBattleUnits
  missingUnitResourcesByRank
  allUnitsRanks
  maxReleasedUnitRanks
}