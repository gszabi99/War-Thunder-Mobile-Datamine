from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { levelup_without_unit } = require("%appGlobals/pServer/pServerApi.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { campConfigs, receivedLevelsRewards, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { buyUnitsData } = require("%appGlobals/unitsState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInMenu, isInDebriefing, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { WP, balanceWp } = require("%appGlobals/currenciesState.nut")
let { getUnitAnyPrice } = require("%appGlobals/unitUtils.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")

let isSeen = hardPersistWatched("isLevelUpSeen", false) // To show it after login once.
let isLvlUpOpened = mkWatched(persist, "isOpened", false)
let failedRewardsLevelStr = mkWatched(persist, "failedRewardsLevelStr", {})
let upgradeUnitName = mkWatched(persist, "upgradeUnitName", null)

isLvlUpOpened.subscribe(@(v) v ? isSeen(true) : null)
isInDebriefing.subscribe(function(v) {
  if (!v)
    return
  failedRewardsLevelStr({}) //try to receive faile rewards again. Maybe there was a connection error or something like that

  local hasBalanceForLevelUpUnit = false
  foreach(unit in buyUnitsData.value.canBuyOnLvlUp) {
    let { currencyId = null, price = 0 } = getUnitAnyPrice(unit, true, unitDiscounts.value)
    if (currencyId != WP || price > balanceWp.value)
      continue
    hasBalanceForLevelUpUnit = true
    break
  }
  if (hasBalanceForLevelUpUnit)
    isSeen(false)
})
isLvlUpOpened.subscribe(@(_) upgradeUnitName(null))

let maxRewardLevelInfo = Computed(function(prev) {
  let { level, starLevel, isReadyForLevelUp, isStarProgress = false } = playerLevelInfo.value
  let res = {
    level = level + (isReadyForLevelUp ? 1 : 0)
    starLevel = !isReadyForLevelUp ? starLevel
      : isStarProgress ? starLevel + 1
      : 0
  }
  return isEqual(prev, res) ? prev : res
})

let rewardsToReceive = Computed(function() {
  let level = maxRewardLevelInfo.value.level
  let received = receivedLevelsRewards.value
  let failed = failedRewardsLevelStr.value
  let res = {}
  foreach (lvlStr, reward in (campConfigs.value?.playerLevelRewards ?? {}))
    if (lvlStr not in received && lvlStr not in failed && lvlStr.tointeger() <= level)
      res[lvlStr.tointeger()] <- reward
  return res
})

let hasDataForLevelWnd = Computed(@() playerLevelInfo.value.isReadyForLevelUp || rewardsToReceive.value.len() > 0)
hasDataForLevelWnd.subscribe(function(v) {
  if (v)
    return
  isSeen(false)
  isLvlUpOpened(false)
})

let needOpenLevelUpWnd = keepref(Computed(@() hasDataForLevelWnd.value
  && !isSeen.value
  && isLoggedIn.value && isInMenu.value && !isInDebriefing.value && !hasModalWindows.value))

needOpenLevelUpWnd.subscribe(function(val) {
  if (!val)
    return
  resetTimeout(0.1, function() {
    if (needOpenLevelUpWnd.value)
      isLvlUpOpened(true)
  })
})

let needAutoLevelUp = keepref(Computed(@() hasDataForLevelWnd.value
  && rewardsToReceive.value.len() == 0
  && buyUnitsData.value.canBuyOnLvlUp.len() == 0
  && !isInBattle.value))

let skipLevelUpUnitPurchase = @() levelup_without_unit(curCampaign.value)

let function onNeedAutoLevelUp(need) {
  if (need)
    skipLevelUpUnitPurchase()
}
onNeedAutoLevelUp(needAutoLevelUp.value)
needAutoLevelUp.subscribe(onNeedAutoLevelUp)

let function openLvlUpWndIfCan() {
  if (hasDataForLevelWnd.value)
    isLvlUpOpened(true)
  return hasDataForLevelWnd.value
}

return {
  maxRewardLevelInfo
  isLvlUpOpened
  rewardsToReceive
  failedRewardsLevelStr
  upgradeUnitName
  closeLvlUpWnd = @() isLvlUpOpened(false)
  openLvlUpWndIfCan
  skipLevelUpUnitPurchase
}
