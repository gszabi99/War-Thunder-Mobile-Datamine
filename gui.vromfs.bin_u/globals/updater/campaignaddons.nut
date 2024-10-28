from "math" import max

let { TANK, AIR, HELICOPTER } = require("%appGlobals/unitConst.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { commonAddonsByPostfix, extAddonsByRank, knownAddons, campaignPostfix
} = require("%appGlobals/updater/addons.nut")

let aircraftCbtPkgs = ["pkg_cbt_aircraft", "pkg_cbt_aircraft_hq"].filter(@(a) a in knownAddons)
let customUnitPkg = {
  //ships
  germ_destroyer_class1934a_1940 = null
  uk_destroyer_hunt_4series = null
  us_destroyer_fletcher = null
  //tanks
  us_m4a1_1942_sherman = null
  ussr_t_34_1941_l_11 = null
  germ_pzkpfw_IV_ausf_F2 = null,
  //aircrafts
  ["i-15_1934"] = null,
  he51c1 = null,
  ["f3f-2"] = null,
  fw_190a_1 = null,
  il_2m_1943 = null,
  ["p-38k"] = aircraftCbtPkgs,
  ["yak-3t"] = aircraftCbtPkgs,
  ["fw-190c"] = aircraftCbtPkgs
}

let defAddonPostfix = "naval"
let addonPostfixByType = {
  [TANK] = "ground",
  [AIR] = "aircraft",
  [HELICOPTER] = "aircraft",
}
let getAddonPostfix = @(unitName) addonPostfixByType?[getUnitType(unitName)] ?? defAddonPostfix
let getCampaignByPostfix = @(postfix) campaignPostfix.findindex(@(v) v == postfix)

function appendRankAddon(addons, postfix, mRank) {
  let addon = $"pkg_tier_{mRank}_{postfix}"
  if (addon in knownAddons)
    addons.append(addon)
  let addonHq = $"{addon}_hq"
  if (addonHq in knownAddons)
    addons.append(addonHq)
  return addons
}

function appendCampaignExtAddons(addons, campaign, mRank) {
  let ext = extAddonsByRank?[campaign][mRank]
  if (ext != null)
    addons.extend(ext)
  return addons
}

function appendSideAddons(addons, mRank) {
  let addon = $"pkg_common_{mRank}_aircraft"
  if (addon in knownAddons)
    addons.append(addon)
  let addonHq = $"{addon}_hq"
  if (addonHq in knownAddons)
    addons.append(addonHq)
  return addons
}

function getUnitPkgs(unitName, mRank) {
  if (unitName in customUnitPkg)
    return customUnitPkg[unitName] ?? []
  let postfix = getAddonPostfix(unitName)
  let campaign = getCampaignByPostfix(postfix)
  let res = clone (commonAddonsByPostfix?[postfix] ?? [])
  for (local i = mRank; i >= 1; i--) {
    appendRankAddon(res, postfix, i)
    appendCampaignExtAddons(res, campaign, i)
    appendSideAddons(res, i)
  }
  return res
}

let getCampaignAddonPostfix = @(campaign) campaignPostfix?[campaign] ?? "naval"

function getCampaignPkgsForOnlineBattle(campaign, mRank) {
  let postfix = getCampaignAddonPostfix(campaign)
  let res = clone (commonAddonsByPostfix?[postfix] ?? [])
  for (local i = mRank + 1; i >= 1 ; i--) {
    appendRankAddon(res, postfix, i)
    appendCampaignExtAddons(res, campaign, i)
    appendSideAddons(res, i)
  }
  return res
}

function getCampaignPkgsForNewbieBattle(campaign, mRank, isSingle) {
  let postfix = getCampaignAddonPostfix(campaign)
  let res = clone (commonAddonsByPostfix?[postfix] ?? [])
  //we don't want to bots have higher rank than player in the single battle,
  //but mRank == 1 is tested regulary when test novice experience, but rare case about novice purchase high level tank not good tested.
  //so beeter player to download +1 pack as in the online mode in such case to ensure crash safe
  let maxRank = max(mRank > 1 ? mRank + 1 : mRank, isSingle ? 0 : 1)
  for (local i = maxRank; i >= 1 ; i--) {
    appendRankAddon(res, postfix, i)
    appendCampaignExtAddons(res, campaign, i)
    appendSideAddons(res, i)
  }
  return res
}

function getAddonCampaignImpl(addon) {
  let list = addon.split("_")
  let postfixIdx = list.len() - (list.top() == "hq" ? 2 : 1)
  let postfix = list[postfixIdx]
  return campaignPostfix.findindex(@(v) v == postfix)
}

let addonCampaigns = {}
function getAddonCampaign(addon) {
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
