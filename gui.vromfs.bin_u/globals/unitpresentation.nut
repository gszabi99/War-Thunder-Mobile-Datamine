from "%appGlobals/unitConst.nut" import *
let getTagsUnitName = require("getTagsUnitName.nut")

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
  assault       = "\u25A3"
  light_tank    = "\u252A"
  medium_tank   = "\u252C"
  heavy_tank    = "\u2528"
  SPAA          = "\u2530"
  tank_destroyer = "\u2534"
}

let unitTypeFontIcons = {
  [AIR] = "▭",
  [TANK] = "▮",
  [SHIP] = "┚",
  [HELICOPTER] = "⋡",
  [BOAT] = "⋛",
}

let unitTypeColors = {
  [AIR]         = 0xFFECBC51, 
  [TANK]        = 0xFF99D752, 
  [SHIP]        = 0xFF7FAEFF, 
  [HELICOPTER]  = 0xFFECBC51, 
  [BOAT]        = 0xFF7FAEFF, 
}

let defaults = {
  name = ""
  image = ""
  upgradedImage = ""
  locId = ""
  blueprintImage = ""
}


let inProgress = { image = "!ui/unitskin#image_in_progress.avif" } 
let overrides = {

  ["sb2c_1c_killstreak"] = { image = "!ui/unitskin#sb2c_1c.avif" },
  ["il_2m_1943_killstreak"] = { image = "!ui/unitskin#il_2_1941.avif" },
  ["ju_87d_5_killstreak"] = { image = "!ui/unitskin#ju_87d_5.avif" },
  ["do_17z_2_killstreak"] = { image = "!ui/unitskin#do_17z_2.avif" },
  ["p_40e_killstreak"] = { image = "!ui/unitskin#p_40e.avif" },
  ["yak_9_killstreak"] = { image = "!ui/unitskin#yak_9.avif" },
  ["fw_190a_1_killstreak"] = { image = "!ui/unitskin#fw_190a_1.avif" },
  ["la-5_killstreak"] = { image = "!ui/unitskin#la-5fn.avif" },
  ["he_111h_6_killstreak"] = { image = "!ui/unitskin#he_111h_6.avif" },
  ["il_4_killstreak"] = { image = "!ui/unitskin#il_4.avif" },
  ["firefly_mk5_killstreak"] = { image = "!ui/unitskin#firefly_mk5.avif" },
  ["b_25j_20_killstreak"] = { image = "!ui/unitskin#b_25j_20.avif" },
  ["f4u_4_killstreak"] = { image = "!ui/unitskin#f4u_4.avif" },
  ["seafire_mk3_killstreak"] = { image = "!ui/unitskin#seafire_mk3.avif" },
  ["a6m5_zero_killstreak"] = { image = "!ui/unitskin#a6m5_zero.avif" },
  ["bf-109f-4_killstreak"] = { image = "!ui/unitskin#bf-109f-4.avif" },
  ["sb2c_4_killstreak"] = { image = "!ui/unitskin#sb2c_4.avif" },
  ["er-2_m105_mv3_killstreak"] = { image = "!ui/unitskin#er-2_m105_mv3.avif" },
  ["he-111h-16_winter_killstreak"] = { image = "!ui/unitskin#he-111h-16_winter.avif" },
  ["b_26b_c_killstreak"] = { image = "!ui/unitskin#b_26b_c.avif" },
  ["f4u-4b_killstreak"] = { image = "!ui/unitskin#f4u-4b.avif" },
  ["fw-190a-5_cannons_killstreak"] = { image = "!ui/unitskin#fw-190a-5_cannons.avif" },
  ["la-11_killstreak"] = { image = "!ui/unitskin#la-11.avif" },
  ["bf-109g-2_killstreak"] = { image = "!ui/unitskin#bf-109g-2.avif" },
  ["p_47n_15_killstreak"] = { image = "!ui/unitskin#p_47n_15.avif" },
  ["wyvern_s4_killstreak"] = { image = "!ui/unitskin#wyvern_s4.avif" },
  ["do_335a_1_killstreak"] = { image = "!ui/unitskin#do_335a_1.avif" },
  ["douglas_ad_2_killstreak"] = { image = "!ui/unitskin#douglas_ad_2.avif" },
  ["f8f1_killstreak"] = { image = "!ui/unitskin#f8f1.avif" },
  ["bf_109k_4_killstreak"] = { image = "!ui/unitskin#bf_109k_4.avif" },
  ["la_9_killstreak"] = { image = "!ui/unitskin#la_9.avif" },
  ["fw-190d-9_killstreak"] = { image = "!ui/unitskin#fw-190d-9.avif" },

















}


let platoonNames = {
  
  uk_sherman_ic_firefly = "uk_sherman_ic_firefly_platoon"
}

let genParams = {
  image = @(name) $"!ui/unitskin#{name}.avif"
  upgradedImage = @(name) $"!ui/unitskin#{name}_upgraded.avif"
  locId = @(name) $"{name}"
  blueprintImage = @(name) $"ui/unitskin#blueprint_{name}.avif"
}

function mkUnitPresentation(realUnitName) {
  let unitName = getTagsUnitName(realUnitName)
  let res = defaults.__merge(overrides?[unitName] ?? {}, { name = unitName, realUnitName })
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
let getUnitName = @(u, loc) loc(getUnitLocId(u))
let getPlatoonName = @(unitName, loc) unitName in platoonNames ? loc(platoonNames[unitName])
  : loc("platoon/name", { name = loc(getUnitLocId(unitName)) })

return {
  unitClassFontIcons
  unitTypeFontIcons
  unitTypeColors
  getUnitPresentation
  getUnitLocId
  getUnitClassFontIcon = @(u) unitClassFontIcons?[u?.unitClass] ?? ""
  getUnitName
  getPlatoonName
  getPlatoonOrUnitName = @(unit, loc) (unit?.platoonUnits.len() ?? 0) > 0
    ? getPlatoonName(unit?.name ?? "", loc)
    : getUnitName(unit?.name ?? "", loc)
}