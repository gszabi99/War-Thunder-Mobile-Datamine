from "math" import max
let { TANK, AIR, HELICOPTER } = require("%appGlobals/unitConst.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { commonCampaignAddons, campaignAddonsByRank, knownAddons, campaignPostfix, soloNewbieByCampaign
} = require("%appGlobals/updater/addons.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")

let aircraftCbtPkgs = ["pkg_cbt_aircraft", "pkg_cbt_aircraft_hq"].filter(@(a) a in knownAddons)
let airStarterPkgs = ["pkg_tier_1_aircraft"].filter(@(a) a in knownAddons)
let customUnitPkg = {
  
  germ_destroyer_class1934a_1940 = null
  uk_destroyer_hunt_4series = null
  us_destroyer_fletcher = null
  jp_destroyer_akizuki  = null
  ussr_destroyer_pr56_spokoinyy = null
  
  us_m4a1_1942_sherman = null
  ussr_t_34_1941_l_11 = null
  germ_pzkpfw_IV_ausf_F2 = null,
  
  ["i-15_1934"] = null,
  he51c1 = null,
  ["f3f-2"] = null,
  ["ki_10_2"] = null,
  fw_190a_1 = null,
  il_2m_1943 = null,
  ["p-38k"] = aircraftCbtPkgs,
  ["yak-3t"] = aircraftCbtPkgs,
  ["fw-190c"] = aircraftCbtPkgs,

  ["p-400"]            = airStarterPkgs,
  ["p-400_prem"]       = airStarterPkgs,
  ["me-410a-1"]        = airStarterPkgs,
  ["me-410a-1_prem"]   = airStarterPkgs,
  ["bf-109e-3"]        = airStarterPkgs,
  ["bf-109e-3_prem"]   = airStarterPkgs,
  i_180                = airStarterPkgs,
  i_180_prem           = airStarterPkgs,
  f4f_4                = airStarterPkgs,
  f4f_4_prem           = airStarterPkgs,
  ["yak-9"]            = airStarterPkgs,
  ["yak-9_prem"]       = airStarterPkgs,
}

let defAddonCampaign = "ships"
let addonCampaignByType = {
  [TANK] = "tanks",
  [AIR] = "air",
  [HELICOPTER] = "air",
}
let getCampaignByUnitName = @(unitName) addonCampaignByType?[getUnitType(unitName)] ?? defAddonCampaign

let originalCampaigns = {
  ships_new = "ships"
}
let getCampaignOrig = @(c) originalCampaigns?[c] ?? c

function appendCampaignRankAddons(addons, campaign, mRank) {
  let ext = campaignAddonsByRank?[campaign][mRank]
  if (ext != null)
    addons.extend(ext)
  return addons
}

function getUnitPkgs(realUnitName, mRank) {
  let unitName = getTagsUnitName(realUnitName)
  if (unitName in customUnitPkg)
    return customUnitPkg[unitName] ?? []
  let campaign = getCampaignByUnitName(unitName)
  let res = clone (commonCampaignAddons?[campaign] ?? [])
  for (local i = mRank; i >= 1; i--)
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

function getCampaignPkgsForNewbieBattle(campaignExt, mRank, isSingle) {
  let campaign = getCampaignOrig(campaignExt)
  if (isSingle && mRank <= 1)
    return soloNewbieByCampaign?[campaign] ?? []

  let res = clone (commonCampaignAddons?[campaign] ?? [])

  
  
  
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

return {
  getUnitPkgs
  getCampaignPkgsForOnlineBattle
  getCampaignPkgsForNewbieBattle
  getAddonCampaign
  getCampaignOrig
}
