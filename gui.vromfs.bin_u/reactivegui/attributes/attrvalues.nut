from "%globalsDarg/darg_library.nut" import *
let { Point2 } = require("dagor.math")
let { isDataBlock, blk2SquirrelObjNoArrays, getBlkByPathArray, blkOptFromPath
} = require("%sqstd/datablock.nut")
let { round, round_by_value, fabs } = require("%sqstd/math.nut")
let { deep_clone } = require("%sqstd/underscore.nut")
let { getHudConfigParameter } = require("%rGui/hud/hudConfigParameters.nut")
let { get_modifications_blk } = require("blkGetters")
let { TANK, SHIP, AIR } = require("%appGlobals/unitConst.nut")

let iconDamage = "►"
let iconCooldown = "▩"

let defCategoryImage = "ui/gameuiskin#upgrades_captain_icon.avif"
let categoryImages = {
  ship_commander = "ui/gameuiskin#upgrades_captain_icon.avif"
  ship_look_out_station = "ui/gameuiskin#upgrades_observation_icon.avif"
  ship_engine_room = "ui/gameuiskin#upgrades_mechanic_icon.avif"
  ship_artillery = "ui/gameuiskin#upgrades_artillery_icon.avif"
  ship_damage_control = "ui/gameuiskin#upgrades_torpedoes_icon.avif"
  ship_missiles = "ui/gameuiskin#upgrades_ship_rckt_weaponry_icon.avif"
  tank_fire_power = "ui/gameuiskin#upgrades_tank_firepower_icon.avif"
  tank_crew = "ui/gameuiskin#upgrades_tank_crew_icon.avif"
  tank_protection = "ui/gameuiskin#upgrades_tools_icon.avif"
  plane_flight_performance = "ui/gameuiskin#upgrades_flight_performance.avif"
  plane_crew = "ui/gameuiskin#upgrades_plane_crew.avif"
  plane_weapon = "ui/gameuiskin#upgrades_plane_weapon.avif"
}

let tankAttrToTankCrewParamsMap = {
  loading_time_mult = [ "loader", "loadingTimeMult" ]
  tracking = [ "tank_gunner", "targetingSpeedYawMult" ]
  eyesight = [ "driver", "visionSpottingDistanceMultiplier" ]
  agility = [ "driver", "changeTimeMultiplier" ]
  vitality = [ "driver", "damageMultiplier" ]
  driving = [ "driver", "brakesTau" ]
  field_repair = [ "driver", "fieldRepairSpeedMultiplier" ]
}

let planeAttrToCrewParamsMap = {
  plane_engine = [ "flightPerformance", "engine" ]
  plane_fuselage = [ "flightPerformance", "fuselage" ]
  plane_flaps_wings = [ "flightPerformance", "flapsWings" ]
  plane_compressor = [ "flightPerformance", "compressor" ]
  plane_spotting = [ "pilot", "detection", "vision", "spottingDistance" ]
  plane_threat_recognition = [ "pilot", "detection", "hearing", "spottingDistance" ]
  plane_overload_resistance = [ "gForce", "adaptationK" ]
  plane_protection = [ "pilot", "takingDamage", "damageMultiplier" ]
  plane_accuracy = [ "gunner", "shooting", "fullStamina", "accuracy" ]
  plane_jamming = [ "weaponsmith", "weaponCare", "jamProbabilityMultiplier" ]
  plane_reloading = [ "weaponsmith", "reloadSpeed", "gun" ]
  plane_scatter = [ "weaponsmith", "weaponCare", "mulMaxDeltaAngle" ]
}

function modsMul(attrId, mods) {
  if (attrId == "attrib_ship_max_speed" && !mods?.maintanance_new_engines)
    return get_modifications_blk()?.modifications.maintanance_new_engines.effects.mulMaxSpeed ?? 1.0
  return 1.0
}

let isPoint2 = @(p) type(p) == "instance" && p instanceof Point2

function getAttrMaxMulsCfgShip() {
  let attributesBlk = blkOptFromPath("config/attributes.blk")
  return isDataBlock(attributesBlk?.ship_attributes)
    ? blk2SquirrelObjNoArrays(attributesBlk.ship_attributes)
    : {}
}

