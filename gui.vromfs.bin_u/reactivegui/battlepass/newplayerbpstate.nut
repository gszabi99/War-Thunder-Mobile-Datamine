from "%globalsDarg/darg_library.nut" import *
let { campaignActiveUnlocks, unlockInProgress, batchReceiveRewards } = require("%rGui/unlocks/unlocks.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { fillViewInfo, gatherUnlockStageInfo } = require("%rGui/battlePass/passStatePkg.nut")
let { curCampaign, getCampaignStatsId } = require("%appGlobals/pServer/campaign.nut")
let { userstatStatsTables } = require("%rGui/unlocks/userstat.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")

let isNPWndOpened = mkWatched(persist, "newPlayerBpSceneisNPWndOpened", false)

let curStatsCampaign = Computed(@() getCampaignStatsId(curCampaign.get()))

let npBpFreeRewardsUnlock = Computed(@()
  campaignActiveUnlocks.get().findvalue(@(unlock) "new_player_pass_free" in unlock?.meta))
let npBpPaidRewardsUnlock = Computed(@()
  campaignActiveUnlocks.get().findvalue(@(unlock) "new_player_pass_paid" in unlock?.meta))
let npPurchasedUnlock = Computed(@()
  campaignActiveUnlocks.get().findvalue(@(unlock) "new_player_pass_purchased" in unlock?.meta))
let winsCount = Computed(@() npBpFreeRewardsUnlock.get()?.current ?? 0)

let isNPActive = Computed(@() campaignActiveUnlocks.get()?[npBpPaidRewardsUnlock.get()?.requirement].isCompleted ?? false)
let isNPSeasonActive = Computed(@() npBpFreeRewardsUnlock.get() != null)

let seasonEndTime = Computed(@() userstatStatsTables.get()?.stats[npBpFreeRewardsUnlock.get()?.table]["$endsAt"] ?? 0)

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
}

let npPassGoods = Computed(@() shopGoods.get()?[$"new_player_pass_{curStatsCampaign.get()}"])

return {
  curStatsCampaign
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
  seasonEndTime
}