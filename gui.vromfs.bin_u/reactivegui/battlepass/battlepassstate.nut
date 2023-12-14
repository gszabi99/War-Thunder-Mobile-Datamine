from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { subscribe } = require("eventbus")
let { activeUnlocks, unlockRewardsInProgress, receiveUnlockRewards
} = require("%rGui/unlocks/unlocks.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")

let BP_GOODS_ID = "battle_pass"

let isBattlePassWndOpened = mkWatched(persist, "isBattlePassWndOpened", false)
let isBPPurchaseWndOpened = mkWatched(persist, "isBPPurchaseWndOpened", false)
let isDebugBp = mkWatched(persist, "isDebugBp", false)
let openBattlePassWnd = @() isBattlePassWndOpened(true)
let closeBattlePassWnd = @() isBattlePassWndOpened(false)

let seasonNumber = Computed(@() userstatStats.value?.stats.season["$index"] ?? 0)
let seasonName = Computed(@() loc($"events/name/season_{seasonNumber.value}"))
let seasonEndTime = Computed(@() userstatStats.value?.stats.season["$endsAt"] ?? 0)

let bpProgressUnlock = Computed(@() activeUnlocks.value?["battlepass_points_to_progress"])
let pointsPerStage   = Computed(@() bpProgressUnlock.value?.stages[0].progress ?? 1)

let bfFreeRewardsUnlock = Computed(@()
  activeUnlocks.value.findvalue(@(unlock) "battle_pass_free" in unlock?.meta))
let bpPaidRewardsUnlock = Computed(@()
  activeUnlocks.value.findvalue(@(unlock) "battle_pass_paid" in unlock?.meta))
let bpPurchasedUnlock = Computed(@()
  activeUnlocks.value.findvalue(@(unlock) "battlepas_purchased" in unlock?.meta))

let isBpRewardsInProgress = Computed(@()
  bfFreeRewardsUnlock.value?.name in unlockRewardsInProgress.value
    || bpPaidRewardsUnlock.value?.name in unlockRewardsInProgress.value
    || bpPurchasedUnlock.value?.name in unlockRewardsInProgress.value)

let battlePassGoods = Computed(@() shopGoods.value?[BP_GOODS_ID])

let isBpPurchased = Computed(@()
  (battlePassGoods.value != null
    && (servProfile.value?.purchasesCount[BP_GOODS_ID].count ?? 0) > 0)
  != isDebugBp.value)
let isBpActive = Computed(@()
  (activeUnlocks.value?[bpPaidRewardsUnlock.value?.requirement].isCompleted ?? false)
    != isDebugBp.value)

isBpActive.subscribe(@(v) v ? isBPPurchaseWndOpened.set(false) : null)

let hasBpRewardsToReceive = Computed(@() !!bfFreeRewardsUnlock.get()?.hasReward
  || !!bpPurchasedUnlock.get()?.hasReward
  || (isBpActive.get() && !!bpPaidRewardsUnlock.get()?.hasReward))

let pointsCurStage = Computed(@() (bpProgressUnlock.value?.current ?? 0)
  % pointsPerStage.value )
let curStage = Computed(@() bpProgressUnlock.value?.stage ?? 0)

let function gatherUnlockStageInfo(unlock, isPaid, isActive, curStageV) {
  let { name = "", stages = [], lastRewardedStage = -1, hasReward = false } = unlock
  return stages.map(function(stage, idx) {
    let { progress = 0 } = stage
    let isReceived = idx < lastRewardedStage
    return {
      progress
      rewards = stage?.rewards ?? {}
      unlockName = name
      isPaid
      isReceived
      canReceive = !isReceived && isActive && hasReward && curStageV > progress - 1
    }
  })
}

