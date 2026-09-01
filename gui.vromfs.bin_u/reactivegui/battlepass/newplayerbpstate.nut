from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/bqClient.nut" import sendCustomBqEvent
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/battlePass/passStatePkg.nut" import fillViewInfo, gatherUnlockStageInfo
from "%rGui/shop/shopState.nut" import shopGoods
from "%rGui/unlocks/unlocks.nut" import campaignActiveUnlocks, unlockInProgress, batchReceiveRewards, unseenUnlocks,
  setLastSeenUnlocks
from "%rGui/unlocks/userstat.nut" import userstatStatsTables


let isNPWndOpened = mkWatched(persist, "newPlayerBpSceneisNPWndOpened", false)

let npBpFreeRewardsUnlock = Computed(@()
  campaignActiveUnlocks.get().findvalue(@(unlock) "new_player_pass_free" in unlock?.meta))
let npBpPaidRewardsUnlock = Computed(@()
  campaignActiveUnlocks.get().findvalue(@(unlock) "new_player_pass_paid" in unlock?.meta))
let npPurchasedUnlock = Computed(@()
  campaignActiveUnlocks.get().findvalue(@(unlock) "new_player_pass_purchased" in unlock?.meta))
let winsCount = Computed(@() npBpFreeRewardsUnlock.get()?.current ?? 0)

let isNPActive = Computed(@() campaignActiveUnlocks.get()?[npBpPaidRewardsUnlock.get()?.requirement].isCompleted ?? false)
let isNPSeasonActive = Computed(@() npBpFreeRewardsUnlock.get() != null)

let nbpSeasonEndTime = Computed(@() userstatStatsTables.get()?.stats[npBpFreeRewardsUnlock.get()?.table]["$endsAt"] ?? 0)

let mkNPPaidStageList = Computed(function() {
  let res = gatherUnlockStageInfo(npBpPaidRewardsUnlock.get(), true, isNPActive.get(), winsCount.get())
  fillViewInfo(res, serverConfigs.get())
  return res
})

let mkNPFreeStageList = Computed(function() {
  let res = gatherUnlockStageInfo(npBpFreeRewardsUnlock.get(), false, true, winsCount.get())
  fillViewInfo(res, serverConfigs.get())
  return res
})

let isNPRewardsInProgress = Computed(@()
  npBpFreeRewardsUnlock.get()?.name in unlockInProgress.get()
    || npBpPaidRewardsUnlock.get()?.name in unlockInProgress.get()
    || npPurchasedUnlock.get()?.name in unlockInProgress.get())

let selectedStage = mkWatched(persist, "NPSelectedStage", 0)

let hasNpBpRewardsToReceive = Computed(@() !!npBpFreeRewardsUnlock.get()?.hasReward
  || !!npPurchasedUnlock.get()?.hasReward
  || (isNPActive.get() && !!npBpPaidRewardsUnlock.get()?.hasReward))

function getNotReceivedInfo(unlock, maxProgress) {
  let { stages = [], name = "", lastRewardedStage = 0, periodic = false, startStageLoop = 1 } = unlock
  local stage = null
  local finalStage = null
  for (local s = max(lastRewardedStage, 0); s < stages.len(); s++) {
    let { progress = null } = stages[s]
    if (progress == null || progress > maxProgress)
      break
    finalStage = s + 1
    stage = stage ?? (s + 1)
  }
  if (periodic) {
    let { progress = null } = stages.findvalue(@(_, s) s + 1 == startStageLoop)
    if (progress != null) {
      let diff = maxProgress - progress
      for (local s = max(finalStage ?? 0, lastRewardedStage); s < stages.len() + diff; s++) {
        finalStage = s + 1
        stage = stage ?? (s + 1)
      }
    }
  }
  return stage == null ? null : { unlock = name, stage, finalStage }
}

let sendNpBqEvent = @(action, params = {}) sendCustomBqEvent("newbie_battlepass_1", params.__merge({
  action
  stageProgress = winsCount.get()
  isPassPurchased = isNPActive.get()
  campaign = curCampaign.get()
}))

function receiveNPRewards(progress) {
  if (isNPRewardsInProgress.get())
    return

  let fullList = [
    !npPurchasedUnlock.get()?.hasReward ? null
      : { unlock = npPurchasedUnlock.get().name, stage = npPurchasedUnlock.get().stage }
    getNotReceivedInfo(npBpFreeRewardsUnlock.get(), progress)
    isNPActive.get() ? getNotReceivedInfo(npBpPaidRewardsUnlock.get(), progress) : null
  ].filter(@(v) v != null)

  if (fullList.len() == 0)
    return

  batchReceiveRewards(fullList.map(@(c) { unlock = c.unlock, up_to_stage = c?.finalStage ?? c.stage }))

  let total = fullList.reduce(@(res, c) res + c.finalStage - c.stage + 1, 0)
  sendNpBqEvent("receive_rewards", {
    paramInt1 = progress
    paramInt2 = total
  })
}

let npPassGoods = Computed(@() shopGoods.get()?[$"new_player_pass_{curCampaign.get()}"])
let hasUnseenNpPass = Computed(@() npBpFreeRewardsUnlock.get()?.name in unseenUnlocks.get()
  || npBpPaidRewardsUnlock.get()?.name in unseenUnlocks.get())

isNPWndOpened.subscribe(@(v) !v
  ? setLastSeenUnlocks([npBpFreeRewardsUnlock.get()?.name, npBpPaidRewardsUnlock.get()?.name].filter(@(id) id != null))
  : null)

return {
  isNPWndOpened
  mkNPPaidStageList
  mkNPFreeStageList

  winsCount
  selectedStage
  receiveNPRewards
  isNPRewardsInProgress
  isNPActive

  openNPWnd = @() isNPWndOpened.set(true)
  closeNPWnd = @() isNPWndOpened.set(false)
  isNPSeasonActive
  npPassGoods
  nbpSeasonEndTime
  sendNpBqEvent
  hasNpBpRewardsToReceive
  hasUnseenNpPass
}