from "%globalsDarg/darg_library.nut" import *

function getLevelProgress(curLevelConfig, reward) {
  let { exp = 0, level = 1, nextLevelExp = 0, isLastLevel = false, levelsExp = [] } = curLevelConfig
  let res = {
    prevLevel = level
    unlockedLevel = level
    isLastLevel
  }
  if (nextLevelExp == 0)
    return res
  let { totalExp = 0 } = reward
  // For campaign level and tutorial mission unit level
  let addExp = clamp(totalExp, 0, max(0, nextLevelExp - exp))
  let isLevelUp = addExp > 0 && nextLevelExp <= (exp + totalExp)
  if (isLevelUp)
    res.unlockedLevel++
  // For multiplayer mission unit levels
  if (isLevelUp && levelsExp.len() > 0) {
    local leftReceivedExp = totalExp - addExp
    foreach (idx, levelExp in levelsExp) {
      if (leftReceivedExp <= 0)
        break
      if (idx <= level)
        continue
      res.unlockedLevel = idx
      res.isLastLevel = isLastLevel || (idx + 1) not in levelsExp
      leftReceivedExp = leftReceivedExp - levelExp
    }
  }
  return res
}

let isDebrWithUnitsResearch = @(debrData) debrData?.isResearchCampaign ?? false

function isPlayerReceiveLevel(debrData) {
  if (isDebrWithUnitsResearch(debrData))
    return false // No rewards for campaign levels in campaigns with researches
  let { exp = 0, nextLevelExp = 0 } = debrData?.player
  let { totalExp = 0 } = debrData?.reward.playerExp
  return nextLevelExp != 0
    && nextLevelExp != exp // Checks player had no levelup available before this mission
    && exp + totalExp >= nextLevelExp
}

function getResearchedUnit(debrData) {
  if (!isDebrWithUnitsResearch(debrData))
    return null
  let { exp = 0, reqExp = 0, unit = null } = debrData?.researchingUnit
  let { totalExp = 0 } = debrData?.reward.playerExp
  return reqExp > 0 && totalExp > 0 && (exp + totalExp) >= reqExp ? unit : null
}

let getBestUnitName = @(debrData) (debrData?.isSeparateSlots ?? false)
  ? (debrData?.reward.unitName ?? "")
  : (debrData?.unit.name ?? "")

function getUnitsSet(debrData) {
  let { unit = null } = debrData
  if (unit == null)
    return []
  if (!debrData?.isSeparateSlots)
    return [ unit ]
  // In campaigns with separate slots, slotbar units set imitates a single unit with "platoonUnits" set.
  return [ unit.__merge({ platoonUnits = [] }) ].extend(unit?.platoonUnits ?? [])
}

function getUnit(unitName, debrData) {
  let { unit = null } = debrData
  if (unitName == null || unit == null)
    return null
  if (!debrData?.isSeparateSlots)
    return unit?.name == unitName ? unit : null
  // In campaigns with separate slots, slotbar units set imitates a single unit with "platoonUnits" set.
  let unitsList = [ unit ].extend(unit?.platoonUnits ?? [])
  return unitsList.findvalue(@(u) u?.name == unitName)?.__merge({ platoonUnits = [] })
}

function getUnitRewards(unitName, debrData) {
  if (unitName == null)
    return {}
  if (debrData?.reward.unitExp != null && unitName == getBestUnitName(debrData))
    return { name = unitName, exp = debrData.reward.unitExp } // Compatibility with dedicated pre-1.8.0
  return (debrData?.reward.units ?? []).findvalue(@(v) v?.name == unitName) ?? {}
}

function isUnitReceiveLevel(unitName, debrData) {
  let { exp = 0, nextLevelExp = 0 } = getUnit(unitName, debrData)
  let { totalExp = 0 } = getUnitRewards(unitName, debrData)?.exp
  return nextLevelExp != 0
    && exp + totalExp >= nextLevelExp
}

function getNewPlatoonUnit(unitName, debrData) {
  if (debrData?.isSeparateSlots ?? false)
    return null // No platoons in campaigns with separate slots.
  let unit = getUnit(unitName, debrData)
  if (unit == null)
    return null
  let { level = 0, exp = 0, levelsExp = [], lockedUnits = [] } = unit
  let { totalExp = 0 } = getUnitRewards(unitName, debrData)?.exp
  if (totalExp == 0 || lockedUnits.len() == 0)
    return null
  local pReqLevel = -1
  local pUnitName = null
  foreach (pUnit in lockedUnits) {
    let { reqLevel = 0, name } = pUnit
    if (reqLevel > level && (pUnitName == null || reqLevel < pReqLevel)) {
      pReqLevel = reqLevel
      pUnitName = name
    }
  }
  if (pUnitName == null || levelsExp.len() < pReqLevel)
    return null

  local leftExp = totalExp + exp
  for (local l = level; l < pReqLevel; l++)
    leftExp -= levelsExp[l]
  return leftExp >= 0 ? unit.__merge({ name = pUnitName }) : null
}

let sortUnitMods = @(a, b) (a?.reqLevel ?? 0) <=> (b?.reqLevel ?? 0)
  || (a?.group ?? "") <=> (b?.group ?? "")
  || (a?.costGold ?? 0) <=> (b?.costGold ?? 0)
  || (a?.costWpWeight ?? 0) <=> (b?.costWpWeight ?? 0)
  || (a?.name ?? "") <=> (b?.name ?? "")

return {
  getLevelProgress

  isPlayerReceiveLevel
  getResearchedUnit

  isDebrWithUnitsResearch
  getBestUnitName
  getUnitsSet
  getUnit
  getUnitRewards
  isUnitReceiveLevel
  getNewPlatoonUnit

  sortUnitMods
}
