from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { eventbus_subscribe } = require("eventbus")
let { isEqual } = require("%sqstd/underscore.nut")
let { activeUnlocks, receiveUnlockRewards, unlockInProgress, getRelativeStageData
} = require("%rGui/unlocks/unlocks.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let { deferOnce } = require("dagor.workcycle")
let { isAdsAvailable, showAdsForReward } = require("%rGui/ads/adsState.nut")
let { completeAnimDelay, moveCardsFullTime, moveCardsHalfTime, FULL_DAYS
} = require("loginAwardPlaces.nut")
let { delayUnseedPurchaseShow } = require("%rGui/shop/unseenPurchasesState.nut")
let { userstatRegisterExecutor } = require("userstat.nut")
let { hasVip } = require("%rGui/state/profilePremium.nut")

let showUnseenAfterAnimDelay = 0.2

const LOGIN_UNLOCK_ID = "every_day_award"
let loginAwardUnlock = Computed(@() activeUnlocks.value?[LOGIN_UNLOCK_ID])
let isLoginAwardOpened = mkWatched(persist, "isLoginAwardOpened", false)
let needShowLoginAwardWnd = keepref(Computed(@() (loginAwardUnlock.value?.hasReward ?? false)
  && isInMenuNoModals.value))

function getStageReward(unlock) {
  let { stages, stage } = getRelativeStageData(unlock)
  let total = stages.len()
  return stages?[(total + stage - 1) % total].rewards
}

let loginAwardUnlockByAds = Computed(function() {
  if (!isAdsAvailable.value)
    return null
  let baseUnlock = loginAwardUnlock.value
  if (baseUnlock == null || baseUnlock.hasReward)
    return null 
  let lastReward = getStageReward(baseUnlock)
  return activeUnlocks.value.findvalue(@(u) (u?.meta.loginAwardByAds ?? false)
    && u.hasReward
    && isEqual(getStageReward(u), lastReward))
})

let openWnd = @() needShowLoginAwardWnd.value ? isLoginAwardOpened(true) : null
needShowLoginAwardWnd.subscribe(@(v) v ? deferOnce(openWnd) : null)

function delayUnseenAfterReward(stage) {
  local time = completeAnimDelay + showUnseenAfterAnimDelay
  if ((stage % FULL_DAYS) == 0)
    time += isAdsAvailable.value && !loginAwardUnlock.value?.hasReward ? 0 : moveCardsFullTime
  else if ((stage % (FULL_DAYS / 2)) == 0)
    time += moveCardsHalfTime
  delayUnseedPurchaseShow(time)
}

function delayUnseenAfterAds(stage) {
  if ((stage % FULL_DAYS) == 0)
    delayUnseedPurchaseShow(moveCardsFullTime + showUnseenAfterAnimDelay)
}

userstatRegisterExecutor("lAward.onReceiveRewardCb", function(result, context) {
  let { stage } = context
  if ("error" not in result)
    delayUnseenAfterReward(stage)
})

function receiveLoginAward() {
  if (!loginAwardUnlock.value?.hasReward)
    return
  let stage = loginAwardUnlock.get().lastRewardedStage + 1
  delayUnseedPurchaseShow(completeAnimDelay + showUnseenAfterAnimDelay) 
  receiveUnlockRewards(LOGIN_UNLOCK_ID, stage, { executeBefore = "lAward.onReceiveRewardCb", stage })
}

function showLoginAwardAds() {
  if (!loginAwardUnlockByAds.value)
    return

  let stage = loginAwardUnlockByAds.value.lastRewardedStage + 1
  if(hasVip.get()) {
    let { name = null } = loginAwardUnlockByAds.get()
    let mainUnlockStage = loginAwardUnlock.get().lastRewardedStage
    delayUnseenAfterAds(mainUnlockStage)
    receiveUnlockRewards(name, stage, { executeBefore = "lAward.onReceiveAdsRewardCb", mainUnlockStage })
    return
  }
  showAdsForReward({
    loginUnlockId = loginAwardUnlockByAds.value.name
    stage
    bqId = $"repeat_login_reward"
    bqParams = {
      paramInt1 = stage
      details = $"stage {stage}"
    }
  })
}

userstatRegisterExecutor("lAward.onReceiveAdsRewardCb", function(result, context) {
  let { mainUnlockStage } = context
  if ("error" not in result)
    delayUnseenAfterAds(mainUnlockStage)
})

eventbus_subscribe("adsRewardApply", function(data) {
  let { loginUnlockId = null } = data
  let { name = null } = loginAwardUnlockByAds.value
  if (loginUnlockId == null || loginUnlockId != name)
    return
  let stage = loginAwardUnlockByAds.value.lastRewardedStage + 1
  let mainUnlockStage = loginAwardUnlock.value.lastRewardedStage
  delayUnseenAfterAds(mainUnlockStage) 
  receiveUnlockRewards(name, stage, { executeBefore = "lAward.onReceiveAdsRewardCb", mainUnlockStage })
})

eventbus_subscribe("adsShowFinish", function(data) {
  if (data?.loginUnlockId != null)
    delayUnseenAfterAds(loginAwardUnlock.value?.lastRewardedStage ?? 1)
})

register_command(@() isLoginAwardOpened(!isLoginAwardOpened.value), "ui.openLoginAwardWnd")

return {
  loginAwardUnlock
  isLoginAwardOpened
  canShowLoginAwards = Computed(@() loginAwardUnlock.value != null)
  receiveLoginAward
  isLoginAwardInProgress = Computed(@() LOGIN_UNLOCK_ID in unlockInProgress.value
    || loginAwardUnlockByAds.value?.name in unlockInProgress.value)
  hasLoginAwardByAds = Computed(@() loginAwardUnlockByAds.value != null)
  showLoginAwardAds
}