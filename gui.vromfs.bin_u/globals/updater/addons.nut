let { loc, doesLocTextExist } = require("dagor.localize")
let { get_settings_blk } = require("blkGetters")
let { logerr } = require("dagor.debug")
let { eachBlock } = require("%sqstd/datablock.nut")
let { get_addons_size } = require("contentUpdater")
let { startswith, endswith } = require("string")
let { unique } = require("%sqstd/underscore.nut")
let { toIntegerSafe } = require("%sqstd/string.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")

let PKG_NAVAL  = "pkg_naval"
let PKG_NAVAL_HQ = "pkg_naval_hq"
let PKG_GROUND = "pkg_ground"
let PKG_GROUND_HQ = "pkg_ground_hq"
let PKG_LVL_AIR_LOCATIONS = "pkg_lvl_air_locations"
let PKG_COMMON = "pkg_common"
let PKG_COMMON_HQ = "pkg_common_hq"
let PKG_DEV = "pkg_dev"

let ADDON_VERSION_EMPTY = ""

let MB = 1 << 20
let nbsp = "\u00A0" // Non-breaking space char
let comma = loc("ui/comma")

let commonAddonsByPostfix = {
  naval     = [ PKG_COMMON, PKG_NAVAL, PKG_COMMON_HQ, PKG_NAVAL_HQ ],
  ground    = [ PKG_COMMON, PKG_GROUND, PKG_COMMON_HQ, PKG_GROUND_HQ ],
  aircraft  = [ PKG_COMMON, PKG_COMMON_HQ ],
}
let dev       = [ PKG_DEV ]
let initialAddons = [ "pkg_secondary_hq", "pkg_secondary" ]
let latestDownloadAddonsByCamp = { //addons to download after other required campaign addons is already downloaded
  tanks = ["pkg_video"]
}
let latestDownloadAddons = []
let commonUhqAddons = ["pkg_environment_uhq"]
let ovrHangarAddon = {addons = [], hangarPath=""}//{ addons : array<string>, hangarPath : string }

let gameModeAddonToAddonSetMap = {
  [PKG_NAVAL] = commonAddonsByPostfix.naval,
  [PKG_GROUND] = commonAddonsByPostfix.ground,
  [PKG_LVL_AIR_LOCATIONS] = commonAddonsByPostfix.aircraft,
}

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
let extAddonsByRank = {}
let soloNewbieByCampaign = {}
let setBlk = get_settings_blk()
let addonsBlk = setBlk?.addons
if (addonsBlk != null)
  eachBlock(addonsBlk, function(b) {
    let addon = b.getBlockName()
    let addonHq = $"{addon}_hq"
    let addonUhq = $"{addon}_uhq"

    knownAddons[addon] <- true

    let { hq = true, uhq = false } = b
    if (hq)
      knownAddons[addonHq] <- true
    if (uhq)
      knownAddons[addonUhq] <- true

    let { hangarPath = "" } = b
    if (hangarPath != "") {
      ovrHangarAddon.clear()
      ovrHangarAddon.__update({ addons = [addon], hangarPath })
      latestDownloadAddons.append(addon)
      if (hq) {
        latestDownloadAddons.append(addonHq)
        ovrHangarAddon.addons.append(addonHq)
      }
    }

    let conditions = b.getBlockByName("conditions")
    if (conditions != null) {
      local isProcessed = false
      foreach(camp in conditions % "soloNewbie") {
        isProcessed = true
        if (camp not in soloNewbieByCampaign)
          soloNewbieByCampaign[camp] <- []
        soloNewbieByCampaign[camp].append(addon)
        if (hq)
          soloNewbieByCampaign[camp].append(addonHq)
      }

      let { campaign = null, mRank = null } = conditions
      if (type(campaign) != "string" || type(mRank) != "integer") {
        if (!isProcessed)
          logerr($"Invalid type of required field in addon/conditions for '{addon}': campaign = {campaign}, mRank = {mRank}")
        return
      }
      if (campaign not in extAddonsByRank)
        extAddonsByRank[campaign] <- {}
      if (mRank not in extAddonsByRank[campaign])
        extAddonsByRank[campaign][mRank] <- []
      extAddonsByRank[campaign][mRank].append(addon)

      if (hq)
        extAddonsByRank[campaign][mRank].append(addonHq)

      if (campaign in campaignPostfix && !doesLocTextExist($"addon/{addon}")) {
        let cfg = { locId = $"addon/{campaignPostfix[campaign]}_tier", mRank }
        addonLocIdWithMRank[addon] <- cfg
        addonLocIdWithMRank[addonHq] <- cfg
      }
    }
  })


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

function getAddonsSizeStr(addons) {
  let bytes = get_addons_size(unique(addons))
  let mb = (bytes + (MB / 2)) / MB
  return "".concat(mb > 0 ? mb : "???", loc("measureUnits/MB"))
}

return freeze({
  campaignPostfix
  commonAddonsByPostfix
  dev
  initialAddons
  commonUhqAddons
  latestDownloadAddons
  latestDownloadAddonsByCamp
  extAddonsByRank
  knownAddons
  ovrHangarAddon
  soloNewbieByCampaign

  gameModeAddonToAddonSetMap

  localizeAddons
  localizeAddonsLimited
  getAddonsSizeStr
  resetAddonNamesCache = @() addonNames.clear()

  ADDON_VERSION_EMPTY
})