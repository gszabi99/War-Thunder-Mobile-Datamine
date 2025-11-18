from "%globalsDarg/darg_library.nut" import *
let { round, round_by_value, lerpClamped } = require("%sqstd/math.nut")
let { getUnitType, getUnitTagsShop } = require("%appGlobals/unitTags.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { applyAttrLevels } = require("%rGui/attributes/attrValues.nut")
let { TANK, SHIP, SUBMARINE, AIR } = require("%appGlobals/unitConst.nut")
let { attrPresets } = require("%rGui/attributes/attrState.nut")
let { loadUnitWeaponSlots } = require("%rGui/weaponry/loadUnitBullets.nut")
let { getWeaponShortNameWithCount, getWeaponTypeName } = require("%rGui/weaponry/weaponsVisual.nut")
let { getSpeedText } = require("%rGui/measureUnits.nut")
let { format } = require("string")

let aircraftMark = "▭"
let cannonMark = "⋖"

let goodPenetrationColor = 0xFF64B140
let normalPenetrationColor = 0xFFFFD966
let badPenetrationColor = 0xFFE06666
let addedFromSlot = 0xFF65BC82

let MAX_ATTR_VALUE = 5

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
  maxSpeed = [4, 23] 
  surfaceSpeed = [4, 23] 
  periscopeSpeed = [4, 23] 
  turningTime = [10, 60]
  asmCaptureDuration = [2.2, 10]
  mainCannonDps = [0, 5000]
  auxCannonDps = [0, 5000]
  aaaDps = [0, 5000]
  rocketsDps = [0, 6750]
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
  maxSpeedForward = [0, 31] 
  maxSpeedBackward = [0, 31] 
  powerToWeightRatio = [0, 50]
}

let valueRangeAir = {
  maxSpeed = [66, 706] 
}

let valueRange = {
  [SHIP] = valueRangeShip,
  [SUBMARINE] = valueRangeShip,
  [TANK] = valueRangeTank,
  [AIR] = valueRangeAir,
}

let allCannons = {
  mainCannon = true
  auxCannon = true
}

let roundCaliber = @(caliber) caliber > 15 ? caliber.tointeger() : caliber 
let dpsText = @(dps) $"{(dps + 0.5).tointeger()}{loc("measureUnits/damagePerSecond")}"

function mkGetProgress(unitType, id) {
  let range = valueRange?[unitType][id]
  return range == null ? null
    : @(v) lerpClamped(range[0], range[1], 0.0, 1.0, v)
}

function mkGetProgressInv(unitType, id) {
  let range = valueRange?[unitType][id]
  return range == null ? null
    : @(v) v == 0 ? 0.0 : (1.0 - lerpClamped(range[0], range[1], 0.0, 1.0, v))
}

function getArmorPenetrationColor(unit, v) {
  let avgShellPenetration = avgShellPenetrationMmByRank?[unit.mRank - 1] ?? []
  let idxPenetration = avgShellPenetration.findindex(@(p) v > p)
    ?? (armorProtectionPercentageColors.len() - 1)
  return armorProtectionPercentageColors[idxPenetration]
}

function mkStat(id, cfg, unitType) {
  return {
    id
    secondaryId = null
    isAvailable = @(s) id in s
    isAfterWeapons = false
    getHeader = @(_, __) loc($"stats/{id}")
    getValue = @(s) s?[id]
    getProgress = mkGetProgress(unitType, id)
    getProgressColor = @(_, __) null
    getListTitle = @() null
    hasSeveralValueRows = false
    getRowListHeader = @(v) v
    getRowListValue = @(_) null
    valueToText = @(v, _) v?.tostring()
    valueToTextAttr = @(v, _) v?.tostring()
  }.__update(cfg)
}

