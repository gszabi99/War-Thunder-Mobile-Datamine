from "%globalsDarg/darg_library.nut" import *
let { Point2 } = require("dagor.math")
let { getUnitFileName } = require("vehicleModel")
let { getUnitTagsCfg, getUnitType } = require("%appGlobals/unitTags.nut")
let { AIR } = require("%appGlobals/unitConst.nut")
let { eachBlock, isDataBlock, blkOptFromPath } = require("%sqstd/datablock.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { isReadyToFullLoad, isLoginRequired } = require("%appGlobals/loginState.nut")

let WT_GUNS = "guns"
let WT_SMOKE = "smoke"
let WT_COUNTERMEASURES = "countermeasures"
let WT_FLARES = "flares"
let WT_AAM = "aam" // Air-to-Air Missiles
let WT_AGM = "agm" // Air-to-Ground Missile, Anti-Tank Guided Missiles
let WT_ROCKETS = "rockets"
let WT_BOMBS = "bombs"
let WT_TORPEDO = "torpedoes"

let allCustomBulletParams = [
  "explosiveType", "explosiveMass", "explodeTreshold", "speed", "ricochetPreset", "mass", "mass_lbs",
  "dropSpeedRange", "dropHeightRange", "maxSpeedInWater", "distToLive", "maxSpeed"
]

let valConvert = {
  [Point2] = @(v) [ v.x, v.y ]
}
let prepareVal = @(v) valConvert?[v?.getclass()](v) ?? v

let warhedByKineticDamage = @(kineticDamage) kineticDamage?.damageType == "tandemPrecharge" ? "tandem" : "heat"
let getRocketParams = @(wBlk) {
  warhead = wBlk?.strikingPart != null ? "multidart"
    : wBlk?.smokeShell == true ? "smoke"
    : wBlk?.cumulativeDamage.armorPower != null ? warhedByKineticDamage(wBlk?.kineticDamage)
    : wBlk?.explosiveType != null && wBlk?.armorpower != null ? "aphe"
    : wBlk?.explosiveType != null ? "he"
    : "ap"
}

let customParamsByWeaponType = {
  [WT_ROCKETS] = getRocketParams,
  [WT_AGM] = getRocketParams,
}


let fullCache = persist("fullCache", @() {})
let choiceCache = {}
let blkToWeaponId = {}

function getWeaponIdImpl(blkPath) {
  local start = 0
  local searchFrom = 0
  while (searchFrom != null) { // -expr-cannot-be-null
    searchFrom = blkPath.indexof("/", searchFrom + 1) ?? blkPath.indexof("\\", searchFrom + 1)
    if (searchFrom != null)
      start = searchFrom + 1
  }
  local end = blkPath.indexof(".", start) ?? blkPath.len()
  return blkPath.slice(start, end)
}

function getWeaponId(blkPath) {
  if (blkPath not in blkToWeaponId)
    blkToWeaponId[blkPath] <- getWeaponIdImpl(blkPath)
  return blkToWeaponId[blkPath]
}

function gatherWeaponsFromBlk(weaponsBlk, hasTriggerGroups, res = null) {
  res = res ?? {}
  foreach (wBlk in (weaponsBlk % "Weapon")) {
    let { dummy = false, blk = null, triggerGroup = null, trigger = "", bullets = 0, turret = null } = wBlk
    let triggerGroupExt = hasTriggerGroups ? (triggerGroup ?? "primary") : trigger
    if (dummy || blk == null)
      continue
    if (triggerGroupExt not in res)
      res[triggerGroupExt] <- {}
    if (blk not in res[triggerGroupExt])
      res[triggerGroupExt][blk] <- { totalBullets = 0, guns = 0, weaponId = getWeaponId(blk), trigger, triggerGroup,
        turrets = 0
      }
    res[triggerGroupExt][blk].totalBullets += bullets
    res[triggerGroupExt][blk].guns++
    if (turret != null)
      res[triggerGroupExt][blk].turrets++
  }
  return res
}

function gatherSlotWeaponPreset(weaponsBlk) {
  let res = []
  let byBlk = {}
  foreach (wBlk in (weaponsBlk % "Weapon")) {
    let { dummy = false, blk = null, trigger = "", bullets = 0, turret = null } = wBlk
    if (dummy || blk == null)
      continue
    if (blk not in byBlk) {
      byBlk[blk] <- { blk, totalBullets = 0, guns = 0, weaponId = getWeaponId(blk), trigger, turrets = 0 }
      res.append(byBlk[blk])
    }
    byBlk[blk].totalBullets += bullets
    byBlk[blk].guns++
    if (turret != null)
      byBlk[blk].turrets++
  }
  return res
}

function appendOnce(arr, v) {
  if (!arr.contains(v))
    arr.append(v)
}

function getBulletsList(bulletsBlk) {
  local bulletsList = bulletsBlk % "bullet"
  local weaponType = WT_GUNS
  if (bulletsList.len() != 0)
    return { bulletsList, weaponType }

  bulletsList = bulletsBlk % "rocket"
  if (bulletsList.len() != 0) {
    let rocket = bulletsList[0]
    return {
      bulletsList
      weaponType = rocket?.smokeShell == true ? WT_SMOKE
        : (rocket?.isFlare == true) || (rocket?.isChaff == true) ? WT_COUNTERMEASURES
        : rocket?.smokeShell == false ? WT_FLARES
        : rocket?.bulletType == "atgm_tank" ? WT_AGM
        : rocket?.operated == true || rocket?.guidanceType != null ? WT_AAM
        : WT_ROCKETS
    }
  }

  bulletsList = bulletsBlk % "bomb"
  if (bulletsList.len() != 0)
    return { bulletsList, weaponType = WT_BOMBS }

  bulletsList = bulletsBlk % "torpedo"
  if (bulletsList.len() != 0)
    return { bulletsList, weaponType = WT_TORPEDO }

  return { bulletsList, weaponType }
}

function loadBullets(bulletsBlk, id, weaponBlkName, isBulletBelt) {
  if (bulletsBlk.paramCount() == 0 && bulletsBlk.blockCount() == 0)
    return null

  let { bulletsList, weaponType } = getBulletsList(bulletsBlk)
  if (bulletsList.len() == 0)
    return null

  local res = null
  foreach (b in bulletsList) {
    let paramsBlk = isDataBlock(b?.rocket) ? b.rocket : b
    let shellAnimations = paramsBlk % "shellAnimation"
    if (res != null) {
      foreach (anim in shellAnimations)
        appendOnce(res.shellAnimations, anim)
    }
    else
      res = {
        id
        weaponBlkName
        weaponType
        caliber = 1000.0 * (paramsBlk?.caliber ?? 0)
        bullets = []
        bulletNames = []
        bulletDataByType = {}
        isBulletBelt = isBulletBelt && weaponType == WT_GUNS
        shellAnimations = clone shellAnimations
      }

    let bulletType = b?.bulletType ?? b.getBlockName()
    res.bullets.append(bulletType)
    res.bulletDataByType[bulletType] <- {}

    if (paramsBlk?.guiCustomIcon != null) {
      if (res?.customIconsMap == null)
        res.customIconsMap <- {}
      res.customIconsMap[bulletType] <- paramsBlk.guiCustomIcon
    }

    if ("bulletName" in b)
      res.bulletNames.append(b.bulletName)

    foreach (param in allCustomBulletParams)
      if (param in paramsBlk) {
        let val = prepareVal(paramsBlk[param])
        res[param] <- val
        res.bulletDataByType[bulletType][param] <- val
      }
    let addParams = customParamsByWeaponType?[weaponType](paramsBlk)
    if (addParams != null)
      foreach (key, value in addParams) {
        res[key] <- value
        res.bulletDataByType[bulletType][key] <- value
      }

    foreach (param in ["smokeShellRad", "smokeActivateTime", "smokeTime"])
      if (param in paramsBlk)
        res[param] <- paramsBlk[param]

    let { proximityFuse = null, sonicDamage = null } = paramsBlk
    if (isDataBlock(proximityFuse)) {
      res.proximityFuseArmDistance <- proximityFuse?.armDistance ?? 0
      res.proximityFuseRadius      <- proximityFuse?.radius ?? 0
    }

    if (isDataBlock(paramsBlk?.sonicDamage))
      res.sonicDamage <- {
        distance  = sonicDamage?.distance ?? 0.0
        speed     = sonicDamage?.speed ?? 0.0
        horAngles = sonicDamage?.horAngles
        verAngles = sonicDamage?.verAngles
      }
  }

  if (res == null)
    return res

  if (res.bullets.len() == 1)
    res.bulletDataByType.clear() //no need copy when only single bullet.

  res.mass <- bulletsList.reduce(@(r, b) r + (b?.mass ?? 0.0), 0.0) / bulletsList.len()
  let massLbsSum = bulletsList.reduce(@(r, b) r + (b?.mass_lbs ?? 0.0), 0.0)
  if (massLbsSum > 0)
    res.mass_lbs <- massLbsSum / bulletsList.len()
  if (res.bulletNames.len() > 1 && res.bulletNames.findvalue(@(v) v != res.bulletNames[0]) == null)
    res.isUniform <- true

  return res
}

function loadAllBullets(weaponBlkName) {
  let weaponBlk = blkOptFromPath(weaponBlkName)
  let { bullets = 0, bulletsCartridge = 1, useSingleIconForBullet = false, mass = 0.0,
    container = false, blk = "", shotFreq = 0
  } = weaponBlk
  let isBulletBelt = !useSingleIconForBullet
    && ((weaponBlk?.isBulletBelt ?? true) || bulletsCartridge > 1)

  let res = {
    catridge = bulletsCartridge
    total = bullets
    gunMass = mass
    bulletSets = {}
    blk = container ? blk : weaponBlkName
    shotFreq
  }
  let defBullets = container
    ? loadBullets(blkOptFromPath(blk), "", blk, isBulletBelt)
    : loadBullets(weaponBlk, "", weaponBlkName, isBulletBelt)
  if (defBullets != null)
    res.bulletSets[""] <- defBullets
  eachBlock(weaponBlk, function(b) {
    let id = b.getBlockName()
    let bulletsList = loadBullets(b, id, weaponBlkName, isBulletBelt)
    if (bulletsList != null)
      res.bulletSets[id] <- bulletsList
  })
  return res
}

function loadBulletsCached(weaponBlkName, cache) {
  if (weaponBlkName not in cache)
    cache[weaponBlkName] <- loadAllBullets(weaponBlkName)
  return cache[weaponBlkName]
}

function calcMass(weapon) {
  let { bulletSets, totalBullets, gunMass } = weapon
  return gunMass + totalBullets * (bulletSets.findvalue(@(v) v.mass > 0)?.mass ?? 0.0)
}

function calcMassLbs(weapon) {
  let { bulletSets, totalBullets } = weapon //massLbs does not used with guns. so no need to count gun mass in lbs
  return totalBullets * (bulletSets.findvalue(@(v) "mass_lbs" in v)?.mass_lbs ?? 0.0)
}

function getBanPresets(presetBlk) {
  let res = {}
  foreach(banned in presetBlk % "BannedWeaponPreset") {
    let { slot = -1, preset = "" } = banned
    if (slot == -1 || preset == "")
      continue
    if (slot not in res)
      res[slot] <- {}
    res[slot][preset] <- true
  }
  return res
}

function fillBanAndMirrors(slots, notUseForDisbalance) {
  foreach(slotIdx, s in slots) {
    foreach(presetId, preset in s.wPresets)
      foreach(banIdx, banList in preset.banPresets)
        foreach(banId, _ in banList) {
          let tgtBanList = slots?[banIdx].wPresets[banId].banPresets
          if (tgtBanList == null)
            continue
          if (slotIdx not in tgtBanList)
            tgtBanList[slotIdx] <- {}
          tgtBanList[slotIdx][presetId] <- true
        }

    if (slotIdx == 0 || !!notUseForDisbalance?[slotIdx])
      continue
    let mirror = slots.len() - slotIdx
    if (mirror == slotIdx)
      continue
    s.mirror <- mirror
    let mirrorOrder = slots[mirror].wPresetsOrder
    foreach(i, p in s.wPresetsOrder)
      if (i in mirrorOrder && p != mirrorOrder[i])
        s.wPresets[p].mirrorId <- mirrorOrder[i]
  }
}

function loadUnitBulletsFullImpl(unitName) {
  let triggersData = {}
  let unitBlk = blkOptFromPath(getUnitFileName(unitName))
  let { commonWeapons = null, weapon_presets = null, WeaponSlots = null } = unitBlk
  let hasTriggerGroups = getUnitType(unitName) != AIR
  if (isDataBlock(commonWeapons))
    triggersData.commonWeapons <- gatherWeaponsFromBlk(commonWeapons, hasTriggerGroups)

  let weaponSlots = {}
  let weaponSlotsOrder = {}
  let slotsParams = {}
  if (isDataBlock(WeaponSlots)) {
    slotsParams.notUseForDisbalance <- {}
    foreach(wsBlk in WeaponSlots % "WeaponSlot") {
      let { index = null, notUseforDisbalanceCalculation = false } = wsBlk
      if (index == null)
        continue
      if (notUseforDisbalanceCalculation)
        slotsParams.notUseForDisbalance[index] <- true
      weaponSlots[index] <- {}
      weaponSlotsOrder[index] <- []
      foreach(presetBlk in wsBlk % "WeaponPreset") {
        let presetName = presetBlk?.name
        if (presetName == null)
          continue
        weaponSlots[index][presetName] <- presetBlk
        weaponSlotsOrder[index].append(presetName)
      }
    }
    foreach(id in ["maxloadMass", "maxloadMassLeftConsoles", "maxloadMassRightConsoles", "maxDisbalance"])
      slotsParams[id] <- WeaponSlots?[id] ?? 0
  }

  if (isDataBlock(weapon_presets))
    eachBlock(weapon_presets, function(b) {
      let { name = "", blk = null } = b
      if (name != $"{unitName}_default") //we not use not default preset
        return
      let fullPresetBlk = blkOptFromPath(blk)
      triggersData[name] <- gatherWeaponsFromBlk(fullPresetBlk, hasTriggerGroups)
      if (weaponSlots.len() == 0)
        return
      let usedSlots = {}
      foreach(w in fullPresetBlk % "Weapon") {
        let { slot = null, preset = null } = w
        let presetBlk = weaponSlots?[slot][preset]
        if (presetBlk == null)
          continue
        triggersData[name] = gatherWeaponsFromBlk(presetBlk, hasTriggerGroups, triggersData[name])
        usedSlots[slot] <- true //-potentially-nulled-index
      }
      foreach(slot, slotPresets in weaponSlots) {
        if (usedSlots?[slot])
          continue
        foreach(presetId, presetBlk in slotPresets)
          if (presetId.startswith("default")) {
            triggersData[name] = gatherWeaponsFromBlk(presetBlk, hasTriggerGroups, triggersData[name])
            break
          }
      }
    })

  let bulletsCache = {}
  let presets = triggersData.map(@(presetTriggers)
    presetTriggers.map(function(triggerWeapons) {
      let bulletSets = {}
      local weaponId = ""
      local guns = 0
      local catridge = 1
      local total = 0
      local trigger = ""
      local triggerGroup = null
      local turrets = 0
      foreach (wBlkName, wData in triggerWeapons) {
        let bulletsData = loadBulletsCached(wBlkName, bulletsCache)
        if (bulletSets.len() == 0) {
          weaponId = wData.weaponId
          catridge = bulletsData.catridge
          trigger = wData.trigger
          triggerGroup = wData.triggerGroup
        }
        guns += wData.guns
        total += wData.totalBullets
        turrets += wData.turrets
        bulletSets.__update(bulletsData?.bulletSets)
      }
      return { weaponId, bulletSets, catridge, guns, total, trigger, triggerGroup, turrets }
    }))

  let res = { presets, slots = [], slotsParams, reqModifications = {} }

  let { reqModifications } = res
  let { bullets = {} } = getUnitTagsCfg(unitName)

  foreach(preset in presets)
    foreach(weapon in preset) {
      let { bulletSets, weaponId } = weapon
      let bulletsTags = bullets?[weaponId] ?? {}
      foreach(bSet in bulletSets) {
        let reqModification = bulletsTags?[bSet.id].reqModification ?? ""
        reqModifications[reqModification] <- true
      }
    }

  if("" in reqModifications)
    reqModifications.$rawdelete("")

  if (weaponSlots.len() == 0)
    return res

  let { slots } = res
  let weaponsTags = getUnitTagsCfg(unitName)?.Shop.weapons
  foreach(index, slotPresets in weaponSlots) {
    let wPresets = slotPresets.map(function(presetBlk, presetId) {
      let { iconType = "", isDefault = false } = presetBlk
      let reqModification = weaponsTags?[presetId].reqModification ?? ""
      let weapons = []
      let preset = gatherSlotWeaponPreset(presetBlk)
      local mass = 0.0
      local massLbs = 0.0
      reqModifications[reqModification] <- true
      foreach(wData in preset) {
        let w = wData.__merge(loadBulletsCached(wData.blk, bulletsCache))
        if (wData.blk != w.blk) {
          w.totalBullets = w.guns * w.total
          w.weaponId = getWeaponId(w.blk)
        }
        weapons.append(w)
        mass += calcMass(w)
        massLbs += calcMassLbs(w)
      }
      let wRes = {
        name = presetId
        reqModification
        iconType
        isDefault = reqModification == "" && (isDefault || index == 0 || presetId.startswith("default"))
        weapons
        mass
        banPresets = getBanPresets(presetBlk)
      }
      if (massLbs > 0)
        wRes.massLbs <- massLbs
      return wRes
    })
    slots.append({ index, wPresets, wPresetsOrder = weaponSlotsOrder[index] })
  }
  slots.sort(@(a, b) a.index <=> b.index)

  if("" in reqModifications)
    reqModifications.$rawdelete("")

  fillBanAndMirrors(slots, slotsParams?.notUseForDisbalance)

  return res
}

function loadUnitBulletsAndSlots(realUnitName) {
  let unitName = getTagsUnitName(realUnitName)
  if (unitName not in fullCache) {
    if (isLoginRequired.get() && !isReadyToFullLoad.get())
      return { presets = {}, slots = [], slotsParams = {}, reqModifications = {} }
    fullCache[unitName] <- freeze(loadUnitBulletsFullImpl(unitName))
  }
  return fullCache[unitName]
}

let loadUnitBulletsFull = @(unitName) loadUnitBulletsAndSlots(unitName).presets
let loadUnitWeaponSlots = @(unitName) loadUnitBulletsAndSlots(unitName).slots
let loadUnitSlotsParams = @(unitName) loadUnitBulletsAndSlots(unitName).slotsParams
let loadUnitReqModifications = @(unitName) loadUnitBulletsAndSlots(unitName).reqModifications

function loadUnitBulletsChoiceImpl(unitName) {
  let { bullets = {}, bulletsOrder = [] } = getUnitTagsCfg(unitName)
  if (bullets.len() == 0)
    return {}
  let fullBullets = loadUnitBulletsFull(unitName)

  return fullBullets
    .map(@(preset)
      preset.map(function(data) {
        let { bulletSets, weaponId } = data
        let wbOrder = bulletsOrder?[weaponId] ?? []
        let wbOrderFull = wbOrder.contains("") ? wbOrder : [""].extend(wbOrder)
        let wBullets = bullets?[weaponId] ?? {}
        let sets = bulletSets.filter(@(_, id) id in wBullets || id == "")
        if (sets.len() == 0)
          return null
        return data.__merge({
          unitName
          fromUnitTags = wBullets,
          bulletSets = sets,
          bulletsOrder = wbOrderFull.filter(@(b) b in sets)
        })
      })
      .filter(@(d) d != null))
}

function loadUnitBulletsChoice(unitName) {
  if (unitName not in choiceCache)
    choiceCache[unitName] <- freeze(loadUnitBulletsChoiceImpl(unitName))
  return choiceCache[unitName]
}

return {
  loadUnitBulletsFull //include all bullets described in the unit blk
  loadUnitBulletsChoice //include only bullets described in the unittags
  loadUnitWeaponSlots
  loadUnitSlotsParams
  loadUnitBulletsAndSlots
  getWeaponId
  loadUnitReqModifications
}