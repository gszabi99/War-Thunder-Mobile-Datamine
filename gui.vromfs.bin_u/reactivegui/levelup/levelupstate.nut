from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { levelup_without_unit } = require("%appGlobals/pServer/pServerApi.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { campConfigs, receivedLevelsRewards, receivedLvlRewards, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { buyUnitsData } = require("%appGlobals/unitsState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInMenu, isInDebriefing, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { WP, balanceWp } = require("%appGlobals/currenciesState.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { openUnitsTreeAtCurRank, isUnitsTreeOpen } = require("%rGui/unitsTree/unitsTreeState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let LVL_UP_ANIM = 2.2

let isSeen = hardPersistWatched("isLevelUpSeen", false) // To show it after login once.
let isLvlUpOpened = mkWatched(persist, "isOpened", false)
let isRewardsModalOpen = mkWatched(persist, "isRewardsModalOpen", false)
let failedRewardsLevelStr = mkWatched(persist, "failedRewardsLevelStr", {})
let upgradeUnitName = mkWatched(persist, "upgradeUnitName", null)

let openLvlUpWnd = @() isLvlUpOpened.set(true)
let openLvlUpAfterDelay = @() resetTimeout(LVL_UP_ANIM, openLvlUpWnd)
let openRewardsModal = @() isRewardsModalOpen.set(true)

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
  let receivedOld = receivedLevelsRewards.get() //compatibility with 2024.04.14
  let received = receivedLvlRewards.get()
  let failed = failedRewardsLevelStr.value
  let res = {}
  foreach (lvlStr, reward in (campConfigs.value?.playerLevelRewards ?? {}))
    if (lvlStr not in received && lvlStr not in receivedOld && lvlStr not in failed && lvlStr.tointeger() <= level)
      res[lvlStr.tointeger()] <- reward
  return res
})

let hasDataForLevelWnd = Computed(@() playerLevelInfo.value.isReadyForLevelUp || rewardsToReceive.value.len() > 0)
hasDataForLevelWnd.subscribe(function(v) {
  if (v)
    return
  isSeen(false)
  isRewardsModalOpen.set(false)
  isLvlUpOpened.set(false)
})

let needOpenLevelUpWnd = keepref(Computed(@() hasDataForLevelWnd.value
  && !isSeen.value
  && isLoggedIn.value
  && isInMenu.value
  && !isInDebriefing.value
  && !hasModalWindows.value))

function openLvlUpWndIfCan() {
  if (hasDataForLevelWnd.value) {
    if (!isUnitsTreeOpen.get())
      openUnitsTreeAtCurRank()
    if (rewardsToReceive.get().len() > 0)
      openRewardsModal()
    else if (curCampaign.get() not in serverConfigs.get()?.unitTreeNodes)
      openLvlUpWnd()
    else
      levelup_without_unit(curCampaign.value)
  }
  return hasDataForLevelWnd.value
}

function onNeedOpenLevelUpWnd() {
  if (!needOpenLevelUpWnd.get())
    return

  if (needOpenLevelUpWnd.value) {
    openUnitsTreeAtCurRank()
    if (rewardsToReceive.get().len() > 0)
      openRewardsModal()
    else
      openLvlUpWndIfCan()
  }
}

needOpenLevelUpWnd.subscribe(@(_) deferOnce(onNeedOpenLevelUpWnd))

let needAutoLevelUp = keepref(Computed(@() hasDataForLevelWnd.value
  && rewardsToReceive.value.len() == 0
  && buyUnitsData.value.canBuyOnLvlUp.len() == 0
  && !isInBattle.value))

let skipLevelUpUnitPurchase = @() levelup_without_unit(curCampaign.value)

function onNeedAutoLevelUp(need) {
  if (need)
    skipLevelUpUnitPurchase()
}
onNeedAutoLevelUp(needAutoLevelUp.value)
needAutoLevelUp.subscribe(onNeedAutoLevelUp)

let lvlUpCost = Computed(function() {
  let { costGold, nextLevelExp, exp } = playerLevelInfo.value
  let expLeft = nextLevelExp - exp
  return nextLevelExp
    ? max(1, (min(1.0, expLeft.tofloat() / nextLevelExp) * costGold + 0.5).tointeger())
    : null
})

let isLvlUpAnimated = Watched(false)
function startLvlUpAnimation() {
  isLvlUpAnimated.set(true)
  resetTimeout(LVL_UP_ANIM, @() isLvlUpAnimated.set(false))
}

return {
  isLvlUpOpened
  openLvlUpWndIfCan
  openLvlUpAfterDelay
  closeLvlUpWnd = @() isLvlUpOpened.set(false)

  isRewardsModalOpen
  openRewardsModal
  closeRewardsModal = @() isRewardsModalOpen.set(false)

  maxRewardLevelInfo
  rewardsToReceive
  failedRewardsLevelStr
  upgradeUnitName
  skipLevelUpUnitPurchase
  lvlUpCost
  hasDataForLevelWnd
  isSeen

  isLvlUpAnimated
  startLvlUpAnimation
}
