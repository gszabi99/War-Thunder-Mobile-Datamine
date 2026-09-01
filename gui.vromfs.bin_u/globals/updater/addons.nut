from "%globalScripts/logs.nut" import *
from "blkGetters" import get_settings_blk
from "dagor.localize" import loc, doesLocTextExist
from "string" import startswith, endswith
from "%sqstd/datablock.nut" import eachBlock
from "%sqstd/math.nut" import getRomanNumeral
from "%sqstd/string.nut" import toIntegerSafe
from "%sqstd/underscore.nut" import unique
from "types" import String, Integer


const PKG_NAVAL  = "pkg_naval"
const PKG_NAVAL_HQ = "pkg_naval_hq"
const PKG_GROUND = "pkg_ground"
const PKG_GROUND_HQ = "pkg_ground_hq"
const PKG_LVL_AIR_LOCATIONS = "pkg_lvl_air_locations"
const PKG_COMMON = "pkg_common"
const PKG_COMMON_HQ = "pkg_common_hq"
const PKG_DEV = "pkg_dev"

const MB = 1 << 20
const nbsp = "\u00A0" 
let comma = loc("ui/comma")

let initialAddonsByCamp = {} 
let initialAddons = []
let latestDownloadAddonsByCamp = {} 
let latestDownloadAddons = []

let campaignPostfix = {
  tanks = "ground"
  ships = "naval"
  air = "aircraft"
}

let toIdsMap = @(list) list
  .reduce(function(res, v) {
    res[v] <- true
    return res
  }, {})

let addonLocId = toIdsMap([ PKG_COMMON, PKG_COMMON_HQ, PKG_NAVAL_HQ, PKG_GROUND_HQ ])
  .map(@(_) "")
  .__update({
    [PKG_NAVAL]       = "addon/naval",
    [PKG_GROUND]      = "addon/ground",
    [PKG_DEV]         = "addon/dev",
    pkg_secondary_hq  = "addon/pkg_secondary",
  })
let addonLocIdWithMRank = {}

let knownAddons = {}
let campaignAddonsByRank = {}
let commonCampaignAddons = {}
let soloNewbieByCampaign = {}
let coopNewbieByCampaign = {}
let setBlk = get_settings_blk()
let addonsBlk = setBlk?.addons

if (addonsBlk != null) {
  eachBlock(addonsBlk, function(b) {
    let addon = b.getBlockName()
    let addonHq = $"{addon}_hq"

    knownAddons[addon] <- true

    let { hq = true } = b
    if (hq)
      knownAddons[addonHq] <- true

    function appendAddonByKey(list, key) {
      if (key not in list)
        list[key] <- []
      list[key].append(addon)
      if (hq)
        list[key].append(addonHq)
    }

    let allConditions = b % "conditions"
    foreach (conditions in allConditions) {
      let { campaign = null, mRank = null, isSoloNewbie = false, isCoopNewbie = false, isDownloadLast = false,
        isDownloadFirst = false
      } = conditions
      if (isDownloadFirst) {
        if (campaign != null)
          appendAddonByKey(initialAddonsByCamp, campaign)
        else {
          initialAddons.append(addon)
          if (hq)
            initialAddons.append(addonHq)
        }
        continue
      }
      if (isDownloadLast && campaign == null) {
        latestDownloadAddons.append(addon)
        if (hq)
          latestDownloadAddons.append(addonHq)
        continue
      }

      if (!(campaign instanceof String)) {
        logerr($"Invalid type of required field in addon/conditions for '{addon}': campaign = {campaign}")
        continue
      }

      if (isSoloNewbie) {
        appendAddonByKey(soloNewbieByCampaign, campaign)
        appendAddonByKey(coopNewbieByCampaign, campaign)
      }
      if (isCoopNewbie)
        appendAddonByKey(coopNewbieByCampaign, campaign)

      if (!(mRank instanceof Integer)) {
        if (isDownloadLast)
          appendAddonByKey(latestDownloadAddonsByCamp, campaign)
        else if (!isSoloNewbie)
          appendAddonByKey(commonCampaignAddons, campaign)
        continue
      }

      if (campaign not in campaignAddonsByRank)
        campaignAddonsByRank[campaign] <- {}
      appendAddonByKey(campaignAddonsByRank[campaign], mRank)

      if (campaign in campaignPostfix && !doesLocTextExist($"addon/{addon}")) {
        let cfg = { locId = $"addon/{campaignPostfix[campaign]}_tier", mRank }
        addonLocIdWithMRank[addon] <- cfg
        addonLocIdWithMRank[addonHq] <- cfg
      }
    }
  })
}

