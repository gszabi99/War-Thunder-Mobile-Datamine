from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { subscribe } = require("eventbus")
let { activeUnlocks, unlockInProgress, receiveUnlockRewards, buyUnlock, getUnlockPrice
} = require("%rGui/unlocks/unlocks.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { curSeasons } = require("%appGlobals/pServer/profileSeasons.nut")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { eventSeason } = require("%rGui/event/eventState.nut")

let BP_GOODS_ID = "battle_pass"
let BP_PROGRESS_UNLOCK_ID = "battlepass_points_to_progress"

let battlePassOpenCounter = mkWatched(persist, "battlePassOpenCounter", 0)
let isBPPurchaseWndOpened = mkWatched(persist, "isBPPurchaseWndOpened", false)
let isDebugBp = mkWatched(persist, "isDebugBp", false)
let openBattlePassWnd = @() battlePassOpenCounter.set(battlePassOpenCounter.get() + 1)
let closeBattlePassWnd = @() battlePassOpenCounter.set(0)

let seasonNumber = Computed(@() userstatStats.value?.stats.season["$index"] ?? 0)
let seasonName = Computed(@() loc($"events/name/season_{seasonNumber.value}"))
let seasonEndTime = Computed(@() userstatStats.value?.stats.season["$endsAt"] ?? 0)

let bpProgressUnlock = Computed(@() activeUnlocks.value?[BP_PROGRESS_UNLOCK_ID])
let pointsPerStage   = Computed(@() bpProgressUnlock.value?.stages[0].progress ?? 1)
let bpLevelPrice = Computed(@() getUnlockPrice(bpProgressUnlock.get()))
let bpIconActive = Computed(@() $"ui/gameuiskin#bp_icon_active_{eventSeason.get()}.avif")

let bpFreeRewardsUnlock = Computed(@()
  activeUnlocks.value.findvalue(@(unlock) "battle_pass_free" in unlock?.meta
    && unlock?.activity.start_index == seasonNumber.value))
let bpPaidRewardsUnlock = Computed(@()
  activeUnlocks.value.findvalue(@(unlock) "battle_pass_paid" in unlock?.meta
    && unlock?.activity.start_index == seasonNumber.value))
let bpPurchasedUnlock = Computed(@()
  activeUnlocks.value.findvalue(@(unlock) "battlepas_purchased" in unlock?.meta))

let isBpRewardsInProgress = Computed(@()
  bpFreeRewardsUnlock.value?.name in unlockInProgress.value
    || bpPaidRewardsUnlock.value?.name in unlockInProgress.value
    || bpPurchasedUnlock.value?.name in unlockInProgress.value)

let battlePassGoods = Computed(@() shopGoods.value?[BP_GOODS_ID])

let isBpPurchasedRaw = Computed(function() {
  let goods = battlePassGoods.get()
  if (goods == null)
    return false

  let { oncePerSeason = "" } = goods
  let { count = 0, lastTime = 0 } = servProfile.value?.purchasesCount[BP_GOODS_ID]
  if (oncePerSeason == "" || count <= 0)
    return count > 0

  let { start = 0, end = 0 } = curSeasons.get()?[oncePerSeason]
  return lastTime != 0 && start != 0 && lastTime >= start && lastTime <= end
})

let isBpPurchased = Computed(@() isBpPurchasedRaw.get() != isDebugBp.value)

let isBpActive = Computed(@()
  (activeUnlocks.value?[bpPaidRewardsUnlock.value?.requirement].isCompleted ?? false)
    != isDebugBp.value)

isBpActive.subscribe(@(v) v ? isBPPurchaseWndOpened.set(false) : null)

let hasBpRewardsToReceive = Computed(@() !!bpFreeRewardsUnlock.get()?.hasReward
  || !!bpPurchasedUnlock.get()?.hasReward
  || (isBpActive.get() && !!bpPaidRewardsUnlock.get()?.hasReward))

let pointsCurStage = Computed(@() (bpProgressUnlock.value?.current ?? 0)
  % pointsPerStage.value )
let curStage = Computed(@() bpProgressUnlock.value?.stage ?? 0)
let maxStage = Computed(@() max(bpFreeRewardsUnlock.get()?.stages.top().progress ?? 0,
  bpPaidRewardsUnlock.get()?.stages.top().progress ?? 0))

let function gatherUnlockStageInfo(unlock, isPaid, isActive, curStageV) {
  let { name = "", stages = [], lastRewardedStage = -1, hasReward = false } = unlock
  return stages.map(function(stage, idx) {
    let { progress = 0 } = stage
    let isReceived = idx < lastRewardedStage
    let canBuyLevel = (curStageV + 1) == progress
    return {
      progress
      rewards = stage?.rewards ?? {}
      unlockName = name
      isPaid
      isReceived
      canBuyLevel
      canReceive = !isReceived && isActive && hasReward && curStageV > progress - 1
    }
  })
}

let mkBpStagesList = @() Computed(function() {
  let listPaidStages = gatherUnlockStageInfo(bpPaidRewardsUnlock.value, true, isBpActive.value, curStage.value)
  let listFreeStages = gatherUnlockStageInfo(bpFreeRewardsUnlock.value, false, true, curStage.value)

  let res = listPaidStages.extend(listFreeStages)
  let purchaseStages = gatherUnlockStageInfo(bpPurchasedUnlock.value, true, true, curStage.value)
  if (purchaseStages.len() > 0) {
    let { isReceived, canReceive } = purchaseStages[0]
    res.insert(0, purchaseStages[0].__merge({
      progress = 0
      canBuyLevel = false
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
    getNotReceivedInfo(bpFreeRewardsUnlock.value, progress)
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

let function buyBPLevel() {
  let price = bpLevelPrice.get()
  if ((bpProgressUnlock.get()?.periodic == true || !bpProgressUnlock.get()?.isCompleted ) && price.price > 0) {
    buyUnlock(BP_PROGRESS_UNLOCK_ID, curStage.get() + 1, price.currency, price.price,
      { onSuccessCb = { id = "battlePass.buyUnlock" }})
  }
}

subscribe("battlePass.buyUnlock", function(_) {
  receiveBpRewards(curStage.get() + 1)
})


isBPPurchaseWndOpened.subscribe(@(v) v ? sendBpBqEvent("bp_purchase_open") : null)

register_command(@() isDebugBp.set(!isDebugBp.get()), "ui.debug.battlePass")

return {
  battlePassOpenCounter
  openBattlePassWnd
  closeBattlePassWnd
  isBPPurchaseWndOpened
  openBPPurchaseWnd = @() isBPPurchaseWndOpened(true)
  closeBPPurchaseWnd = @() isBPPurchaseWndOpened(false)
  receiveBpRewards
  sendBpBqEvent
  buyBPLevel

  bpPaidRewardsUnlock
  bpPurchasedUnlock
  battlePassGoods
  isBpRewardsInProgress
  isBpSeasonActive = Computed(@() bpFreeRewardsUnlock.get() != null)

  mkBpStagesList
  curStage
  maxStage
  selectedStage
  isBpActive
  isBpPurchased
  pointsCurStage
  bpProgressUnlock
  pointsPerStage
  bpLevelPrice
  bpIconActive
  isBPLevelPurchaseInProgress = Computed(@() unlockInProgress.get().len() > 0)
  BP_PROGRESS_UNLOCK_ID

  seasonNumber
  seasonName
  seasonEndTime
  hasBpRewardsToReceive
}