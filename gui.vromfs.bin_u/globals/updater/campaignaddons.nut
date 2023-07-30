//checked for explicitness
#no-root-fallback
#explicit-this
let { get_settings_blk } = require("blkGetters")
let { TANK } = require("%appGlobals/unitConst.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { naval, ground } = require("%appGlobals/updater/addons.nut")

let campaignPostfix = {
  tanks = "ground"
  ships = "naval"
}

let customUnitPkg = {
  //ships
  germ_destroyer_class1934a_1940 = null
  uk_destroyer_hunt_4series = null
  us_destroyer_fletcher = null
  //tanks
  us_m4a1_1942_sherman = null
  ussr_t_34_1941_l_11 = null
  germ_pzkpfw_IV_ausf_F2 = null
}

let knownAddons = {}
let addonsBlk = get_settings_blk()?.addons
if (addonsBlk != null)
  foreach (folder in addonsBlk % "folder")
    if (type(folder) == "string")
      knownAddons[folder.split("/").top()] <- true

let commonAddons = { ground, naval }
let getAddonPostfix = @(unitName) getUnitType(unitName) == TANK ? "ground" : "naval"

let function appendRankAddon(addons, postfix, mRank) {
  let addon = $"pkg_tier_{mRank}_{postfix}"
  if (addon in knownAddons)
    addons.append(addon)
  let addonHq = $"{addon}_hq"
  if (addonHq in knownAddons)
    addons.append(addonHq)
  return addons
}

let function getUnitPkgs(unitName, mRank) {
  if (unitName in customUnitPkg)
    return customUnitPkg[unitName] ?? []
  let postfix = getAddonPostfix(unitName)
  let res = clone (commonAddons?[postfix] ?? [])
  for (local i = mRank; i >= 1; i--)
    appendRankAddon(res, postfix, i)
  return res
}

let getCampaignAddonPostfix = @(campaign) campaignPostfix?[campaign] ?? "naval"

let function getCampaignPkgsForOnlineBattle(campaign, mRank) {
  let postfix = getCampaignAddonPostfix(campaign)
  let res = clone (commonAddons?[postfix] ?? [])
  for (local i = mRank + 1; i >= 1 ; i--)
    appendRankAddon(res, postfix, i)
  return res
}

let function getCampaignPkgsForNewbieBattle(campaign, isSingle) {
  let postfix = getCampaignAddonPostfix(campaign)
  let res = clone (commonAddons?[postfix] ?? [])
  if (!isSingle)
    appendRankAddon(res, postfix, 1)
  return res
}

let function getAddonCampaignImpl(addon) {
  let list = addon.split("_")
  let postfixIdx = list.len() - (list.top() == "hq" ? 2 : 1)
  let postfix = list[postfixIdx]
  return campaignPostfix.findindex(@(v) v == postfix)
}

let addonCampaigns = {}
let function getAddonCampaign(addon) {
  if (addon not in addonCampaigns)
    addonCampaigns[addon] <- getAddonCampaignImpl(addon)
  return addonCampaigns[addon]
}

return {
  getUnitPkgs
  getCampaignPkgsForOnlineBattle
  getCampaignPkgsForNewbieBattle
  getAddonCampaign
}
