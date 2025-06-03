from "%globalsDarg/darg_library.nut" import *
let { get_game_params_blk } = require("blkGetters")
let { get_option_torpedo_dive_depth_auto, get_option_torpedo_dive_depth } = require("weaponryOptions")
let { round, round_by_value } = require("%sqstd/math.nut")
let { blkOptFromPath, eachBlock } = require("%sqstd/datablock.nut")
let { appendOnce } = require("%sqStdLibs/helpers/u.nut")
let { compareWeaponFunc } = require("%globalScripts/modeXrayLib.nut")
let { SHIP, BOAT } = require("%appGlobals/unitConst.nut")
let { getUnitAttrValRaw } = require("%rGui/dmViewer/modeXrayAttr.nut")

let CANNON_CALIBER_MIN = 15
let isCaliberCannon = @(v) v >= CANNON_CALIBER_MIN

local torpedoSpeedMult = null
function getTorpedoSpeedMult() {
  if (torpedoSpeedMult == null) {
    let blk = get_game_params_blk()
    let realGunnery = (blk?.difficulty_presets.arcade.realGunnery ?? 1) == 1 ? "on" : "off"
    torpedoSpeedMult = blk?.difficulty_settings.realGunnery[realGunnery].torpedoSpeedMultFromDist.x ?? 1.0
  }
  return torpedoSpeedMult
}

let collectWeapons = @(weaponsArr, blk)
  eachBlock(blk, @(weapon) (weapon?.blk != null && !weapon?.dummy)
    ? appendOnce(weapon, weaponsArr, false, compareWeaponFunc)
    : null)

function getCommonWeapons(unitBlk, _primaryMod) {
  let res = []
  collectWeapons(res, unitBlk?.commonWeapons)
  return res
}

function getUnitWeaponsList(commonData) {
  let { unitDataCache } = commonData
  if ("weaponBlkList" not in unitDataCache) {
    let { unitBlk } = commonData
    let weaponBlkList = []
    if (unitBlk != null) {
      collectWeapons(weaponBlkList, unitBlk?.commonWeapons)
      eachBlock(unitBlk?.WeaponSlots, @(wSlot) collectWeapons(weaponBlkList, wSlot?.WeaponPreset))
      eachBlock(unitBlk?.modifications, @(mod) collectWeapons(weaponBlkList, mod?.effects.commonWeaponss))
    }
    unitDataCache.weaponBlkList <- weaponBlkList
  }
  return unitDataCache.weaponBlkList
}

function getWeaponNameByBlkPath(weaponBlkPath) {
  let fn = weaponBlkPath.split("/").top()
  return fn.endswith(".blk") ? fn.slice(0, -4) : fn
}

let toStr_speed = @(v) " ".concat(round(v * 3.6), loc("measureUnits/kmh"))
let toStr_horsePowers = @(v) " ".concat(round(v), loc("measureUnits/hp"))
let toStr_thrustKgf = @(v) " ".concat(round(v / 10.0) * 10, loc("measureUnits/kgf"))
let toStr_distance = @(v) " ".concat(round_by_value(v / 1000.0, 0.1), loc("measureUnits/km_dist"))
let toStr_massKg = @(v) " ".concat(round_by_value(v, 0.1), loc("measureUnits/kg"))
let toStr_massLbs = @(v) " ".concat(round_by_value(v, 0.1), loc("measureUnits/lbs"))
let toStr_depth = @(v) " ".concat(round_by_value(v, 0.1), loc("measureUnits/meters_alt"))


function getWeaponDescTextByWeaponInfoBlk(commonData, weaponInfoBlk) {
  let res = []
  let weaponBlk = blkOptFromPath(weaponInfoBlk?.blk)
  let weapon = weaponBlk?.torpedo
  if (weapon == null)
    return res

  
  let massKg = weapon?.mass ??  weapon?.massKg ?? 0.0
  let massLbs = weapon?.mass_lbs ?? weapon?.massLbs ?? 0.0
  let massKgTxt = massKg > 0 ? toStr_massKg(massKg) : null
  let massLbsTxt = massLbs > 0 ? toStr_massLbs(massLbs) : null
  let massLbsAndKgTxt = massLbsTxt && massKgTxt
    ? "".concat(massLbsTxt, loc("ui/parentheses/space", { text = massKgTxt })) : null
  let massTxt = massLbsAndKgTxt ?? massKgTxt ?? massLbsTxt
  if (massTxt != null)
    res.append("".concat(loc("bullet_properties/Mass"), colon, massTxt))

  
  if (weapon?.bulletType == "torpedo") {
    if (weapon?.maxSpeedInWater)
      res.append("".concat(loc("torpedo/maxSpeedInWater"), colon,
        toStr_speed(weapon.maxSpeedInWater * getTorpedoSpeedMult())))
    if (weapon?.distToLive) {
      let val = getUnitAttrValRaw(commonData, "ship_damage_control", "attrib_torpedo_distance")
        ?? weapon.distToLive
      res.append("".concat(loc("torpedo/distanceToLive"), colon, toStr_distance(val)))
    }
    if (weapon?.diveDepth) {
      let diveDepth = [ SHIP, BOAT ].contains(commonData.unit.unitType) && !get_option_torpedo_dive_depth_auto()
          ? get_option_torpedo_dive_depth()
          : weapon.diveDepth
      res.append("".concat(loc("bullet_properties/diveDepth"), colon, toStr_depth(diveDepth)))
    }
    if (weapon?.armDistance)
      res.append("".concat(loc("torpedo/armingDistance"), colon, toStr_depth(weapon.armDistance)))
  }

  
  if (weapon?.explosiveType) {
    res.append("".concat(loc("bullet_properties/explosiveType"), colon, loc($"explosiveType/{weapon.explosiveType}")))
    if (weapon?.explosiveMass)
      res.append("".concat(loc("bullet_properties/explosiveMass"), colon, toStr_massKg(weapon.explosiveMass)))
  }

  return "".concat("\n", "\n".join(res))
}

return {
  getCommonWeapons
  getUnitWeaponsList
  getWeaponNameByBlkPath
  getWeaponDescTextByWeaponInfoBlk
  isCaliberCannon
  toStr_speed
  toStr_horsePowers
  toStr_thrustKgf
  toStr_distance
}
