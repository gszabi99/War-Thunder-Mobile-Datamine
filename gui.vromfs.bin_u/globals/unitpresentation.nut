
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
  locIdFull = ""
}

let inProgress = { image = "!ui/unitskin#image_in_progress.avif" }
let overrides = {
  //here all overrides by unit
  us_m3a3_bradley_reskin = inProgress
  germ_flakpz_I_Gepard_reskin = inProgress
  jp_type_87_reskin = inProgress
  sw_veak_40_reskin = inProgress
  us_mbt_70 = inProgress
  us_m60a1_rise_passive_era = inProgress
  us_m3a3_bradley = inProgress
  us_m60a3_tts = inProgress
  us_xm_8 = inProgress
  us_xm_803 = inProgress
  germ_leopard_1a5 = inProgress
  germ_kpz_70 = inProgress
  germ_thyssen_henschel_tam = inProgress
  germ_mkpz_super_m48 = inProgress
  germ_th_800_bismark = inProgress
  germ_begleitpanzer_57 = inProgress
  germ_leopard_c2_mexas = inProgress
  ussr_t_64a_1971 = inProgress
  ussr_t_72a = inProgress
  ussr_bmp_2 = inProgress
  ussr_9p149 = inProgress
  ussr_t_62m1 = inProgress
  ussr_t_55_amd_1 = inProgress
  ussr_bmd_4 = inProgress
  ussr_object_279 = inProgress
  uk_chieftain_mk_10 = inProgress
  uk_olifant_mk_2 = inProgress
  uk_ratel_zt3 = inProgress
  uk_rooikat_za_35 = inProgress
  jp_type_74_mod_g_kai = inProgress
  jp_type_74_f = inProgress
  jp_type_89 = inProgress
  sw_strv_105 = inProgress
  sw_strf_90b = inProgress
  sw_cv_90105_tml = inProgress
  uk_ac4_thunderbolt = inProgress
  us_halftrack_m16_reskin = inProgress
  uk_bosvark_test = inProgress
  ussr_t_34_1940_l_11_test = inProgress
  germ_pzkpfw_IV_ausf_F2_test = inProgress
  us_m4a1_1942_sherman_test = inProgress
  us_m42_duster_test = inProgress
}

let platoonNames = {
  //here overiides for platoon names
  uk_sherman_ic_firefly = "uk_sherman_ic_firefly_platoon"
}

let genParams = {
  image = @(name) $"!ui/unitskin#{name}.avif"
  upgradedImage = @(name) $"!ui/unitskin#{name}_upgraded.avif"
  locId = @(name) $"{name}_shop"
  locIdFull = @(name) $"{name}_0"
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
  getUnitLocIdFull = @(u) getUnitPresentation(u).locIdFull
  getUnitClassFontIcon = @(u) unitClassFontIcons?[u?.unitClass] ?? ""
  getPlatoonName
  getPlatoonOrUnitName = @(unit, loc) (unit?.platoonUnits.len() ?? 0) > 0 ? getPlatoonName(unit.name, loc) : loc(getUnitLocId(unit.name))
}