let statsShip = {
  shipCrewAll = {
    isAvailable = @(s) "shipCrewMax" in s
    getValue = @(s) s?.shipCrewRating ?? 0.0
    valueToText = @(_, s) "shipCrewMin" not in s ? round(s.shipCrewMax).tostring()
      : $"{round(s.shipCrewMin)}-{round(s.shipCrewMax)}"
    getProgress = mkGetProgress(SHIP, "shipCrewRating")
  }

  shipCrewMax = {
    getValue = @(s) s?.shipCrewRating ?? 0.0
    valueToText = @(_, s) round(s.shipCrewMax).tostring()
    getProgress = mkGetProgress(SHIP, "shipCrewRating")
  }

  shipCrewMin = {
    valueToText = @(_, s) round(s.shipCrewMin).tostring()
    getProgress = null
  }

  maxSpeed = { valueToText = @(v, _) getSpeedText(v) }
  surfaceSpeed = { valueToText = @(v, _) getSpeedText(v) }
  periscopeSpeed = { valueToText = @(v, _) getSpeedText(v) }
  turningTime = {
    getProgress = mkGetProgressInv(SHIP, "turningTime")
    valueToText = @(v, _) "".concat(round_by_value(v, 0.1), loc("measureUnits/seconds"))
  }
  asmCaptureDuration = {
    getProgress = mkGetProgressInv(SHIP, "asmCaptureDuration")
    valueToText = @(v, _) "".concat(round_by_value(v, 0.1), loc("measureUnits/seconds"))
  }
  allCannons = {
    isAvailable = @(s) s?.weapons.findvalue(@(w) w?.wtype in allCannons) != null
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
    function getHeader(s, _) {
      let list = []
      let { weapons = [], supportPlane = "", ecmType = "" } = s
      if (weapons.findvalue(@(w) w?.wtype == "aaa"))
        list.append(loc("stats/aaa/short"))
      if (weapons.findvalue(@(w) w?.wtype == "mine"))
        list.append(loc("stats/mine"))
      if (weapons.findvalue(@(w) w?.wtype == "bomb"))
        list.append(loc("stats/bomb"))
      if (weapons.findvalue(@(w) w?.wtype == "rockets" && w?.antiSubRocket))
        list.append(loc("stats/asm/short"))
      if (ecmType != "")
        list.append(loc($"stats/{ecmType}/short"))
      if (supportPlane != "")
        list.append(" ".concat(aircraftMark, loc(getUnitLocId(supportPlane))))
      return ", ".join(list)
    }
    getValue = @(_) null
    valueToText = @(__, _) ""
  }
  supportPlane = {
    isAfterWeapons = true
    getHeader = @(s, _) " ".concat(aircraftMark, loc(getUnitLocId(s.supportPlane)))
    valueToText = @(_, s) $"x{s?.supportPlaneCount ?? 1}"
  }

  ecmDuration = {
    isAfterWeapons = true
    getHeader = @(s, _) loc($"stats/{s?.ecmType ?? ""}")
    valueToText = @(v, _) "".concat(round_by_value(v, 0.1), loc("measureUnits/seconds"))
  }
}.map(@(cfg, id) mkStat(id, cfg, SHIP))

