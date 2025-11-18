from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { levelup_without_unit, levelInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { campConfigs, receivedLvlRewards,
  curCampaign, isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { buyUnitsData } = require("%appGlobals/unitsState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInDebriefing, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { WP, balanceWp } = require("%appGlobals/currenciesState.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { openUnitsTreeAtCurRank, isUnitsTreeOpen } = require("%rGui/unitsTree/unitsTreeState.nut")

let LVL_UP_ANIM = 2.2

let isSeen = hardPersistWatched("isLevelUpSeen", false) 
let isLvlUpOpened = mkWatched(persist, "isOpened", false)
let isRewardsModalOpen = mkWatched(persist, "isRewardsModalOpen", false)
let failedRewardsLevelStr = mkWatched(persist, "failedRewardsLevelStr", {})
let upgradeUnitName = mkWatched(persist, "upgradeUnitName", null)

let openLvlUpWnd = @() isLvlUpOpened.set(true)
let openRewardsModal = @() isRewardsModalOpen.set(true)

isLvlUpOpened.subscribe(@(v) v ? isSeen.set(true) : null)
isInDebriefing.subscribe(function(v) {
  if (!v)
    return
  failedRewardsLevelStr.set({}) 

  local hasBalanceForLevelUpUnit = false
  foreach(unit in buyUnitsData.get().canBuyOnLvlUp) {
    let { currencyId = null, price = 0 } = getUnitAnyPrice(unit, true, unitDiscounts.get())
    if (currencyId != WP || price > balanceWp.get())
      continue
    hasBalanceForLevelUpUnit = true
    break
  }
  if (hasBalanceForLevelUpUnit)
    isSeen.set(false)
})
isLvlUpOpened.subscribe(@(_) upgradeUnitName.set(null))

let maxRewardLevelInfo = Computed(function(prev) {
  let { level, starLevel, isReadyForLevelUp, isStarProgress = false } = playerLevelInfo.get()
  let res = {
    level = level + (isReadyForLevelUp ? 1 : 0)
    starLevel = !isReadyForLevelUp ? starLevel
      : isStarProgress ? starLevel + 1
      : 0
  }
  return isEqual(prev, res) ? prev : res
})

let rewardsToReceive = Computed(function() {
  let level = maxRewardLevelInfo.get().level
  let received = receivedLvlRewards.get()
  let failed = failedRewardsLevelStr.get()
  let res = {}
  foreach (lvlStr, reward in (campConfigs.get()?.playerLevelRewards ?? {}))
    if (lvlStr not in received && lvlStr not in failed && lvlStr.tointeger() <= level)
      res[lvlStr.tointeger()] <- reward
  return res
})

let hasDataForLevelWnd = Computed(@() playerLevelInfo.get().isReadyForLevelUp || rewardsToReceive.get().len() > 0)
hasDataForLevelWnd.subscribe(function(v) {
  if (v)
    return
  isSeen.set(false)
  isRewardsModalOpen.set(false)
  isLvlUpOpened.set(false)
})

let needAutoLevelUp = keepref(Computed(@() !levelInProgress.get()
  && hasDataForLevelWnd.get()
  && rewardsToReceive.get().len() == 0
  && buyUnitsData.get().canBuyOnLvlUp.len() == 0
  && !isInBattle.get()))

function skipLevelUpUnitPurchase() {
  if (levelInProgress.get())
    return
  levelup_without_unit(curCampaign.get())
}

function onNeedAutoLevelUp() {
  if (needAutoLevelUp.get())
    skipLevelUpUnitPurchase()
}
onNeedAutoLevelUp()
needAutoLevelUp.subscribe(@(_) deferOnce(onNeedAutoLevelUp))

let needOpenLevelUpWnd = keepref(Computed(@() hasDataForLevelWnd.get()
  && !isSeen.get()
  && isLoggedIn.get()
  && isInMenuNoModals.get()
  && !isInDebriefing.get()))

function openLvlUpWndIfCan() {
  if (!hasDataForLevelWnd.get())
    return false

  if (needAutoLevelUp.get()) {
    deferOnce(onNeedAutoLevelUp)
    return true
  }

  if (!isUnitsTreeOpen.get() && !isCampaignWithUnitsResearch.get())
    openUnitsTreeAtCurRank()
  if (rewardsToReceive.get().len() > 0)
    openRewardsModal()
  else if (!isCampaignWithUnitsResearch.get())
    openLvlUpWnd()
  else if (!levelInProgress.get())
    levelup_without_unit(curCampaign.get())

  return true
}

let openLvlUpAfterDelay = @() resetTimeout(LVL_UP_ANIM, openLvlUpWndIfCan)

function onNeedOpenLevelUpWnd() {
  if (!needOpenLevelUpWnd.get())
    return

  if (needOpenLevelUpWnd.get()) {
    if(!isCampaignWithUnitsResearch.get())
      openUnitsTreeAtCurRank()
    if (rewardsToReceive.get().len() > 0)
      openRewardsModal()
    else
      openLvlUpWndIfCan()
  }
}

needOpenLevelUpWnd.subscribe(@(_) deferOnce(onNeedOpenLevelUpWnd))

let lvlUpCost = Computed(function() {
  let { costGold, nextLevelExp, exp } = playerLevelInfo.get()
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
