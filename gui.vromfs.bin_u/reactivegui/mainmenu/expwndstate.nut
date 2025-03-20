from "%globalsDarg/darg_library.nut" import *

let isExperienceWndOpen = Watched(false)

function openExpWnd() {
  isExperienceWndOpen(true)
}

function canPurchaseLevelUp(playerLevelInfoV, buyUnitsDataV, releasedUnitsV) {
  let { nextLevelExp = 0, isMaxLevel = true } = playerLevelInfoV
  if (nextLevelExp == 0 || isMaxLevel)
    return false

  let { canBuyOnLvlUp } = buyUnitsDataV
  let released = canBuyOnLvlUp.filter(@(_, name) name in releasedUnitsV)
  return canBuyOnLvlUp.len() == 0 || released.len() > 0
}

return {
  openExpWnd
  isExperienceWndOpen
  canPurchaseLevelUp
}