from "%globalsDarg/darg_library.nut" import *

let isExperienceWndOpen = Watched(false)

function openExpWnd() {
  isExperienceWndOpen.set(true)
}

function canPurchaseLevelUp(playerLevelInfoV, buyUnitsDataV, unreleasedUnitsV) {
  let { nextLevelExp = 0, isMaxLevel = true } = playerLevelInfoV
  if (nextLevelExp == 0 || isMaxLevel)
    return false

  let { canBuyOnLvlUp } = buyUnitsDataV
  let unreleased = canBuyOnLvlUp.filter(@(_, name) name not in unreleasedUnitsV)
  return canBuyOnLvlUp.len() == 0 || unreleased.len() > 0
}

return {
  openExpWnd
  isExperienceWndOpen
  canPurchaseLevelUp
}