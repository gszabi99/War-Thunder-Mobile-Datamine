from "%globalsDarg/darg_library.nut" import *
let { round, round_by_value, lerpClamped } = require("%sqstd/math.nut")
let { getUnitType, getUnitTagsShop } = require("%appGlobals/unitTags.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { applyAttrLevels } = require("%rGui/unitAttr/unitAttrValues.nut")
let { TANK, SHIP, SUBMARINE } = require("%appGlobals/unitConst.nut")
let { get_game_params } = require("gameparams")

let aircraftMark = "▭"
let cannonMark = "⋖"

let goodPenetrationColor = 0xFF64B140
let normalPenetrationColor = 0xFFFFD966
let badPenetrationColor = 0xFFE06666

let armorProtectionPercentageColors = [
  goodPenetrationColor,
  normalPenetrationColor,
  badPenetrationColor
]

let avgShellPenetrationMmByRank = [
  [ 91, 75, 0 ],
  [ 91, 75, 0 ],
  [ 148, 114, 0 ],
]

let valueRangeShip = {
  shipCrewRating = [0.0, 10.0]
  maxSpeed = [7, 43]
  turningTime = [10, 60]
  mainCannonDps = [0, 5000]
  auxCannonDps = [0, 5000]
  aaaDps = [0, 5000]
  torpedoDps = [0, 5000]
  mineDps = [0, 5000]
  bombDps = [0, 5000]
  allCannonsDps = [0, 10000]
}

let valueRangeTank = {
  mainWeaponCaliber = [13, 153]
  armorPower = [30, 800]
  reloadTime = [0, 45]
  gunnerTurretRotationSpeed = [2, 75]
  maxSpeedForward = [0, 110]
  maxSpeedBackward = [0, 110]
  powerToWeightRatio = [0, 50]
}

let valueRange = {
  [SHIP] = valueRangeShip,
  [SUBMARINE] = valueRangeShip,
  [TANK] = valueRangeTank,
}

let allCannons = {
  mainCannon = true
  auxCannon = true
}

let roundCaliber = @(caliber) caliber > 15 ? caliber.tointeger() : caliber //round cannon caliber, but not minigun
let dpsText = @(dps) $"{(dps + 0.5).tointeger()}{loc("measureUnits/damagePerSecond")}"

let function mkGetProgress(unitType, id) {
  let range = valueRange?[unitType][id]
  return range == null ? null
    : @(v) lerpClamped(range[0], range[1], 0.0, 1.0, v)
}

let function mkGetProgressInv(unitType, id) {
  let range = valueRange?[unitType][id]
  return range == null ? null
    : @(v) v == 0 ? 0.0 : (1.0 - lerpClamped(range[0], range[1], 0.0, 1.0, v))
}

let function getArmorPenetrationColor(unit, v) {
  let avgShellPenetration = avgShellPenetrationMmByRank?[unit.mRank - 1] ?? []
  let idxPenetration = avgShellPenetration.findindex(@(p) v > p)
    ?? (armorProtectionPercentageColors.len() - 1)
  return armorProtectionPercentageColors[idxPenetration]
}

let function mkStat(id, cfg, unitType) {
  return {
    id
    isAvailable = @(s) id in s
    getHeader = @(_) loc($"stats/{id}")
    getValue = @(s) s[id]
    valueToText = @(v, _) v.tostring()
    getProgress = mkGetProgress(unitType, id)
    getProgressColor = @(_, __) null
  }.__update(cfg)
}

let statsShip = {
  shipCrewAll = {
    isAvailable = @(s) "shipCrewMax" in s
    getValue = @(s) s?.shipCrewRating ?? 0.0
    valueToText = @(_, s) "shipCrewMin" in s ? $"{s.shipCrewMin}-{s.shipCrewMax}" : s.shipCrewMax.tostring()
    getProgress = mkGetProgress(SHIP, "shipCrewRating")
  }

  shipCrewMax = {
    getValue = @(s) s?.shipCrewRating ?? 0.0
    valueToText = @(_, s) s.shipCrewMax.tostring()
    getProgress = mkGetProgress(SHIP, "shipCrewRating")
  }

  shipCrewMin = { getProgress = null }

  maxSpeed = {
    valueToText = @(v, _) "".concat(round(v * 3.6), loc("measureUnits/kmh"))
  }
  turningTime = {
    getProgress = mkGetProgressInv(SHIP, "turningTime")
    valueToText = @(v, _) "".concat(round_by_value(v, 0.1), loc("measureUnits/seconds"))
  }
  allCannons = {
    isAvailable = @(s) s?.weapons.findvalue(@(w) w?.wtype in allCannons) != null
    getHeader = @(_) loc("stats/allCannons")
    getValue = @(s) (s?.weapons ?? []).reduce(function(res, w) {
        let { wtype = "", shotFreq = 0, damage = 0, gunsCount = 1 } = w
        if (wtype in allCannons)
          res += damage * shotFreq * gunsCount
        return res
      }, 0.0)
    valueToText = @(v, _) dpsText(v)
    getProgress = mkGetProgress(SHIP, "allCannonsDps")
  }
  special = {
    isAfterWeapons = true
    isAvailable = @(_) true
    function getHeader(s) {
      let list = []
      let { weapons = [], supportPlane = "" } = s
      if (weapons.findvalue(@(w) w?.wtype == "aaa"))
        list.append(loc("stats/aaa/short"))
      if (weapons.findvalue(@(w) w?.wtype == "mine"))
        list.append(loc("stats/mine"))
      if (weapons.findvalue(@(w) w?.wtype == "bomb"))
        list.append(loc("stats/bomb"))
      if (supportPlane != "")
        list.append(" ".concat(aircraftMark, loc(getUnitLocId(supportPlane))))
      return ", ".join(list)
    }
    getValue = @(_) null
    valueToText = @(__, _) ""
  }
  supportPlane = {
    isAfterWeapons = true
    getHeader = @(s) " ".concat(aircraftMark, loc(getUnitLocId(s.supportPlane)))
    valueToText = @(_, s) $"x{s?.supportPlaneCount ?? 1}"
  }
}.map(@(cfg, id) mkStat(id, cfg, SHIP))

let statsSubmarine = {
  maxSpeed = {
    valueToText = @(v, _) "".concat(round(v * 3.6 * (get_game_params()?.submarineMaxSpeedMult ?? 1.)),
      loc("measureUnits/kmh"))  }
}.map(@(cfg, id) mkStat(id, cfg, SHIP))

let statsTank = {
  mainWeaponCaliber = {
    getHeader = @(_) " ".concat(cannonMark, loc("stats/mainWeaponCaliber"))
    valueToText = @(v, _) "".concat(v, loc("measureUnits/mm"))
  }
  armorPowerFull = {
    isAvailable = @(s) "armorPower" in s
    getHeader = @(_) " ".concat(
      cannonMark,
      loc("stats/armorPower/full", {
        distance = "".concat("100", loc("measureUnits/meters_alt"))
      }))
    getValue = @(s) s["armorPower"]
    valueToText = @(v, _) "".concat(round(v), loc("measureUnits/mm"))
    getProgress = mkGetProgress(TANK, "armorPower")
    getProgressColor = getArmorPenetrationColor
  }
  maxSpeedForward = {
    valueToText = @(v, _) "".concat(round(v), loc("measureUnits/kmh"))
  }
  maxSpeedBackward = {
    valueToText = @(v, _) "".concat(round(v), loc("measureUnits/kmh"))
  }
  powerToWeightRatio = {
    valueToText = @(v, _) "".concat(round(v), loc("measureUnits/hp_per_ton"))
  }
  mass = {
    valueToText = @(v, _) loc("measureUnits/full/ton", { n = round(v / 1000.0).tointeger() })
  }
  crew = {
    valueToText = @(v, _) v.tostring()
  }
}.map(@(cfg, id) mkStat(id, cfg, TANK))

let statsCfgShip = {
  full = [
    statsShip.shipCrewMax
    statsShip.shipCrewMin
    statsShip.maxSpeed
    statsShip.turningTime
    statsShip.supportPlane
  ]
  short = [
    statsShip.shipCrewAll
    statsShip.maxSpeed
    statsShip.turningTime
    statsShip.allCannons
    statsShip.special
  ]
}

let statsCfgSubmarine = {
  full = [
    statsShip.shipCrewMax
    statsShip.shipCrewMin
    statsSubmarine.maxSpeed
    statsShip.turningTime
    statsShip.supportPlane
  ]
  short = [
    statsShip.shipCrewAll
    statsSubmarine.maxSpeed
    statsShip.turningTime
    statsShip.allCannons
    statsShip.special
  ]
}

let statsCfgTank = {
  full = [
    statsTank.mainWeaponCaliber
    statsTank.armorPowerFull
    statsTank.maxSpeedForward
    statsTank.maxSpeedBackward
    statsTank.powerToWeightRatio
    statsTank.mass
    statsTank.crew
  ]
  short = [
    statsTank.maxSpeedForward
  ]
}

let statsCfg = {
  [SHIP] = statsCfgShip,
  [SUBMARINE] = statsCfgSubmarine,
  [TANK] = statsCfgTank,
}

let mkDamageText = @(dmg, shotFreq) shotFreq <= 0 ? $"{round(dmg)}►"
  : $"{round(dmg)}► {round_by_value(1.0 / shotFreq, shotFreq > 1 ? 0.01 : 0.1)}▩"

let mkGunStat = @(id) {
  id
  isAvailable = @(_) true
  getHeader = @(s) loc($"stats/{id}", { caliber = roundCaliber(s?.caliber ?? 0) })
  getValue = @(s) (s?.damage ?? 0) * (s?.shotFreq ?? 0) * (s?.gunsCount ?? 1)
  valueToText = @(_, s) mkDamageText((s?.damage ?? 0) * (s?.gunsCount ?? 1), s?.shotFreq ?? 0)
  getProgress = mkGetProgress(SHIP, $"{id}Dps")
  getProgressColor = @(_, __) null
}

let mkWeapStat = @(id, override = {}) {
  id
  isAvailable = @(_) true
  getHeader = @(s) loc($"stats/{id}", { caliber = roundCaliber(s?.caliber ?? 0) })
  getValue = @(s) (s?.damage ?? 0) * (s?.shotFreq ?? 0)
  valueToText = @(_, s) mkDamageText(s?.damage ?? 0, s?.shotFreq ?? 0)
  getProgress = mkGetProgress(SHIP, $"{id}Dps")
  getProgressColor = @(_, __) null
}.__update(override)

let weaponsCfgShip = {
  full = [
    mkGunStat("mainCannon")
    mkGunStat("auxCannon")
    mkGunStat("aaa")
    mkWeapStat("torpedo")
    mkWeapStat("mine")
    mkWeapStat("bomb")
  ]
  short = [
    mkWeapStat("torpedo", { valueToText = @(_, s) dpsText((s?.damage ?? 0) * (s?.shotFreq ?? 0)) })
  ]
}

let weaponsCfgTank = {
  full = [
    {
      id = "armorPower"
      getHeader = @(_) " ".concat(cannonMark, loc("stats/armorPower"))
      valueToText = @(v, _) "".concat(round(v), loc("measureUnits/mm"))
      getProgressColor = @(_, __) null
      getValue = @(wCfg) wCfg.armorPower
      getProgress = mkGetProgress(TANK, "armorPower")
      isAvailable = @(_) true
    }
    {
      id = "reloadTime"
      getProgress = mkGetProgressInv(TANK, "reloadTime")
      getHeader = @(_) loc("stats/reloadTime")
      valueToText = @(v, _) "".concat(round_by_value(v, 0.1), loc("measureUnits/seconds"))
      getValue = @(wCfg) wCfg.reloadTime
      getProgressColor = @(_, __) null
      isAvailable = @(_) true
    }
    {
      id = "gunnerTurretRotationSpeed"
      getProgress = mkGetProgressInv(TANK, "gunnerTurretRotationSpeed")
      getHeader = @(_) loc("stats/gunnerTurretRotationSpeed")
      valueToText = @(v, _) "".concat(round(v), loc("measureUnits/deg_per_sec"))
      getValue = @(wCfg) wCfg.gunnerTurretRotationSpeed
      getProgressColor = @(_, __) null
      isAvailable = @(_) true
    }
  ]
  short = [
    {
      id = "armorPower"
      getHeader = @(_) " ".concat(cannonMark, loc("stats/armorPower"))
      valueToText = @(v, _) "".concat(round(v), loc("measureUnits/mm"))
      getProgressColor = @(_, __) null
      getValue = @(wCfg) wCfg.armorPower
      getProgress = mkGetProgress(TANK, "armorPower")
      isAvailable = @(_) true
    }
  ]
}

let weaponsCfg = {
  [SHIP] = weaponsCfgShip,
  [SUBMARINE] = weaponsCfgShip,
  [TANK] = weaponsCfgTank
}

let function mkUnitStat(unit, stat, shopCfg, uid) {
  if (!stat.isAvailable(shopCfg))
    return null
  let header = stat.getHeader(shopCfg)
  if (header == "")
    return null
  let value = stat.getValue(shopCfg)
  return {
    uid //for compare
    header
    value = stat.valueToText(value, shopCfg)
    progress = stat.getProgress?(value)
    progressColor = stat.getProgressColor(unit, value)
  }
}

let function getUnitStats(unit, shopCfg, statsList, weapStatsList) {
  if (shopCfg == null)
    return []
  let unitStats = statsList.map(@(stat) mkUnitStat(unit, stat, shopCfg, stat.id))
  let weapByType = (shopCfg?.weapons ?? {}).reduce(function(res, wCfg) {
    let { wtype = "null" } = wCfg
    res[wtype] <- (res?[wtype] ?? []).append(wCfg)
    return res
  }, {})

  local weaponsIdx = statsList.findindex(@(stat) stat?.isAfterWeapons ?? false)
  foreach (stat in weapStatsList) {
    let list = unit.unitType == "tank"
      ? weapByType?[shopCfg?.mainWeaponType ?? "mainCannon"]
      : weapByType?[stat.id]
    if (list == null)
      continue
    if (unit.unitType != "tank")
      list.sort(@(a, b) a.damage < b.damage)
    foreach (i, wCfg in list) {
      let s = mkUnitStat(unit, stat, wCfg, $"{stat.id}{i}")
      if (weaponsIdx == null)
        unitStats.append(s)
      else
        unitStats.insert(weaponsIdx++, s)
    }
  }
  return unitStats.filter(@(v) v != null)
}

let function mkUnitStatsCompFull(unit, attrLevels, attrPreset, mods) {
  let unitType = unit.unitClass == "submarine" ? "submarine" : unit.unitType
  let stats = applyAttrLevels(unitType, getUnitTagsShop(unit.name), attrLevels, attrPreset, mods)
  return getUnitStats(unit, stats, statsCfg?[unitType].full ?? [], weaponsCfg?[unitType].full ?? [])
}

let function mkUnitStatsCompShort(unit, attrLevels, attrPreset, mods) {
  let unitType = unit.unitClass == "submarine" ? "submarine" : unit.unitType
  let stats = applyAttrLevels(unitType, getUnitTagsShop(unit.name), attrLevels, attrPreset, mods)
  return getUnitStats(unit, stats, statsCfg?[unitType].short ?? [], weaponsCfg?[unitType].short ?? [])
}

let function appendStatValue(res, stat, shopCfg) {
  if (!stat.isAvailable(shopCfg))
    return null
  let value = stat.getValue(shopCfg)
  if (type(value) != "integer" && type(value) != "float")
    return null
  res[stat.id] <- (res?[stat.id] ?? []).append(value)
  return value
}

let mkRange = @(values) [
  values.reduce(@(a, b) min(a, b))
  values.reduce(@(a, b) max(a, b))
]

let function gatherUnitStatsLimits(unitsList) {
  let values = {}
  foreach (unitName in unitsList) {
    let unitType = getUnitType(unitName)
    let shopCfg = getUnitTagsShop(unitName)
    statsCfg?[unitType].full.each(@(stat) appendStatValue(values, stat, shopCfg))

    let weapByType = (shopCfg?.weapons ?? {}).reduce(function(res, wCfg) {
      let { wtype = "null" } = wCfg
      res[wtype] <- (res?[wtype] ?? []).append(wCfg)
      return res
    }, {})
    local allCannonsDps = 0.0
    foreach (stat in (weaponsCfg?[unitType].full ?? []))
      weapByType?[stat.id].each(function(wCfg) {
        let v = appendStatValue(values, stat, wCfg)
        if (v != null && stat.id in allCannons)
          allCannonsDps += v
      })
    values.allCannons <- (values?.allCannons ?? []).append(allCannonsDps)
  }

  return values.map(mkRange)
}

return {
  mkUnitStatsCompFull
  mkUnitStatsCompShort
  gatherUnitStatsLimits
  armorProtectionPercentageColors
  avgShellPenetrationMmByRank
}
