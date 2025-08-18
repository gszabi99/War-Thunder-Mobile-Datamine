from "math" import max
let { Computed } = require("frp")
let { check_version } = require("%sqstd/version_compare.nut")
let { tostring_r } = require("%sqstd/string.nut")
let { isNewbieMode, isNewbieModeSingle } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { getCampaignPkgsForOnlineBattle, getCampaignPkgsForNewbieCoop, getCampaignPkgsForNewbieSingle
} = require("%appGlobals/updater/campaignAddons.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { ADDON_VERSION_EMPTY } = require("%appGlobals/updater/addonsState.nut")
let { gameModeAddonToAddonSetMap, knownAddons
} = require("%appGlobals/updater/addons.nut")
let { curCampaignSlotUnits } = require("%appGlobals/pServer/slots.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { squadMembers, squadLeaderCampaign } = require("%appGlobals/squadState.nut")


let getModeAddonsDbgString = @(mode)
  $"only_override_units = {mode?.only_override_units ?? false}, reqPkg = {tostring_r(mode?.reqPkg ?? {})}"

function getModeAddonsInfo(mode, unitNames, serverConfigsV, hasAddonsV, addonsExistInGameFolderV, addonsVersionsV) {
  let { reqPkg = {}, campaign = curCampaign.get(), name = "", only_override_units = false } = mode
  local addons = {}  
  local allReqAddons = {}
  local updateDiff = 0

  let processAddon = function (addon, reqVersion) {
    allReqAddons[addon] <- true
    if (addonsExistInGameFolderV?[addon]) {
      addons[addon] <- false
      return
    }
    let version = addonsVersionsV?[addon] ?? ADDON_VERSION_EMPTY
    if (version != ADDON_VERSION_EMPTY && check_version(reqVersion, version)) {
      addons[addon] <- false
      return
    }
    addons[addon] <- true
    updateDiff += version == "" ? -1 : 1
  }

  foreach (addon, reqVersion in reqPkg) {
    processAddon(addon, reqVersion)

    let addonHq = $"{addon}_hq"
    if (addonHq in knownAddons)
      processAddon(addonHq, reqVersion)
  }

  if (!only_override_units) {
    local mRank = 1
    foreach(uName in unitNames)
      mRank = max(mRank, serverConfigsV?.allUnits[uName].mRank ?? 1)
    let campAddons = isNewbieModeSingle(name)
        ? getCampaignPkgsForNewbieSingle(campaign, mRank, unitNames)
      : isNewbieMode(name)
        ? getCampaignPkgsForNewbieCoop(campaign, mRank)
      : getCampaignPkgsForOnlineBattle(campaign, mRank)
    foreach (addon in campAddons) {
      allReqAddons[addon] <- true
      if (addon in addons)
        continue
      let has = hasAddonsV?[addon] ?? false
      addons[addon] <- !has
      updateDiff += has ? 0 : -1
    }
  }

  let toDownload = addons.filter(@(v) v)
  foreach (addon, _ in addons) {
    let list = gameModeAddonToAddonSetMap?[addon]
    if (list == null)
      continue
    foreach (a in list)
      if (a not in addons && !hasAddonsV?[a])
        toDownload[a] <- true
  }

  let allReqAddonsFinal = clone allReqAddons
  foreach (addon, _ in allReqAddons) {
    let list = gameModeAddonToAddonSetMap?[addon]
    if (list == null)
      continue
    foreach (a in list)
      allReqAddonsFinal[a] <- true
  }

  return { addonsToDownload = toDownload.keys(), updateDiff, allReqAddons = allReqAddonsFinal }
}

let allMyBattleUnits = Computed(function() {
  let res = {}
  if (curCampaignSlotUnits.get() != null)
    curCampaignSlotUnits.get().each(@(name) res[name] <- true)
  else if (curUnit.get() != null)
    res[curUnit.get().name] <- true
  return res
})

let allBattleUnits = Computed(function() {
  let res = clone (allMyBattleUnits.get())
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

  allMyBattleUnits
  allBattleUnits
}