function getAttrMultsCfgPlane() {
  let crewSkillsBlk = blkOptFromPath("config/crew_skills.blk")
  let crewParametersBlk = crewSkillsBlk?.crew_parameters
  let rangeDefault = Point2(1.0, 1.0)
  local attributes = planeAttrToCrewParamsMap.map(function(pathArray) {
    let range = getBlkByPathArray(pathArray, crewParametersBlk, rangeDefault)
    return isPoint2(range)
      ? { begin = range.x, end = range.y }
      : { begin = rangeDefault.x, end = rangeDefault.y }
  })
  return attributes
}

function getAttrRangesCfgTank() {
  let crewSkillsBlk = blkOptFromPath("config/crew_skills.blk")
  let tankCrewBlk = crewSkillsBlk?.crew_parameters.tank_crew
  let rangeDefault = Point2(0.0, 0.0)
  return tankAttrToTankCrewParamsMap
    .map(function(pathArray) {
      let range = getBlkByPathArray(pathArray, tankCrewBlk, rangeDefault)
      return (isPoint2(range) && range.x > 0.0 && range.y > 0.0)
        ? { begin = range.x, end = range.y }
        : { begin = 1.0, end = 1.0 }
    })
    // Should get accuracy as mulMaxDeltaAngle from modifications.blk,
    // but in-game modifications.blk is currently truncated.
    .__update({ accuracy = { begin = 0.75, end = 1.0 } })
}

let attrMaxMulsShip = getAttrMaxMulsCfgShip()
let attrRangesTank = getAttrRangesCfgTank()
let attrMultsPlane = getAttrMultsCfgPlane()

function getTopWeaponByTypes(shopCfgWeapons, wTypes) {
  let weapons = (shopCfgWeapons ?? {})
    .filter(@(v) wTypes.contains(v?.wtype))
    .values()
    .sort(@(a, b) (b?.damage ?? 0) <=> (a?.damage ?? 0))
  return weapons?[0]
}

function mulStat(stats, k, mul) {
  if (k in stats)
    stats[k] = stats[k] * mul
}

function mulWeap(stats, k, mul, wTypes) {
  foreach (weapon in (stats?.weapons ?? {}))
    if (wTypes.contains(weapon?.wtype) && (k in weapon))
      weapon[k] = weapon[k] * mul
}

let attrValCfgDefault = {
  labelLocId = null
  getBaseVal = @(_shopCfg) 0.0
  getMulMin = @(_attrId) 1.0
  getMulMax = @(_attrId) 1.0
  valueToText = @(_v) ""
  updateStats = null

  relatedStat = null
  relatedWeapStat = null
  relatedWeapTypes = []
}

function mkValCfg(cfg) {
  local res = cfg
  let { relatedStat = null, relatedWeapStat = null, relatedWeapTypes = [] } = res
  if (relatedStat)
    res = {
      labelLocId = $"stats/{relatedStat}"
      getBaseVal = @(shopCfg) shopCfg?[relatedStat] ?? 0.0
      getMulMin = @(_attrId) 1.0
      updateStats = @(stats, mul) mulStat(stats, relatedStat, mul)
    }.__update(res)
  if (relatedWeapStat)
    res = {
      getBaseVal = @(shopCfg) getTopWeaponByTypes(shopCfg?.weapons, relatedWeapTypes)?[relatedWeapStat] ?? 0.0
      updateStats = @(stats, mul) mulWeap(stats, relatedWeapStat, mul, relatedWeapTypes)
    }.__update(res)
  return attrValCfgDefault.__merge(res)
}

