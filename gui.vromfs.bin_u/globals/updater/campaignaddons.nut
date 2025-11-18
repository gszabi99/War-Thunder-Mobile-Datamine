from "%globalScripts/logs.nut" import *
from "math" import max, min
from "dagor.localize" import loc
from "%sqstd/math.nut" import getRomanNumeral
from "%appGlobals/unitPresentation.nut" import getUnitLocId
from "%appGlobals/updater/addons.nut" import commonCampaignAddons, campaignAddonsByRank,
  campaignPostfix, soloNewbieByCampaign, coopNewbieByCampaign


let originalCampaigns = {
  ships_new = "ships"
  tanks_new = "tanks"
}
let getCampaignOrig = @(c) originalCampaigns?[c] ?? c

let nbsp = "\u00A0" 

function appendCampaignRankAddons(addons, campaign, mRank) {
  let ext = campaignAddonsByRank?[campaign][mRank]
  if (ext != null)
    addons.extend(ext)
  return addons
}

function getCampaignRankAddons(campaignExt, mRank) {
  let campaign = getCampaignOrig(campaignExt)
  let res = clone (commonCampaignAddons?[campaign] ?? [])
  for (local i = mRank; i >= 1 ; i--)
    appendCampaignRankAddons(res, campaign, i)
  return res
}

function getCampaignPkgsForOnlineBattle(campaignExt, mRank) {
  let campaign = getCampaignOrig(campaignExt)
  let res = clone (commonCampaignAddons?[campaign] ?? [])
  for (local i = mRank + 1; i >= 1 ; i--)
    appendCampaignRankAddons(res, campaign, i)
  return res
}

let getCampaignPkgsForNewbieSingle = @(campaignExt)
  clone (soloNewbieByCampaign?[getCampaignOrig(campaignExt)] ?? [])

function getCampaignPkgsForNewbieCoop(campaignExt, mRank) {
  let campaign = getCampaignOrig(campaignExt)
  let res = clone (coopNewbieByCampaign?[campaign] ?? [])

  
  
  
  let maxRank = max(mRank > 1 ? mRank + 1 : mRank, 1)
  for (local i = maxRank; i >= 1 ; i--)
    appendCampaignRankAddons(res, campaign, i)
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

function getPkgsForCampaign(campaigns) {
  let include = {}
  let exclude = {}
  foreach (campaign, byRank in campaignAddonsByRank) {
    let tbl = campaigns.contains(campaign) ? include : exclude
    foreach (addons in byRank)
      addons.each(@(a) tbl[a] <- a)
  }
  foreach (campaign, addons in commonCampaignAddons) {
    let tbl = campaigns.contains(campaign) ? include : exclude
    addons.each(@(a) tbl[a] <- a)
  }
  return include.filter(@(a) a not in exclude).keys()
}

function appendUnitsLang(resArr, units, campaign, unitsRanksV) {
  let ranks = unitsRanksV?[campaign]
  if (ranks == null)
    return units

  let leftUnits = []
  local minRank = null
  local maxRank = null
  foreach (u in units)
    if (u in ranks) {
      let r = ranks[u]
      minRank = min(r, minRank ?? r)
      maxRank = max(r, maxRank ?? r)
    }
    else
      leftUnits.append(u)

  if (maxRank != null) {
    let name = loc($"addon/{campaignPostfix?[campaign] ?? campaign}_tier",
      { tier = maxRank == minRank ? getRomanNumeral(minRank) : $"{getRomanNumeral(minRank)}-{getRomanNumeral(maxRank)}" })
    resArr.append(name.replace(" ", nbsp))
  }
  return leftUnits
}

function localizeUnitsResources(units, allUnitsRanksV, prefferedCampaign = "") {
  if (units.len() < 3)
    return units.map(@(u) loc(getUnitLocId(u)))

  let resArr = []
  local remainUnits = appendUnitsLang(resArr, units, getCampaignOrig(prefferedCampaign), allUnitsRanksV)
  foreach (c, _ in allUnitsRanksV)
    if (remainUnits.len() == 0)
      break
    else
      remainUnits = appendUnitsLang(resArr, remainUnits, c, allUnitsRanksV)

  if (resArr.len() == 0 && units.len() != 0)
    return [ loc("download/unitResources") ]
  return resArr
}

return {
  getCampaignRankAddons
  getCampaignPkgsForOnlineBattle
  getCampaignPkgsForNewbieCoop
  getCampaignPkgsForNewbieSingle
  getAddonCampaign
  getCampaignOrig
  getPkgsForCampaign
  localizeUnitsResources
}
