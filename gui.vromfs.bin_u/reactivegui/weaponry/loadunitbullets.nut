from "%globalsDarg/darg_library.nut" import *
let { getUnitFileName } = require("vehicleModel")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { blkOptFromPath } = require("%sqStdLibs/helpers/datablockUtils.nut")
let { eachBlock, isDataBlock } = require("%sqstd/datablock.nut")

let WT_GUNS = "guns"
let WT_SMOKE = "smoke"
let WT_COUNTERMEASURES = "countermeasures"
let WT_FLARES = "flares"
let WT_AAM = "aam" // Air-to-Air Missiles
let WT_AGM = "agm" // Air-to-Ground Missile, Anti-Tank Guided Missiles
let WT_ROCKETS = "rockets"


let fullCache = persist("fullCache", @() {})
let choiceCache = {}
let blkToWeaponId = {}

let function getWeaponIdImpl(blkPath) {
  local start = 0
  local searchFrom = 0
  while (searchFrom != null) {
    searchFrom = blkPath.indexof("/", searchFrom + 1) ?? blkPath.indexof("\\", searchFrom + 1)
    if (searchFrom != null)
      start = searchFrom + 1
  }
  local end = blkPath.indexof(".", start) ?? blkPath.len()
  return blkPath.slice(start, end)
}

let function getWeaponId(blkPath) {
  if (blkPath not in blkToWeaponId)
    blkToWeaponId[blkPath] <- getWeaponIdImpl(blkPath)
  return blkToWeaponId[blkPath]
}

let function gatherWeaponsFromBlk(weaponsBlk) {
  let res = {}
  foreach (wBlk in (weaponsBlk % "Weapon")) {
    let { dummy = false, blk = null, triggerGroup = "primary", bullets = 0 } = wBlk
    if (dummy || blk == null)
      continue
    if (triggerGroup not in res)
      res[triggerGroup] <- {}
    if (blk not in res[triggerGroup])
      res[triggerGroup][blk] <- { totalBullets = 0, guns = 0, weaponId = getWeaponId(blk) }
    res[triggerGroup][blk].totalBullets += bullets
    res[triggerGroup][blk].guns++
  }
  return res
}

let function loadBullets(bulletsBlk, id, weaponBlkName, isBulletBelt) {
  if (bulletsBlk.paramCount() == 0 && bulletsBlk.blockCount() == 0)
    return null

  local bulletsList = bulletsBlk % "bullet"
  local weaponType = WT_GUNS
  if (bulletsList.len() == 0) {
    bulletsList = bulletsBlk % "rocket"
    if (bulletsList.len() == 0)
      return null

    let rocket = bulletsList[0]
    if (rocket?.smokeShell == true)
      weaponType = WT_SMOKE
    else if ((rocket?.isFlare == true) || (rocket?.isChaff == true))
      weaponType = WT_COUNTERMEASURES
    else if (rocket?.smokeShell == false)
      weaponType = WT_FLARES
    else if (rocket?.operated == true || rocket?.guidanceType != null)
      weaponType = (rocket?.bulletType == "atgm_tank") ? WT_AGM : WT_AAM
    else
      weaponType = WT_ROCKETS
  }

  local res = null
  foreach (b in bulletsList) {
    let paramsBlk = isDataBlock(b?.rocket) ? b.rocket : b
    if (res == null)
      if (!paramsBlk?.caliber)
        continue
      else
        res = {
          id
          weaponBlkName
          weaponType
          caliber = 1000.0 * paramsBlk.caliber
          bullets = []
          bulletNames = []
          bulletDataByType = {}
          isBulletBelt = isBulletBelt && weaponType == WT_GUNS
        }

    let bulletType = b?.bulletType ?? b.getBlockName()
    let bulletTypeFull = (paramsBlk?.selfDestructionInAir ?? false) ? $"{bulletType}@s_d" : bulletType
    res.bullets.append(bulletTypeFull)
    res.bulletDataByType[bulletType] <- {}

    if (paramsBlk?.guiCustomIcon != null) {
      if (res?.customIconsMap == null)
        res.customIconsMap <- {}
      res.customIconsMap[bulletTypeFull] <- paramsBlk.guiCustomIcon
    }

    if ("bulletName" in b)
      res.bulletNames.append(b.bulletName)

    foreach (param in ["explosiveType", "explosiveMass", "explodeTreshold", "speed", "ricochetPreset"])
      if (param in paramsBlk) {
        res[param] <- paramsBlk[param]
        res.bulletDataByType[bulletType][param] <- paramsBlk[param]
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

  if (res.bulletNames.len() > 1 && res.bulletNames.findvalue(@(v) v != res.bulletNames[0]) == null) {
    res.mass <- bulletsList[0]?.mass ?? 0.0
    res.isUniform <- true
  }
  else if (res.bulletNames.len() == 1)
    res.mass <- bulletsList[0]?.mass ?? 0.0

  return res
}

let function loadAllBullets(weaponBlkName) {
  let weaponBlk = blkOptFromPath(weaponBlkName)
  let { bullets = 0, bulletsCartridge = 1, useSingleIconForBullet = false } = weaponBlk
  let isBulletBelt = !useSingleIconForBullet
    && ((weaponBlk?.isBulletBelt ?? false) || bulletsCartridge > 1)

  let res = {
    catridge = bulletsCartridge
    total = bullets
    bulletSets = {}
  }
  let defBullets = loadBullets(weaponBlk, "", weaponBlkName, isBulletBelt)
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

let function loadBulletsCached(weaponBlkName, cache) {
  if (weaponBlkName not in cache)
    cache[weaponBlkName] <- loadAllBullets(weaponBlkName)
  return cache[weaponBlkName]
}

let function loadUnitBulletsFullImpl(unitName) {
  let triggersData = {}
  let unitBlk = blkOptFromPath(getUnitFileName(unitName))
  let { commonWeapons = null, weapon_presets = null } = unitBlk
  if (isDataBlock(commonWeapons))
    triggersData.commonWeapons <- gatherWeaponsFromBlk(commonWeapons)

  if (isDataBlock(weapon_presets))
    eachBlock(weapon_presets, function(b) {
      let { name = "", blk = null } = b
      triggersData[name] <- gatherWeaponsFromBlk(blkOptFromPath(blk))
    })

  let bulletsCache = {}
  let res = triggersData.map(@(presetTriggers)
    presetTriggers.map(function(triggerWeapons) {
      let bulletSets = {}
      local weaponId = ""
      local guns = 0
      local catridge = 1
      local total = 0
      foreach (wBlkName, wData in triggerWeapons) {
        let bulletsData = loadBulletsCached(wBlkName, bulletsCache)
        if (bulletSets.len() == 0) {
          weaponId = wData.weaponId
          catridge = bulletsData.catridge
        }
        guns += wData.guns
        total += wData.totalBullets
        bulletSets.__update(bulletsData?.bulletSets)
      }
      return { weaponId, bulletSets, catridge, guns, total }
    }))

  return res
}

let function loadUnitBulletsFull(unitName) {
  if (unitName not in fullCache)
    fullCache[unitName] <- freeze(loadUnitBulletsFullImpl(unitName))
  return fullCache[unitName]
}

let function loadUnitBulletsChoiceImpl(unitName) {
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

let function loadUnitBulletsChoice(unitName) {
  if (unitName not in choiceCache)
    choiceCache[unitName] <- freeze(loadUnitBulletsChoiceImpl(unitName))
  return choiceCache[unitName]
}

return {
  loadUnitBulletsFull //include all bullets described in the unit blk
  loadUnitBulletsChoice //include only bullets described in the unittags
  getWeaponId
}