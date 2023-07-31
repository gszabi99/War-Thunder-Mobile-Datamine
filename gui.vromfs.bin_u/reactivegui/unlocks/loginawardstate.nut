from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { subscribe } = require("eventbus")
let { isEqual } = require("%sqstd/underscore.nut")
let { activeUnlocks, receiveUnlockRewards, unlockRewardsInProgress, getRelativeStageData
} = require("%rGui/unlocks/unlocks.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let { deferOnce } = require("dagor.workcycle")
let { isAdsAvailable, canShowAds, showAdsForReward } = require("%rGui/ads/adsState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { completeAnimDelay, moveCardsFullTime, moveCardsHalfTime, FULL_DAYS
} = require("loginAwardPlaces.nut")
let { delayUnseedPurchaseShow } = require("%rGui/shop/unseenPurchasesState.nut")
let { userstatRegisterExecutor } = require("userstat.nut")

let showUnseenAfterAnimDelay = 0.2

const LOGIN_UNLOCK_ID = "every_day_award"
let loginAwardUnlock = Computed(@() activeUnlocks.value?[LOGIN_UNLOCK_ID])
let isLoginAwardOpened = mkWatched(persist, "isLoginAwardOpened", false)
let needShowLoginAwardWnd = keepref(Computed(@() (loginAwardUnlock.value?.hasReward ?? false)
  && isInMenuNoModals.value))

let function getStageReward(unlock) {
  let { stages, stage } = getRelativeStageData(unlock)
  let total = stages.len()
  return stages?[(total + stage - 1) % total].rewards
}

let loginAwardUnlockByAds = Computed(function() {
  if (!isAdsAvailable.value)
    return null
  let baseUnlock = loginAwardUnlock.value
  if (baseUnlock == null || baseUnlock.hasReward)
    return null //no ads reward till we got final reward
  let lastReward = getStageReward(baseUnlock)
  return activeUnlocks.value.findvalue(@(u) (u?.meta.loginAwardByAds ?? false)
    && u.hasReward
    && isEqual(getStageReward(u), lastReward))
})

let openWnd = @() needShowLoginAwardWnd.value ? isLoginAwardOpened(true) : null
needShowLoginAwardWnd.subscribe(@(v) v ? deferOnce(openWnd) : null)

let function delayUnseenAfterReward(stage) {
  local time = completeAnimDelay + showUnseenAfterAnimDelay
  if ((stage % FULL_DAYS) == 0)
    time += isAdsAvailable.value && !loginAwardUnlock.value?.hasReward ? 0 : moveCardsFullTime
  else if ((stage % (FULL_DAYS / 2)) == 0)
    time += moveCardsHalfTime
  delayUnseedPurchaseShow(time)
}

let function delayUnseenAfterAds(stage) {
  if ((stage % FULL_DAYS) == 0)
    delayUnseedPurchaseShow(moveCardsFullTime + showUnseenAfterAnimDelay)
}

userstatRegisterExecutor("lAward.onReceiveRewardCb", function(result, context) {
  let { stage } = context
  if ("error" not in result)
    delayUnseenAfterReward(stage)
})

let function receiveLoginAward() {
  if (!loginAwardUnlock.value?.hasReward)
    return
  let stage = loginAwardUnlock.value.lastRewardedStage + 1
  delayUnseedPurchaseShow(completeAnimDelay + showUnseenAfterAnimDelay) //if receive rewards from pServer before userstat cb
  receiveUnlockRewards(LOGIN_UNLOCK_ID, stage, { executeBefore = "lAward.onReceiveRewardCb", stage })
}

let function showLoginAwardAds() {
  if (!loginAwardUnlockByAds.value)
    return
  if (!canShowAds.value) {
    openMsgBox({ text = loc("msg/adsNotReadyYet") })
    return
  }

  let stage = loginAwardUnlockByAds.value.lastRewardedStage + 1
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

subscribe("adsRewardApply", function(data) {
  let { loginUnlockId = null } = data
  let { name = null } = loginAwardUnlockByAds.value
  if (loginUnlockId == null || loginUnlockId != name)
    return
  let stage = loginAwardUnlockByAds.value.lastRewardedStage + 1
  let mainUnlockStage = loginAwardUnlock.value.lastRewardedStage
  delayUnseenAfterAds(mainUnlockStage) //if receive rewards from pServer before userstat cb
  receiveUnlockRewards(name, stage, { executeBefore = "lAward.onReceiveAdsRewardCb", mainUnlockStage })
})

subscribe("adsShowFinish", function(data) {
  if (data?.loginUnlockId != null)
    delayUnseenAfterAds(loginAwardUnlock.value?.lastRewardedStage ?? 1)
})

register_command(@() isLoginAwardOpened(!isLoginAwardOpened.value), "ui.openLoginAwardWnd")

return {
  loginAwardUnlock
  isLoginAwardOpened
  canShowLoginAwards = Computed(@() loginAwardUnlock.value != null)
  receiveLoginAward
  isLoginAwardInProgress = Computed(@() LOGIN_UNLOCK_ID in unlockRewardsInProgress.value
    || loginAwardUnlockByAds.value?.name in unlockRewardsInProgress.value)
  hasLoginAwardByAds = Computed(@() loginAwardUnlockByAds.value != null)
  showLoginAwardAds
}