let shipAttrs = {
  attrib_he_shell_damage = {
    function getBaseVal(shopCfg) {
      let weapon = getTopWeaponByTypes(shopCfg?.weapons, [ "mainCannon", "auxCannon" ])
      return (weapon?.damage ?? 0.0) * (weapon?.gunsCount ?? 1)
    }
    getMulMax = @(attrId) (attrMaxMulsShip?[attrId].mulExplDamage ?? 0.0) + 1.0
    valueToText = @(v) "".concat(round(v), iconDamage)
    relatedWeapStat = "damage"
    relatedWeapTypes = [ "mainCannon", "auxCannon" ]
  }
  attrib_player_gun_accuracy = {
    getBaseVal = @(_shopCfg) 1.0
    getMulMax = @(attrId) (attrMaxMulsShip?[attrId].mulMaxDeltaAngle ?? 0.0) + 1.0
    valueToText = @(v) "".concat("+", round_by_value((v - 1.0) * 100, 0.1), "%")
  }
  attrib_player_gun_reload_rate = {
    getMulMax = @(attrId) attrMaxMulsShip?[attrId].mulShotFreq ?? 1.0
    valueToText = @(v) "".concat(round_by_value(v != 0 ? (1.0 / v) : 0, 0.01), iconCooldown)
    relatedWeapStat = "shotFreq"
    relatedWeapTypes = [ "mainCannon", "auxCannon" ]
  }
  attrib_ai_aa_accuracy = {
    getBaseVal = @(_shopCfg) 1.0
    getMulMax = @(attrId) attrMaxMulsShip?[attrId].mulAccuracyBot ?? 1.0
    valueToText = @(v) "".concat("+", round_by_value((v - 1.0) * 100, 0.1), "%")
  }
  attrib_ai_aa_distance = {
    getBaseVal = @(shopCfg) getTopWeaponByTypes(shopCfg?.weapons, [ "aaa" ])?.aimMaxDist ?? 0
    getMulMax = @(attrId) attrMaxMulsShip?[attrId].mulAimMaxDist ?? 1.0
    valueToText = @(v) "".concat(round_by_value(v / 1000.0, 0.1), loc("measureUnits/km_dist"))
  }
  attrib_torpedo_distance = {
    getBaseVal = @(shopCfg) (getTopWeaponByTypes(shopCfg?.weapons, [ "torpedo" ])?.distToLive ?? 0)
      * getHudConfigParameter("distanceViewMultiplier").tofloat()
    getMulMax = @(attrId) attrMaxMulsShip?[attrId].mulDistTolive ?? 1.0
    valueToText = @(v) "".concat(round_by_value(v / 1000.0, 0.1), loc("measureUnits/km_dist"))
  }
  attrib_torpedo_count = {
    function getAttrValText(attrId, step, stepsTotal, shopCfg) {
      let weapon = getTopWeaponByTypes(shopCfg?.weapons, [ "torpedo" ])
      let { addTorpedoesCountPack = 0 } = shopCfg
      let { ammoCount = 0 } = weapon
      let addAttrByStep = (attrMaxMulsShip?[attrId].addTorpedo ?? 1.0) / stepsTotal
      return ammoCount + addTorpedoesCountPack * addAttrByStep * step
    }
  }
  attrib_ship_endurance = {
    labelLocId = "stats/shipCrewAll"
    getMulMax = @(attrId) attrMaxMulsShip?[attrId].mulMetaPartsHp ?? 1.0
    valueToText = @(v) round(v)
    relatedStat = "shipCrewMax"
    function updateStats(stats, mul) {
      mulStat(stats, "shipCrewMin", mul)
      mulStat(stats, "shipCrewMax", mul)
      mulStat(stats, "shipCrewRating", mul)
    }
  }
  attrib_ship_max_speed = {
    getMulMax = @(attrId) attrMaxMulsShip?[attrId].mulMaxSpeed ?? 1.0
    valueToText = @(v) "".concat(round(v * 3.6), loc("measureUnits/kmh"))
    relatedStat = "maxSpeed"
  }
  attrib_ship_steering = {
    function getMulMax(attrId) {
      let mulShipRudderArea = attrMaxMulsShip?[attrId].mulShipRudderArea ?? 1.0
      return mulShipRudderArea != 0 ? (1.0 / mulShipRudderArea) : 1.0
    }
    valueToText = @(v) "".concat(round_by_value(v, 0.1), loc("measureUnits/seconds"))
    relatedStat = "turningTime"
  }
  attrib_rckt_damage = {
    getBaseVal = @(shopCfg) (getTopWeaponByTypes(shopCfg?.weapons, ["rockets"])?.damage ?? 0)
    getMulMax = @(attrId) attrMaxMulsShip?[attrId].explosiveMassMul ?? 1.0
    valueToText = @(v) "".concat(round(v), iconDamage)
  }
  attrib_rckt_capture_time = {
    getBaseVal = @(shopCfg) shopCfg?.asmCaptureDuration ?? 0
    getMulMax = @(attrId) attrMaxMulsShip?[attrId].asmCaptureDurationMul ?? 1.0
    valueToText = @(v) "".concat(round_by_value(v, 0.1), iconCooldown)
    relatedStat = "asmCaptureDuration"
  }
  attrib_rckt_cm_lifetime = {
    getBaseVal = @(shopCfg) (getTopWeaponByTypes(shopCfg?.weapons, ["ircm"])?.cmLiveTime ?? 0)
    getMulMax = @(attrId) attrMaxMulsShip?[attrId].cloudTimeLifeMul ?? 1.0
    valueToText = @(v) "".concat(round_by_value(v, 0.1), iconCooldown)
  }
}.map(@(c) mkValCfg(c))

