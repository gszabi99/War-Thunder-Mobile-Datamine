from "%globalsDarg/darg_library.nut" import *

function getLevelProgress(curLevelConfig, totalExp) {
  let { exp = 0, level = 1, nextLevelExp = 0, isLastLevel = false, levelsExp = [], levelsExpCfg = null
  } = curLevelConfig
  let res = {
    prevLevel = level
    unlockedLevel = level
    isLastLevel
  }
  if (nextLevelExp == 0)
    return res

  
  let addExp = clamp(totalExp, 0, max(0, nextLevelExp - exp))
  let isLevelUp = addExp > 0 && nextLevelExp <= (exp + totalExp)
  if (!isLevelUp)
    return res

  res.unlockedLevel++
  local leftExp = totalExp - addExp
  if (levelsExpCfg == null) { 
    if (levelsExp.len() == 0)
      return res
    foreach (idx, levelExp in levelsExp) {
      if (idx <= level)
        continue
      res.unlockedLevel = idx
      res.isLastLevel = isLastLevel || (idx + 1) not in levelsExp
      leftExp -= levelExp
      if (leftExp <= 0)
        break
    }
    return res
  }

  local fromLevel = level
  foreach (idx, c in levelsExpCfg) {
    if (c.upToLevel <= fromLevel)
      continue
    let leftLevels = c.upToLevel - res.unlockedLevel
    if (leftLevels <= 0)
      continue
    let applyLevels = min(leftExp / c.exp, leftLevels)
    res.unlockedLevel += applyLevels
    leftExp -= applyLevels * c.exp
    if (applyLevels < leftLevels)
      break
    res.isLastLevel = isLastLevel || (idx + 1) not in levelsExpCfg
    fromLevel = c.upToLevel
  }

  return res
}

function getResearchedUnit(debrData) {
  let { exp = 0, reqExp = 0, unit = null } = debrData?.researchingUnit
  let { totalExp = 0 } = debrData?.reward.playerExp
  return reqExp > 0 && totalExp > 0 && (exp + totalExp) >= reqExp ? unit : null
}

let getBestUnitName = @(debrData) debrData?.reward.unitName ?? ""

function getUnitsSet(debrData) {
  let { unit = null } = debrData
  if (unit == null)
    return []
  
  return [ unit.__merge({ platoonUnits = [] }) ].extend(unit?.platoonUnits ?? [])
}

function getBgUnits(debrData) {
  let unitSpawnsListWithExp = (debrData?.damageLogPlayers[debrData?.userId.tostring()].unitSpawnsList ?? {})
    .map(@(_, uName) debrData?.reward.units.findvalue(@(u) u.name == uName).exp.totalExp ?? 0)
  return getUnitsSet(debrData)
    .sort(@(a, b) (unitSpawnsListWithExp?[b.name] ?? -1) <=> (unitSpawnsListWithExp?[a.name] ?? -1)
      || b.mRank <=> a.mRank)
    .map(@(u) u.name)
    .slice(0, 4)
}

function getUnit(unitName, debrData) {
  let { unit = null } = debrData
  if (unitName == null || unit == null)
    return null
  
  let unitsList = [ unit ].extend(unit?.platoonUnits ?? [])
  return unitsList.findvalue(@(u) u?.name == unitName)?.__merge({ platoonUnits = [] })
}

function getUnitRewards(unitName, debrData) {
  if (unitName == null)
    return {}
  if (debrData?.reward.unitExp != null && unitName == getBestUnitName(debrData))
    return { name = unitName, exp = debrData.reward.unitExp } 
  return (debrData?.reward.units ?? []).findvalue(@(v) v?.name == unitName) ?? {}
}

function getSlotExpByUnit(unitName, debrData) {
  let { exp = {}, slotExp = {} } = getUnitRewards(unitName, debrData)
  return slotExp.len() > 0 ? slotExp
    : exp.__merge({
        baseExp = (exp?.baseExp ?? 0)
        totalExp = (exp?.totalExp ?? 0)
      })
}