let statsTank = {
  mainWeaponCaliber = {
    getHeader = @(_, __) " ".concat(cannonMark, loc("stats/mainWeaponCaliber"))
    valueToText = @(v, _) "".concat(v, loc("measureUnits/mm"))
  }
  armorPowerFull = {
    isAvailable = @(s) "armorPower" in s
    getHeader = @(_, __) " ".concat(
      cannonMark,
      loc("stats/armorPower/full", {
        distance = "".concat("100", loc("measureUnits/meters_alt"))
      }))
    getValue = @(s) s["armorPower"]
    valueToText = @(v, _) "".concat(round(v), loc("measureUnits/mm"))
    getProgress = mkGetProgress(TANK, "armorPower")
    getProgressColor = getArmorPenetrationColor
  }
  maxSpeedForward = { valueToText = @(v, _) getSpeedText(v) }
  maxSpeedBackward = { valueToText = @(v, _) getSpeedText(v) }
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

let statsAir = {
  pylonCount = {
    valueToText = @(v, _) v.tostring()
    isAfterWeapons = true
  }
  crew = {
    getHeader = @(__, _) loc("attrib_section/plane_crew")
    valueToText = @(_, s) (s?.gunnersCount ?? 0) != 0
      ? loc("stats/air_crew", { pilots = s?.pilotsCount ?? 0, gunners = s?.gunnersCount ?? 0 })
      : loc("stats/air_crew_pilots", { pilots = s?.pilotsCount ?? 0 })
    isAvailable = @(s) (s?.pilotsCount ?? 0) + (s?.gunnersCount ?? 0) > 0
  }
  massPerSec = {
    valueToText = @(v, _) "".concat(round_by_value(v, 0.1), loc("measureUnits/kgPerSec"))
    isAfterWeapons = true
  }
  maxSpeed = {
    valueToText = @(v, _) getSpeedText(v)
  }
  maxSpeedAlt = {
    valueToText = @(v, _) "".concat(round(v), loc("measureUnits/meters_alt"))
  }
  maxAltitude = {
    valueToText = @(v, _) "".concat(round(v), loc("measureUnits/meters_alt"))
  }
  turnTime = {
    valueToText = @(v, _) "".concat(round(v), loc("measureUnits/seconds"))
  }
  climbSpeed = {
    valueToText = @(v, _) "".concat(round(v), loc("measureUnits/metersPerSecond_climbSpeed"))
  }
  wingLoading = {
    valueToText = @(v, _) "".concat(round(v), loc("measureUnits/kg_per_sq_meters_wing_loading"))
  }
}.map(@(cfg, id) mkStat(id, cfg, AIR))

let statsCfgShip = {
  full = [
    statsShip.shipCrewMax
    statsShip.shipCrewMin
    statsShip.surfaceSpeed
    statsShip.periscopeSpeed
    statsShip.maxSpeed
    statsShip.turningTime
    statsShip.asmCaptureDuration
    statsShip.supportPlane
    statsShip.ecmDuration
  ]
  short = [
    statsShip.shipCrewAll
    statsShip.maxSpeed
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

let statsCfgAir = {
  full = [
    statsAir.pylonCount
    statsAir.crew
    statsAir.maxSpeed
    statsAir.maxSpeedAlt
    statsAir.maxAltitude
    statsAir.turnTime
    statsAir.climbSpeed
    statsAir.wingLoading
  ]
  short = [
    statsAir.massPerSec
    statsAir.pylonCount
    statsAir.crew
    statsAir.maxSpeed
    statsAir.turnTime
    statsAir.climbSpeed
  ]
}

let statsCfg = {
  [SHIP] = statsCfgShip,
  [TANK] = statsCfgTank,
  [AIR] = statsCfgAir
}

let mkDamageText = @(dmg, shotFreq, reloadTime = 0) reloadTime > 0 ? $"{round(dmg)}► {reloadTime}▩"
  : shotFreq <= 0 ? $"{round(dmg)}►"
  : $"{round(dmg)}► {round_by_value(1.0 / shotFreq, shotFreq > 1 ? 0.01 : 0.1)}▩"

let mkGunStat = @(id) mkStat(id, {
  isAvailable = @(_) true
  getHeader = @(s, _) loc($"stats/{id}", { caliber = roundCaliber(s?.caliber ?? 0) })
  getValue = @(s) (s?.damage ?? 0) * (s?.shotFreq ?? 0) * (s?.gunsCount ?? 1)
  valueToText = @(_, s) mkDamageText((s?.damage ?? 0) * (s?.gunsCount ?? 1), s?.shotFreq ?? 0)
  getProgress = mkGetProgress(SHIP, $"{id}Dps")
}, SHIP)

let mkWeapStat = @(id, override = {}) mkStat(id, {
  isAvailable = @(_) true
  getHeader = @(s, _) loc($"stats/{id}", { caliber = roundCaliber(s?.caliber ?? 0) })
  getValue = @(s) (s?.damage ?? 0) * (s?.shotFreq ?? 0)
  valueToText = @(_, s) mkDamageText(s?.damage ?? 0, s?.shotFreq ?? 0)
  getProgress = mkGetProgress(SHIP, $"{id}Dps")
}.__update(override), SHIP)

let calcSalvoRocketDamage = @(s) (s?.damage ?? 0) * (
  (s?.reloadTime ?? 0) > 0 ? ((s?.rocketsSalvo ?? 1) / s.reloadTime) : ((s?.gunsCount ?? 1) * (s?.shotFreq ?? 0))
)

let weaponsCfgShip = {
  full = [
    mkGunStat("mainCannon")
    mkGunStat("auxCannon")
    mkGunStat("aaa")
    mkWeapStat("rockets", {
      getValue = @(s) s?.damage ?? 0,
      valueToText = @(_, s) mkDamageText(s?.damage ?? 0, s?.shotFreq ?? 0, s?.reloadTime ?? 0)
      getHeader = @(s, _) loc($"stats/{s?.antiSubRocket ? "asm" : "rockets"}", { caliber = roundCaliber(s?.caliber ?? 0) })
    })
    mkWeapStat("torpedo")
    mkWeapStat("mine")
    mkWeapStat("bomb")
  ]
  short = [
    mkWeapStat("rockets", {
      valueToText = @(_, s) dpsText(calcSalvoRocketDamage(s))
      getHeader = @(s, _) loc($"stats/{s?.antiSubRocket ? "asm" : "rockets"}", { caliber = roundCaliber(s?.caliber ?? 0) })
    })
    mkWeapStat("torpedo", { valueToText = @(_, s) dpsText((s?.damage ?? 0) * (s?.shotFreq ?? 0)) })
  ]
}

let weaponsCfgTank = {
  full = [
    mkStat("armorPower", {
      getHeader = @(_, __) " ".concat(cannonMark, loc("stats/armorPower"))
      valueToText = @(v, _) "".concat(round(v), loc("measureUnits/mm"))
      isAvailable = @(_) true
    }, TANK)
    mkStat("reloadTime", {
      valueToText = @(v, _) "".concat(round_by_value(v, 0.1), loc("measureUnits/seconds"))
      getProgress = mkGetProgressInv(TANK, "reloadTime")
      isAvailable = @(_) true
    }, TANK)
    mkStat("gunnerTurretRotationSpeed", {
      valueToText = @(v, _) "".concat(round(v), loc("measureUnits/deg_per_sec"))
      isAvailable = @(_) true
    }, TANK)
  ]
  short = [
    mkStat("armorPower", {
      getHeader = @(_, __) " ".concat(cannonMark, loc("stats/armorPower"))
      valueToText = @(v, _) "".concat(round(v), loc("measureUnits/mm"))
      isAvailable = @(_) true
    }, TANK)
  ]
}

function findWeapon(weaponSlots, wId, isFullName = true) {
  if (isFullName)
    foreach (weaponSlot in weaponSlots)
      foreach (preset in weaponSlot?.wPresets ?? {})
        foreach (weap in preset?.weapons ?? [])
          if (weap.weaponId == wId)
            return weap
  foreach (weaponSlot in weaponSlots)
    foreach (weap in weaponSlot?.wPresets.default_common.weapons ?? {})
      if (weap.weaponId == wId)
        return weap
  return null
}

function getTotalWeaponAmountByCaliberAndType(weaponSlots, caliber, weaponType) {
  local total = 0
  foreach (weaponSlot in weaponSlots)
    foreach (weap in weaponSlot?.wPresets.default_common.weapons ?? {})
      if (weap.bulletSets[weap.bulletSets.keys()[0]].caliber == caliber && weap.trigger == weaponType)
        total += weap.guns
  return total
}

function getAirGunName(s, u, isFullName = true) {
  let weapon = findWeapon(loadUnitWeaponSlots(u.name), s.wId, isFullName)
  if (weapon == null)
    return ""
  let bSet = weapon.bulletSets[weapon.bulletSets.keys()[0]]
  let totalWeapByCaliberAndType = getTotalWeaponAmountByCaliberAndType(loadUnitWeaponSlots(u.name), bSet.caliber, s.type)
  let withAnyCount = true
  return isFullName ? getWeaponShortNameWithCount(weapon, bSet, withAnyCount, "weapons/counter/right/short")
    : $"{format(loc("caliber/mm"), bSet.caliber)} {format(loc("weapons/counter/right/short"), totalWeapByCaliberAndType)}"
}

let mkAirMainWeapon = @(id) mkStat(id, {
  id = "mainWeapon"
  secondaryId = id
  getHeader = @(s, u) getAirGunName(s, u, false)
  hasSeveralValueRows = true
  getRowListValue = @(v) v
  getRowListHeader = @(_) loc("weapons_types/enum/frontal")
  isAvailable = @(_) true
}, AIR)

let mkAirTurretWeapon = @(id) mkStat(id, {
  id = "turretWeapon"
  secondaryId = id
  getHeader = @(s, u) getAirGunName(s, u, false)
  hasSeveralValueRows = true
  getRowListValue = @(v) v
  getRowListHeader = @(_) loc("weapons_types/enum/turrets")
  isAvailable = @(_) true
}, AIR)

let mkAirSecondaryWeapon = @(id) mkStat(id, {
  id = "secondaryWeapon"
  posOffset = 1 
  secondaryId = id
  getHeader = @(_, __) getWeaponTypeName(id)
  hasSeveralValueRows = true
  getRowListHeader = @(_) loc("weapons_types/enum/secondary")
  getRowListValue = @(v) v
  isAvailable = @(_) true
}, AIR)

let fullGunWeaponId = "fullGunWeapon"
let mkAirFullGunWeapon = @(id) mkStat(id, {
  id = fullGunWeaponId
  secondaryId = id
  getHeader = @(s, u) $"{getAirGunName(s, u)}: {s.ammoCount}, {round_by_value(s.shotFreq, 0.1)}"
  getListTitle = @() loc("weapons_types/enum/weapons")
  isAvailable = @(_) true
}, AIR)

let weaponsCfgAir = {
  full = [
    mkAirFullGunWeapon("cannon")
    mkAirFullGunWeapon("machine gun")
    mkAirFullGunWeapon("gunner")
    mkAirSecondaryWeapon("bombs")
    mkAirSecondaryWeapon("rockets")
    mkAirSecondaryWeapon("torpedoes")
    mkAirSecondaryWeapon("additional gun")
  ]
  short = [
    mkAirMainWeapon("cannon")
    mkAirMainWeapon("machine gun")
    mkAirTurretWeapon("gunner")
    mkAirSecondaryWeapon("bombs")
    mkAirSecondaryWeapon("rockets")
    mkAirSecondaryWeapon("torpedoes")
    mkAirSecondaryWeapon("additional gun")
  ]
}

let weaponsCfg = {
  [SHIP] = weaponsCfgShip,
  [SUBMARINE] = weaponsCfgShip,
  [TANK] = weaponsCfgTank,
  [AIR] = weaponsCfgAir
}

let mkTitleId = @(id) $"{id}:title"
let isMultiline = @(uid) uid == mkTitleId(fullGunWeaponId)

function mkTitle(uid, header, value = "") {
  if (header == null || header == "")
    return null
  return {
    uid
    header
    value
    progress = null
    progressColor = null
    isMultiline = isMultiline(uid)
  }
}

function mkUnitStat(unit, stat, shopCfg, uid, statsWithAttr = {}) {
  if (!stat.isAvailable(shopCfg))
    return null
  let header = stat.getHeader(shopCfg, unit)
  if (header == "")
    return null
  local value = stat.getValue(shopCfg)
  local valueWithAttr = stat.getValue(statsWithAttr)
  return {
    uid 
    header
    value = stat.valueToText(value, shopCfg)
    valueAttr = stat.valueToTextAttr(value, valueWithAttr)
    progress = stat.getProgress?(value)
    progressColor = stat.getProgressColor(unit, value)
    isMultiline = fullGunWeaponId == stat?.id
  }
}

function mutateUnitStats(unitStats, weaponsIdx, unitStat) {
  if (weaponsIdx != null)
    unitStats.insert(weaponsIdx, unitStat)
  else
    unitStats.append(unitStat)
}

let sortedUnitTypesByWeapDmg = [TANK, AIR].reduce(@(res, t) res.$rawset(t, true), {})
let isWeaponById = @(stat, weaponKey) weaponKey.contains(stat?.secondaryId, 0) || weaponKey.contains(stat.id, 0)

let getWeapByTypeFromSlots = @(slots) slots
  .reduce(function(res, slot) {
      foreach(preset in slot.wPresets)
        foreach(weapon in preset.weapons) {
          let { trigger, weaponId, guns, totalBullets, shotFreq } = weapon
          if (trigger not in res)
            res[trigger] <- []
          let idx = res[trigger].findindex(@(w) w.wId == weaponId)
          if (idx != null) {
            let cfg = res[trigger][idx]
            cfg.gunsCount += guns
            cfg.ammoCount += totalBullets
          }
          else
            res[trigger].append({
              type = trigger
              wId = weaponId
              ammoCount = totalBullets
              gunsCount = guns
              shotFreq
            })
        }
      return res
    },
    {})



function getUnitStats(unit, shopCfg, statsWithAttr, statsList, weapStatsList) {
  if (shopCfg == null)
    return []
  if (statsWithAttr == null)
    return []
  let unitStats = statsList.map(@(stat) mkUnitStat(unit, stat, shopCfg, stat.id, statsWithAttr))

  let weaponSlots = loadUnitWeaponSlots(unit.name)
  let weapByType = weaponSlots.len() == 0
    ? (shopCfg?.weapons ?? {}).reduce(function(res, wCfg, wId) {
        let wtype = wCfg?.wtype ?? wCfg?.type ?? "null"
        res[wtype] <- (res?[wtype] ?? []).append(wCfg.__update({ wId }))
        return res
      }, {})
    : getWeapByTypeFromSlots(weaponSlots)

  local weaponsIdx = statsList.findindex(@(stat) stat.isAfterWeapons)
  let existingListStats = {}
  let existingRowLists = {}
  foreach (stat in weapStatsList) {
    if (stat.hasSeveralValueRows && !existingRowLists?[stat.id]) {
      existingRowLists[stat.id] <- true
      let aggregatedStats = weapStatsList.filter(@(v) v.id == stat.id)
      let headers = {}
      foreach (aggregateStat in aggregatedStats) {
        let list = weapByType?.filter(@(_, k) isWeaponById(aggregateStat, k)) ?? []
        if (list.filter(@(v) v != null).len() == 0)
          continue

        foreach (weap in list)
          foreach (wCfg in weap) {
            if (!aggregateStat.isAvailable(wCfg))
              return null
            let header = aggregateStat.getHeader(wCfg, unit)
            if (header != null)
              headers[header] <- true
          }
      }

      if (headers.len() > 0) {
        let title = " ".join(headers.keys())
        let { posOffset = null } = stat
        let pos = weaponsIdx == null ? null
          : posOffset != null ? weaponsIdx + posOffset
          : weaponsIdx++
        mutateUnitStats(unitStats, pos,
          mkTitle(stat.id, stat.getRowListHeader(title), stat.getRowListValue(title)))
      }
      continue
    }

    let list = unit.unitType == TANK ? [weapByType?[shopCfg?.mainWeaponType ?? "mainCannon"]]
      : stat.getListTitle() ? (weapByType?.filter(@(_, k) isWeaponById(stat, k)) ?? [])
      : [weapByType?[stat.id]]
    if (list.filter(@(v) v != null).len() == 0)
      continue

    let listTitle = stat.getListTitle()
    if (listTitle && !existingListStats?[stat.id]) {
      existingListStats[stat.id] <- true
      mutateUnitStats(unitStats, weaponsIdx != null ? weaponsIdx++ : null,
        mkTitle(mkTitleId(stat.id), listTitle))
    }

    foreach (weapListIdx, weap in list) {
      if (!sortedUnitTypesByWeapDmg?[unit.unitType])
        weap.sort(@(a, b) b.damage <=> a.damage)
      foreach (i, wCfg in weap)
        mutateUnitStats(unitStats, weaponsIdx != null ? weaponsIdx++ : null,
          mkUnitStat(unit, stat, wCfg, $"{stat.id}{list.len() == 1 ? i : $"{weapListIdx}{i}"}"))
    }
  }
  return unitStats.filter(@(v) v != null)
}

let setMaxAttrs = @(attrPreset) attrPresets.get()?[attrPreset]
  .reduce(function(res, v) {
    res[v.id] <- v.attrList.reduce(function(acc, a) {
      acc[a.id] <- MAX_ATTR_VALUE
      return acc
    }, {})
    return res
  }, {})

function mkUnitStatsCompFull(unit, attrLevels, attrPreset, mods) {
  attrLevels = (unit?.isPremium || unit?.isUpgraded) ? setMaxAttrs(unit.attrPreset) : attrLevels
  let unitType = unit.unitType
  let stats = applyAttrLevels(unitType, getUnitTagsShop(unit.name), attrLevels, attrPreset, mods)
  return getUnitStats(unit, stats, getUnitTagsShop(unit.name), statsCfg?[unitType].full ?? [], weaponsCfg?[unitType].full ?? [])
}

function mkUnitStatsCompShort(unit, attrLevels, attrPreset, mods) {
  attrLevels = (unit?.isPremium || unit?.isUpgraded) ? setMaxAttrs(unit.attrPreset) : attrLevels
  let unitType = unit.unitType
  let stats = applyAttrLevels(unitType, getUnitTagsShop(unit.name), attrLevels, attrPreset, mods)
  return getUnitStats(unit, stats, getUnitTagsShop(unit.name), statsCfg?[unitType].short ?? [], weaponsCfg?[unitType].short ?? [])
}

function appendStatValue(res, stat, shopCfg) {
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

function gatherUnitStatsLimits(unitsList) {
  let values = {}
  foreach (unitName in unitsList) {
    let unitType = getUnitType(unitName)
    let shopCfg = getUnitTagsShop(unitName)
    statsCfg?[unitType].full.each(@(stat) appendStatValue(values, stat, shopCfg))

    let weapByType = (shopCfg?.weapons ?? {}).reduce(function(res, wCfg) {
      let wtype = wCfg?.wtype ?? wCfg?.type ?? "null"
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
  addedFromSlot
}