function mkAttrFrom100prcUp(attrId, roundBy = 0.1) {
  let { begin, end } = attrRangesTank[attrId]
  let rMin = begin < end ? begin : end
  let rMax = begin < end ? end : begin
  let mulMax = rMin != 0 ? (rMax / rMin) : 1.0
  return {
    getBaseVal = @(_shopCfg) 1.0
    getMulMax = @(_attrId) mulMax
    valueToText = @(v) "".concat(round_by_value(v * 100, roundBy), "%")
  }
}

function mkAttrUpTo100prc(attrId, roundBy = 0.1) {
  let { begin, end } = attrRangesTank[attrId]
  let rMin = begin < end ? begin : end
  let rMax = begin < end ? end : begin
  let baseVal = rMax != 0 ? (1.0 / rMax) : 0.0
  return {
    getBaseVal = @(_shopCfg) baseVal
    getMulMin = @(_attrId) rMin
    getMulMax = @(_attrId) rMax
    valueToText = @(v) "".concat(round_by_value(v * 100, roundBy), "%")
  }
}

function mkAttrFromMinus0prcUp(attrId, roundBy = 0.1) {
  let { begin, end } = attrRangesTank[attrId]
  return {
    getBaseVal = @(_shopCfg) 1.0
    getMulMin = @(_attrId) 0.0
    getMulMax = @(_attrId) begin - end
    valueToText = @(v) "".concat("+", round_by_value(v * 100, roundBy), "%")
  }
}

let tankAttrs = {
  loading_time_mult = mkAttrFromMinus0prcUp("loading_time_mult")
    .__update({
      updateStats = @(stats, mul) stats.weapons.each(@(el) mulStat(el, "reloadTime", attrRangesTank["loading_time_mult"].begin - mul))
    })
  tracking = mkAttrUpTo100prc("tracking")
    .__update({
      updateStats = @(stats, mul) stats.weapons.each(@(el) mulStat(el, "gunnerTurretRotationSpeed", mul / attrRangesTank.tracking.begin))
    })
  accuracy = mkAttrUpTo100prc("accuracy")
  eyesight = mkAttrFrom100prcUp("eyesight")
  agility = {
    getBaseVal = @(_shopCfg) 10.0
    getMulMin = @(_attrId) attrRangesTank.agility.begin
    getMulMax = @(_attrId) attrRangesTank.agility.end
    valueToText = @(v) "".concat(round_by_value(v, 0.1), loc("measureUnits/seconds"))
  }
  vitality = mkAttrFrom100prcUp("vitality")
  battleRepairItems = {
    function getValDataByServConfigs(attr, step, servConfigs) {
      let { allItems = {}, itemsByAttributes = [] } = servConfigs
      let cfg = itemsByAttributes.filter(@(c) c.attribute == attr.id) //we ignore category but it not important atm
      if (cfg.len() == 0)
        return []
      let res = []
      foreach (c in cfg) {
        let { battleLimit = null } = allItems?[c.item]
        if (battleLimit == null)
          continue
        if (res.len() > 0)
          res.append({ ctor = ROBJ_TEXT, value = comma })
        res.append({ ctor = ROBJ_IMAGE, value = c.item },
          { ctor = ROBJ_TEXT, value = battleLimit + (c.battleLimitAdd?[step - 1] ?? 0) })
      }
      return res
    }
  }
  driving = mkAttrUpTo100prc("driving")
  field_repair = mkAttrUpTo100prc("field_repair", 1.0)
}.map(@(c) mkValCfg(c))

