from "math" import max

let { TANK } = require("%appGlobals/unitConst.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { naval, ground, extAddonsByRank, knownAddons, campaignPostfix
} = require("%appGlobals/updater/addons.nut")

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

let commonAddons = { ground, naval }
let getAddonPostfix = @(unitName) getUnitType(unitName) == TANK ? "ground" : "naval"
let getCampaignByPostfix = @(postfix) campaignPostfix.findindex(@(v) v == postfix)

let function appendRankAddon(addons, postfix, mRank) {
  let addon = $"pkg_tier_{mRank}_{postfix}"
  if (addon in knownAddons)
    addons.append(addon)
  let addonHq = $"{addon}_hq"
  if (addonHq in knownAddons)
    addons.append(addonHq)
  return addons
}

let function appendCampaignExtAddons(addons, campaign, mRank) {
  let ext = extAddonsByRank?[campaign][mRank]
  if (ext != null)
    addons.extend(ext)
  return addons
}

let function getUnitPkgs(unitName, mRank) {
  if (unitName in customUnitPkg)
    return customUnitPkg[unitName] ?? []
  let postfix = getAddonPostfix(unitName)
  let campaign = getCampaignByPostfix(postfix)
  let res = clone (commonAddons?[postfix] ?? [])
  for (local i = mRank; i >= 1; i--) {
    appendRankAddon(res, postfix, i)
    appendCampaignExtAddons(res, campaign, i)
  }
  return res
}

let getCampaignAddonPostfix = @(campaign) campaignPostfix?[campaign] ?? "naval"

let function getCampaignPkgsForOnlineBattle(campaign, mRank) {
  let postfix = getCampaignAddonPostfix(campaign)
  let res = clone (commonAddons?[postfix] ?? [])
  for (local i = mRank + 1; i >= 1 ; i--) {
    appendRankAddon(res, postfix, i)
    appendCampaignExtAddons(res, campaign, i)
  }
  return res
}

let function getCampaignPkgsForNewbieBattle(campaign, mRank, isSingle) {
  let postfix = getCampaignAddonPostfix(campaign)
  let res = clone (commonAddons?[postfix] ?? [])
  let maxRank = max(mRank, isSingle ? 0 : 2)
  for (local i = maxRank; i >= 1 ; i--) {
    appendRankAddon(res, postfix, i)
    appendCampaignExtAddons(res, campaign, i)
  }
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
  getAddonPostfix
}