function isUnitReceiveLevel(unitName, debrData) {
  let { exp = 0, nextLevelExp = 0 } = getUnit(unitName, debrData)
  let { totalExp = 0 } = getUnitRewards(unitName, debrData)?.exp
  return nextLevelExp != 0
    && exp + totalExp >= nextLevelExp
}

function isSlotReceiveLevel(unitName, debrData) {
  let { exp = 0, nextLevelExp = 0 } = getUnit(unitName, debrData)?.slot
  let { totalExp = 0 } = getSlotExpByUnit(unitName, debrData)
  return nextLevelExp != 0
    && exp + totalExp >= nextLevelExp
}

function getSlotLevelCfg(unit, debrData) {
  let { slot = {}, slotIdx = 0, name = "" } = unit
  let { levelsExp = [], levelsExpCfg = null } = debrData?.slots 
  return slot.__merge({ levelsExp, levelsExpCfg, slotIdx, name, isSlot = true })
}

function getNextUnitLevelWithRewards(levelMin, levelMax, modPresetCfg, unitWeaponryCfg, campaign) {
  let { weaponPresets = {}, ammoForWeapons = {} } = unitWeaponryCfg
  for (local l = levelMin; l <= levelMax; l++) {
    let modId = modPresetCfg.findindex(@(v) v?.reqLevel == l)
    if (modId != null && (campaign != "air" || weaponPresets.findvalue(@(wp) wp?.reqModification == modId) != null))
      return l
    foreach (weapon in ammoForWeapons) {
      let { fromUnitTags = {} } = weapon
      if (fromUnitTags.findvalue(@(b) (modId != null && b?.reqModification == modId) || b?.reqLevel == l) != null)
        return l
    }
  }
  return -1
}

function getSlotOrUnitLevelUnlockRewards(debrData) {
  let units = getUnitsSet(debrData)
  foreach (unit in units) {
    let { slot = {}, name = "", slotIdx = 0 } = unit
    let { nextLevelExp = 0, level = 0 } = slot
    let isSlotMaxLevel = nextLevelExp == 0
    if (!isSlotMaxLevel && isSlotReceiveLevel(name, debrData))
      return { has = true, type = "crew", idx = slotIdx, name, levelBeforeBattle = level }
  }
  foreach (unit in units) {
    let { unitWeaponry = {}, campaign = "" } = debrData
    let { nextLevelExp = 0, name = "", level = 0, slotIdx = 0, modPresetCfg = {} } = unit
    let isUnitMaxLevel = nextLevelExp == 0
    if (isUnitMaxLevel || !isUnitReceiveLevel(name, debrData))
      continue
    let { unlockedLevel } = getLevelProgress(unit, getUnitRewards(name, debrData)?.exp.totalExp ?? 0)
    if (getNextUnitLevelWithRewards(level + 1, unlockedLevel, modPresetCfg, unitWeaponry?[name], campaign) > level)
      return { has = true, type = "arsenal", idx = slotIdx, name }
  }
  return { has = false }
}

let sortUnitMods = @(a, b) (a?.reqLevel ?? 0) <=> (b?.reqLevel ?? 0)
  || (a?.group ?? "") <=> (b?.group ?? "")
  || (a?.costGold ?? 0) <=> (b?.costGold ?? 0)
  || (a?.name ?? "") <=> (b?.name ?? "")

return {
  getLevelProgress

  getResearchedUnit

  getBestUnitName
  getBgUnits
  getUnitsSet
  getUnit
  getUnitRewards
  getSlotExpByUnit
  isUnitReceiveLevel
  isSlotReceiveLevel
  getSlotLevelCfg
  getNextUnitLevelWithRewards
  getSlotOrUnitLevelUnlockRewards

  sortUnitMods
}
