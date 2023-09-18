let { loc, doesLocTextExist } = require("dagor.localize")
let { get_addon_size } = require("contentUpdater")
let { startswith } = require("string")
let { unique } = require("%sqstd/underscore.nut")
let { toIntegerSafe } = require("%sqstd/string.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")

let PKG_NAVAL  = "pkg_naval"
let PKG_NAVAL_HQ = "pkg_naval_hq"
let PKG_GROUND = "pkg_ground"
let PKG_GROUND_HQ = "pkg_ground_hq"
let PKG_COMMON = "pkg_common"
let PKG_COMMON_HQ = "pkg_common_hq"
let PKG_DEV = "pkg_dev"

let MB = 1 << 20
let nbsp = "\u00A0" // Non-breaking space char
let comma = loc("ui/comma")

let naval     = [ PKG_COMMON, PKG_NAVAL, PKG_COMMON_HQ, PKG_NAVAL_HQ ]
let ground    = [ PKG_COMMON, PKG_GROUND, PKG_COMMON_HQ, PKG_GROUND_HQ ]
let dev       = [ PKG_DEV ]
let initialAddons = [ "pkg_secondary_hq", "pkg_secondary" ]
let latestDownloadAddons = { //addons to download after other required campaign addons is already downloaded
  tanks = ["pkg_video"]
}
let commonUhqAddons = ["pkg_environment_uhq"]

let gameModeAddonToAddonSetMap = {
  [PKG_NAVAL] = naval,
  [PKG_GROUND] = ground,
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

let function getAddonNameImpl(addon) {
  local locId = addonLocId?[addon]
  if (locId != null)
    return locId == "" ? "" : loc(locId)
  if (!startswith(addon, "pkg_tier_")) {
    locId = $"addon/{addon}"
    return doesLocTextExist(locId) ? loc(locId) : addon
  }
  let list = addon.split("_")
  let postfixIdx = list.len() - (list.top() == "hq" ? 2 : 1)
  let postfix = list[postfixIdx]
  let tier = toIntegerSafe(list[postfixIdx - 1])
  if (tier <= 0)
    return loc($"addon/{postfix}").replace(" ", nbsp)
  return loc($"addon/{postfix}_tier", { tier = getRomanNumeral(tier) }).replace(" ", nbsp)
}

let addonNames = {}
let function getAddonName(addon) {
  if (addon not in addonNames)
    addonNames[addon] <- getAddonNameImpl(addon)
  return addonNames[addon]
}

let function localizeAddons(addons) {
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

let function localizeAddonsLimited(list, maxNumber) {
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

let function getAddonsSizeStr(addons) {
  let bytes = unique(addons).reduce(@(res, addon) res + get_addon_size(addon), 0)
  let mb = (bytes + (MB / 2)) / MB
  return "".concat(mb > 0 ? mb : "???", loc("measureUnits/MB"))
}

return freeze({
  naval
  ground
  dev
  initialAddons
  commonUhqAddons
  latestDownloadAddons

  gameModeAddonToAddonSetMap

  localizeAddons
  localizeAddonsLimited
  getAddonsSizeStr
})