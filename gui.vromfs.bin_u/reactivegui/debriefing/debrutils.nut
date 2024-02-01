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
      res.isLastLevel = (idx + 1) not in levelsExp
      leftReceivedExp = leftReceivedExp - levelExp
    }
  }
  return res
}

function isPlayerReceiveLevel(debrData) {
  let { exp = 0, nextLevelExp = 0 } = debrData?.player
  let { totalExp = 0 } = debrData?.reward.playerExp
  return nextLevelExp != 0
    && nextLevelExp != exp // Checks player had no levelup available before this mission
    && exp + totalExp >= nextLevelExp
}

function isUnitReceiveLevel(debrData) {
  let { exp = 0, nextLevelExp = 0 } = debrData?.unit
  let { totalExp = 0 } = debrData?.reward.unitExp
  return nextLevelExp != 0
    && exp + totalExp >= nextLevelExp
}

function getNewPlatoonUnit(debrData) {
  let { unit = null, reward = null } = debrData
  if (unit == null)
    return null
  let { level = 0, exp = 0, levelsExp = [], lockedUnits = [] } = unit
  let { totalExp = 0 } = reward?.unitExp
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

return {
  getLevelProgress
  isPlayerReceiveLevel
  isUnitReceiveLevel
  getNewPlatoonUnit
}
