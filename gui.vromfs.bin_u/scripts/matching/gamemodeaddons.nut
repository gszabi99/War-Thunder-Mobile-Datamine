from "%scripts/dagui_library.nut" import *
let { get_addon_version, is_addon_exists_in_game_folder } = require("contentUpdater")
let { check_version } = require("%sqstd/version_compare.nut")
let { tostring_r } = require("%sqstd/string.nut")
let { isNewbieMode, isNewbieModeSingle } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { getCampaignPkgsForOnlineBattle, getCampaignPkgsForNewbieBattle
} = require("%appGlobals/updater/campaignAddons.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")
let { gameModeAddonToAddonSetMap, ADDON_VERSION_EMPTY, knownAddons } = require("%appGlobals/updater/addons.nut")


let getModeAddonsDbgString = @(mode)
  $"only_override_units = {mode?.only_override_units ?? false}, reqPkg = {tostring_r(mode?.reqPkg ?? {})}"

function getModeAddonsInfo(mode, unitNames) {
  let { reqPkg = {}, campaign = curCampaign.value, name = "", only_override_units = false } = mode
  local addons = {}  //addon = needDownload
  local allReqAddons = {}
  local updateDiff = 0

  let processAddon = function (addon, reqVersion) {
    allReqAddons[addon] <- true
    if (is_addon_exists_in_game_folder(addon)) {
      addons[addon] <- false
      return
    }
    let version = get_addon_version(addon)
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
      mRank = max(mRank, serverConfigs.value?.allUnits[uName].mRank ?? 1)
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
  }

  let toDownload = addons.filter(@(v) v)
  foreach (addon, _ in addons) {
    let list = gameModeAddonToAddonSetMap?[addon]
    if (list == null)
      continue
    foreach (a in list)
      if (a not in addons && !hasAddons.value?[a])
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

return {
  getModeAddonsInfo
  getModeAddonsDbgString
}