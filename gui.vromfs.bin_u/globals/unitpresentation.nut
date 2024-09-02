
from "%appGlobals/unitConst.nut" import *

let unitClassFontIcons = {
  boat          = "\u2409"
  heavy_boat    = "\u240A"
  barge         = "\u240B"
  destroyer     = "\u240C"
  frigate       = "\u240C"
  light_cruiser = "\u240E"
  cruiser       = "\u240F"
  heavy_cruiser = "\u240F"
  battlecruiser = "\u2410"
  battleship    = "\u2411"
  submarine     = "\u2412"
  fighter       = "\u25A5"
  bomber        = "\u25A2"
  attacker      = "\u25A3"
}

let unitTypeFontIcons = {
  [AIR] = "▭",
  [TANK] = "▮",
  [SHIP] = "┚",
  [HELICOPTER] = "⋡",
  [BOAT] = "⋛",
}

let unitTypeColors = {
  [AIR]         = 0xFFECBC51, // orange
  [TANK]        = 0xFF99D752, // green
  [SHIP]        = 0xFF00D5E2, // blue
  [HELICOPTER]  = 0xFFECBC51, // orange
  [BOAT]        = 0xFF00D5E2, // blue
}

let defaults = {
  name = ""
  image = ""
  upgradedImage = ""
  locId = ""
  blueprintImage = ""
}


let inProgress = { image = "!ui/unitskin#image_in_progress.avif" } // warning disable: -declared-never-used
let overrides = {
//


















}


let platoonNames = {
  //here overiides for platoon names
  uk_sherman_ic_firefly = "uk_sherman_ic_firefly_platoon"
}

let genParams = {
  image = @(name) $"!ui/unitskin#{name}.avif"
  upgradedImage = @(name) $"!ui/unitskin#{name}_upgraded.avif"
  locId = @(name) $"{name}"
  blueprintImage = @(name) $"ui/unitskin#blueprint_{name}.avif"
}

function mkUnitPresentation(unitName) {
  let res = defaults.__merge(overrides?[unitName] ?? {}, { name = unitName })
  foreach (id, gen in genParams)
    if (res[id] == defaults[id])
      res[id] = gen(unitName)
  return res
}

let cache = {}
function getUnitPresentationByName(unitName) {
  if (unitName not in cache)
    cache[unitName ?? ""] <- mkUnitPresentation(unitName)
  return cache[unitName ?? ""]
}

let getUnitPresentation = @(unitOrName) getUnitPresentationByName(unitOrName?.name ?? unitOrName)
let getUnitLocId = @(u) getUnitPresentation(u).locId
let getPlatoonName = @(unitName, loc) unitName in platoonNames ? loc(platoonNames[unitName])
  : loc("platoon/name", { name = loc(getUnitLocId(unitName)) })

return {
  unitClassFontIcons
  unitTypeFontIcons
  unitTypeColors
  getUnitPresentation
  getUnitLocId
  getUnitClassFontIcon = @(u) unitClassFontIcons?[u?.unitClass] ?? ""
  getPlatoonName
  getPlatoonOrUnitName = @(unit, loc) (unit?.platoonUnits.len() ?? 0) > 0
    ? getPlatoonName(unit?.name ?? "", loc)
    : loc(getUnitLocId(unit?.name ?? ""))
}