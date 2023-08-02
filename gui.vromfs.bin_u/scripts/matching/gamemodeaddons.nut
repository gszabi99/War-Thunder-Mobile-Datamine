from "%scripts/dagui_library.nut" import *
let { get_addon_version, is_addon_exists_in_game_folder } = require("contentUpdater")
let { check_version } = require("%sqstd/version_compare.nut")
let { isNewbieMode, isNewbieModeSingle } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { getCampaignPkgsForOnlineBattle, getCampaignPkgsForNewbieBattle
} = require("%appGlobals/updater/campaignAddons.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")
let { gameModeAddonToAddonSetMap } = require("%appGlobals/updater/addons.nut")

let function getModeAddonsInfo(mode, unitName) {
  let { reqPkg = {}, campaign = curCampaign.value, name = "" } = mode
  local addons = {}  //addon = needDownload
  local allReqAddons = {}
  local updateDiff = 0
  foreach (addon, reqVersion in reqPkg) {
    allReqAddons[addon] <- true
    if (is_addon_exists_in_game_folder(addon)) {
      addons[addon] <- false
      continue
    }
    let version = get_addon_version(addon)
    if (version != "" && check_version(reqVersion, version)) {
      addons[addon] <- false
      continue
    }
    addons[addon] <- true
    updateDiff += version == "" ? -1 : 1
  }

  let { mRank = 1 } = serverConfigs.value?.allUnits[unitName]
  let campAddons = isNewbieMode(name)
    ? getCampaignPkgsForNewbieBattle(campaign, mRank, isNewbieModeSingle(name))
    : getCampaignPkgsForOnlineBattle(campaign, mRank)
  foreach (addon in campAddons) {
    allReqAddons[addon] <- true
    if (addon in addons)
      continue
    let has = hasAddons.value?[addon] ?? false
    addons[addon] <- !has
    updateDiff += has ? 0 : -1
  }

  let toDownload = addons.filter(@(v) v)
  foreach (addon in addons) {
    let list = gameModeAddonToAddonSetMap?[addon]
    if (list == null)
      continue
    foreach (a in list)
      if (a not in addons && !hasAddons.value?[a])
        toDownload[a] <- true
  }

  let allReqAddonsFinal = clone allReqAddons
  foreach (addon in allReqAddons) {
    let list = gameModeAddonToAddonSetMap?[addon]
    if (list == null)
      continue
    foreach (a in list)
      allReqAddonsFinal[a] <- true
  }

  return { addonsToDownload = toDownload.keys(), updateDiff, allReqAddons = allReqAddonsFinal }
}

return {
  getModeAddonsInfo
}