let mkBpStagesList = @() Computed(function() {
  let listPaidStages = gatherUnlockStageInfo(bpPaidRewardsUnlock.value, true, isBpActive.value, curStage.value)
  let listFreeStages = gatherUnlockStageInfo(bfFreeRewardsUnlock.value, false, true, curStage.value)

  let res = listPaidStages.extend(listFreeStages)
  let purchaseStages = gatherUnlockStageInfo(bpPurchasedUnlock.value, true, true, curStage.value)
  if (purchaseStages.len() > 0) {
    let { isReceived, canReceive } = purchaseStages[0]
    res.insert(0, purchaseStages[0].__merge({
      progress = 0
      canReceive = !isDebugBp.value ? canReceive
        : (!isReceived && !canReceive)
    }))
  }

  return res.sort(@(a,b) (a?.progress ?? 0) <=> (b?.progress ?? 0))
})

let selectedStage = mkWatched(persist, "bpSelectedStage", 0)

let function getNotReceivedInfo(unlock, maxProgress) {
  let { stages = [], name = "", lastRewardedStage = 0 } = unlock
  local stage = null
  local finalStage = null
  for (local s = max(lastRewardedStage, 0); s < stages.len(); s++) {
    let { progress = null } = stages[s]
    if (progress == null || progress > maxProgress)
      break
    finalStage = s + 1
    stage = stage ?? (s + 1)
  }
  if (stage == null)
    return null
  return { unlockName = name, stage, finalStage }
}

let function receiveBpRewardsImpl(toReceive) {
  if (toReceive.len() == 0)
    return
  let { unlockName, stage, finalStage = null } = toReceive[0]
  receiveUnlockRewards(unlockName, stage,
    { finalStage, onSuccessCb = { id = "battlePass.grantMultiRewards", nextReceive = toReceive.slice(1) } })
}

subscribe("battlePass.grantMultiRewards", @(msg) receiveBpRewardsImpl(msg.nextReceive))

let sendBpBqEvent = @(action, params = {}) sendCustomBqEvent("battlepass_1", params.__merge({
  action
  name = $"season_{seasonNumber.get()}"
  stageProgress = curStage.get()
  battlepassPoints = pointsCurStage.get()
  isPassPurchased = isBpActive.get()
}))

let function receiveBpRewards(progress) {
  if (isBpRewardsInProgress.value)
    return

  let fullList = [
    !bpPurchasedUnlock.value?.hasReward ? null
      : { unlockName = bpPurchasedUnlock.value.name, stage = bpPurchasedUnlock.value.stage }
    getNotReceivedInfo(bfFreeRewardsUnlock.value, progress)
    isBpActive.value ? getNotReceivedInfo(bpPaidRewardsUnlock.value, progress) : null
  ].filter(@(v) v != null)

  if (fullList.len() == 0)
    return

  let total = fullList.reduce(@(res, c) res + c.finalStage - c.stage + 1, 0)
  sendBpBqEvent("receive_rewards", {
    paramInt1 = progress,
    paramInt2 = total
  })
  receiveBpRewardsImpl(fullList)
}

isBPPurchaseWndOpened.subscribe(@(v) v ? sendBpBqEvent("bp_purchase_open") : null)

register_command(@() isDebugBp.set(!isDebugBp.get()), "ui.debug.battlePass")

return {
  isBattlePassWndOpened
  openBattlePassWnd
  closeBattlePassWnd
  isBPPurchaseWndOpened
  openBPPurchaseWnd = @() isBPPurchaseWndOpened(true)
  closeBPPurchaseWnd = @() isBPPurchaseWndOpened(false)
  receiveBpRewards
  sendBpBqEvent

  bfFreeRewardsUnlock
  bpPaidRewardsUnlock
  bpPurchasedUnlock
  battlePassGoods
  isBpRewardsInProgress

  mkBpStagesList
  curStage
  selectedStage
  isBpActive
  isBpPurchased
  pointsCurStage
  bpProgressUnlock
  pointsPerStage

  seasonNumber
  seasonName
  seasonEndTime
  hasBpRewardsToReceive
}