function calcCommonAddonName(addon) {
  if (addon in addonLocIdWithMRank) {
    let { locId, mRank } = addonLocIdWithMRank[addon]
    return loc(locId, { tier = getRomanNumeral(mRank) }).replace(" ", nbsp)
  }

  let locId = $"addon/{addon}"
  return doesLocTextExist(locId) ? loc(locId) : null
}

function getAddonNameImpl(addon) {
  local locId = addonLocId?[addon]
  if (locId != null)
    return locId == "" ? "" : loc(locId)

  if (startswith(addon, "pkg_level_"))
    return loc("addon/environment")
  if (startswith(addon, "pkg_sound_") || startswith(addon, "pkg_extended_"))
    return loc("options/sound")

  if (startswith(addon, "pkg_tier_") || startswith(addon, "pkg_common_")) {
    let list = addon.split("_")
    let postfixIdx = list.len() - (list.top() == "hq" ? 2 : 1)
    let postfix = list[postfixIdx]
    let tier = toIntegerSafe(list[postfixIdx - 1])
    if (tier <= 0)
      return loc($"addon/{postfix}").replace(" ", nbsp)
    return loc($"addon/{postfix}_tier", { tier = getRomanNumeral(tier) }).replace(" ", nbsp)
  }

  let res = calcCommonAddonName(addon)
  if (res != null)
    return res
  if (endswith(addon, "_hq"))
    return calcCommonAddonName(addon.slice(0, addon.len() - 3)) ?? addon
  return addon
}

let addonNames = {}
function getAddonName(addon) {
  if (addon not in addonNames)
    addonNames[addon] <- getAddonNameImpl(addon)
  return addonNames[addon]
}

function localizeAddons(addons) {
  let res = []
  let locs = {}
  foreach (addon in addons) {
    let text = getAddonName(addon)
    if (text == "" || (text in locs))
      continue
    locs[text] <- true
    res.append(text)
  }
  return res
}

function localizeAddonsLimited(list, maxNumber) {
  let localized = localizeAddons(list)
  let total = localized.len()
  if (total <= maxNumber)
    return comma.join(localized)
  let showNumber = maxNumber - 1
  return loc("andMoreAddons", {
    addonsList = comma.join(localized.slice(0, showNumber))
    number = total - showNumber
  })
}

let getAddonsSize = @(addons, addonSizesV)
  unique(addons).reduce(@(total, addon) total + (addonSizesV?[addon] ?? 0), 0)

let mbToString = @(mb) "".concat(mb > 0 ? mb : "???", loc("measureUnits/MB"))
let toMB = @(b) (b + (MB / 2)) / MB

let getAddonsSizeInMb = @(addons, addonSizesV) toMB(getAddonsSize(addons, addonSizesV))
let getAddonsSizeStr = @(addons, addonSizesV) mbToString(getAddonsSizeInMb(addons, addonSizesV))

let gameModeAddonToAddonSetMap = {
  [PKG_NAVAL] = commonCampaignAddons?.ships ?? [],
  [PKG_GROUND] = commonCampaignAddons?.tanks ?? [],
  [PKG_LVL_AIR_LOCATIONS] = commonCampaignAddons?.air ?? [],
}

return freeze({
  campaignPostfix
  commonCampaignAddons
  initialAddons
  initialAddonsByCamp
  latestDownloadAddons
  latestDownloadAddonsByCamp
  campaignAddonsByRank
  knownAddons
  soloNewbieByCampaign
  coopNewbieByCampaign

  gameModeAddonToAddonSetMap

  localizeAddons
  localizeAddonsLimited

  MB
  toMB
  mbToString
  getAddonsSizeStr
  getAddonsSize
  getAddonsSizeInMb
  resetAddonNamesCache = @() addonNames.clear()
})