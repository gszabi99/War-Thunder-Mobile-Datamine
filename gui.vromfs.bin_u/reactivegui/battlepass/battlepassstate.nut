from "%globalsDarg/darg_library.nut" import *
let { activeUnlocks, unlockProgress } = require("%rGui/unlocks/unlocks.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")

let isBattlePassWndOpened = mkWatched(persist, "isBattlePassWndOpened", false)
let openBattlePassWnd = @() isBattlePassWndOpened(true)
let closeBattlePassWnd = @() isBattlePassWndOpened(false)

let seasonNumber = Computed(@() userstatStats.value?.stats.season["$index"] ?? 0)
let seasonName = Computed(@() loc($"events/name/season_{seasonNumber.value}"))
let seasonEndTime = Computed(@() userstatStats.value?.stats.season["$endsAt"] ?? 0)

let bpProgressUnlock = Computed(@() activeUnlocks.value?["battlepass_points_to_progress"])
let pointsPerStage   = Computed(@() bpProgressUnlock.value?.stages[0].progress ?? 1)

let bfFreeRewardsUnlock = Computed(@()
  activeUnlocks.value?[$"battlepass_free_season_{seasonNumber.value}"])

let bpPaidRewardsUnlock = Computed(@()
  activeUnlocks.value?[$"battlepass_paid_season_{seasonNumber.value}"])

let nameBPSeasonPurchased = Computed(@() $"purchased_battlepas_{seasonNumber.value}")

let isActiveBP = Computed(@() unlockProgress.value?[nameBPSeasonPurchased.value].isCompleted)

let pointsCurStage = Computed(@() (bpProgressUnlock.value?.current ?? 0)
  % pointsPerStage.value )
let curStage = Computed(@() bpProgressUnlock.value?.stage ?? 0)

let listStages = Computed(function(){
  let listPaidRewards = (bpPaidRewardsUnlock.value?.stages ?? [])
    .map(@(reward) reward.__merge({
      unlockName = bpPaidRewardsUnlock.value.name
      isPaid = true
    }))
  let listFreeRewards = (bfFreeRewardsUnlock.value?.stages ?? [])
    .map(@(reward) reward.__merge({
      unlockName = bfFreeRewardsUnlock.value.name
      isPaid = false
    }))
  let res = listPaidRewards
    .extend(listFreeRewards)
    .sort(@(a,b) (a?.progress ?? 0) <=> (b?.progress ?? 0));
  return res
})

return {
  isBattlePassWndOpened
  openBattlePassWnd
  closeBattlePassWnd

  listStages
  curStage
  isActiveBP
  pointsCurStage
  bpProgressUnlock
  pointsPerStage

  seasonNumber
  seasonName
  seasonEndTime
}