function mkAttributePlusPercent(attrId, roundBy = 0.1) {
    let { begin, end } = attrMultsPlane[attrId]
    let rMin = begin < end ? begin : end
    let rMax = begin < end ? end : begin
    let mulMax = rMin != 0 ? (rMax / rMin) : 0.0
    return {
    getBaseVal = @(_) 1.0
    getMulMin = @(_) 1.0
    getMulMax = @(_) mulMax
    valueToText = @(v) "".concat("+", round_by_value(fabs(v - 1.0) * 100, roundBy), "%")
  }
}

let planeAttrs = {
  plane_engine = mkAttributePlusPercent("plane_engine")
  plane_fuselage = mkAttributePlusPercent("plane_fuselage")
  plane_flaps_wings = mkAttributePlusPercent("plane_flaps_wings")
  plane_compressor = mkAttributePlusPercent("plane_compressor")
  plane_spotting = mkAttributePlusPercent("plane_spotting")
  plane_threat_recognition = mkAttributePlusPercent("plane_threat_recognition")
  plane_overload_resistance = mkAttributePlusPercent("plane_overload_resistance")
  plane_protection = mkAttributePlusPercent("plane_protection")
  plane_accuracy = mkAttributePlusPercent("plane_accuracy")
  plane_jamming = mkAttributePlusPercent("plane_jamming")
  plane_reloading = mkAttributePlusPercent("plane_reloading")
  plane_scatter = mkAttributePlusPercent("plane_scatter")
}

let attrValCfg = {
  [SHIP] = shipAttrs,
  [TANK] = tankAttrs,
  [AIR] = planeAttrs,
}

let getAttrLabelText = @(unitType, attrId) loc(attrValCfg?[unitType][attrId].labelLocId ?? attrId)

let getAttrMul = @(cfg, attrId, step, stepsTotal) stepsTotal != 0
  ? ((cfg.getMulMax(attrId) - cfg.getMulMin(attrId)) / stepsTotal * step) + cfg.getMulMin(attrId)
  : 1.0

function getAttrValData(unitType, attr, step, shopCfg, servConfigs, mods) {
  let attrId = attr.id
  let stepsTotal = attr.levelCost.len() // Total level progress steps
  let cfg = attrValCfg?[unitType][attrId] ?? attrValCfgDefault

  let data = cfg?.getValDataByServConfigs(attr, step, servConfigs)
  if (data != null)
    return data

  let textVal = cfg?.getAttrValText(attrId, step, stepsTotal, shopCfg)
    ?? cfg.valueToText(cfg.getBaseVal(shopCfg) * getAttrMul(cfg, attrId, step, stepsTotal) * modsMul(attrId, mods))
    ?? ""
  return textVal == "" ? [] : [{ ctor = ROBJ_TEXT, value = textVal }]
}

function applyAttrLevels(unitType, shopCfg, attrLevels, attrPreset, mods) {
  let stats = shopCfg != null ? deep_clone(shopCfg) : null
  if (stats == null || attrPreset == null)
    return stats

  foreach (preset in attrPreset) {
    let catId = preset.id
    foreach(attr in preset.attrList) {
      let attrId = attr?.id
      let cfg = attrValCfg?[unitType][attrId]
      if (cfg?.updateStats == null)
          continue
      let stepsTotal = attr.levelCost.len() ?? 0
      let step = attrLevels?[catId][attrId] ?? 0
      cfg.updateStats(stats, getAttrMul(cfg, attrId, step, stepsTotal) * modsMul(attrId, mods))
    }
  }
  return stats
}

return {
  getAttrLabelText
  defCategoryImage
  applyAttrLevels
  getAttrValData
  categoryImages
}
