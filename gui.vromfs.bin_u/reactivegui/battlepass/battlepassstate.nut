from "%globalsDarg/darg_library.nut" import *

let { register_command } = require("console")
let { eventbus_subscribe } = require("eventbus")
let { activeUnlocks, unlockInProgress, receiveUnlockRewards, buyUnlock, getUnlockPrice
} = require("%rGui/unlocks/unlocks.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { curSeasons } = require("%appGlobals/pServer/profileSeasons.nut")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { shopGoodsToRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { fillViewInfo, gatherUnlockStageInfo } = require("%rGui/battlePass/passStatePkg.nut")


let BP_GOODS_ID = "battle_pass"
let BP_PROGRESS_UNLOCK_ID = "battlepass_points_to_progress"

let BP_NONE = "none"
let BP_COMMON = "common"
let BP_VIP = "vip"

let BP_MAX_LEVELS_TO_ADD = 10

let bpPresentation = {
  [BP_NONE] = {
    name = @() ""
    icon = @(_) $"ui/gameuiskin#bp_icon_not_active.avif"
  },
  [BP_COMMON] = {
    name = @() loc("battlePass")
    icon = @(season) $"ui/gameuiskin#bp_icon_active_{season}.avif"
  },
  [BP_VIP] = {
    name = @() loc("battlePassVIP")
    icon = @(season) $"ui/gameuiskin#bp_icon_active_{season}_vip.avif"
  },
}
let getBpPresentation = @(bpType) bpPresentation?[bpType] ?? bpPresentation[BP_NONE]

let battlePassOpenCounter = mkWatched(persist, "battlePassOpenCounter", 0)
let isBPPurchaseWndOpened = mkWatched(persist, "isBPPurchaseWndOpened", false)
let debugBp = mkWatched(persist, "debugBp", null)
let tutorialFreeMarkIdx = Watched(null)
let openBattlePassWnd = @() battlePassOpenCounter.set(battlePassOpenCounter.get() + 1)
let closeBattlePassWnd = @() battlePassOpenCounter.set(0)

let seasonNumber = Computed(@() userstatStats.get()?.stats.season["$index"] ?? 0)
let seasonName = Computed(@() loc($"events/name/season_{seasonNumber.get()}"))
let seasonEndTime = Computed(@() userstatStats.get()?.stats.season["$endsAt"] ?? 0)

let bpProgressUnlock = Computed(@() activeUnlocks.get()?[BP_PROGRESS_UNLOCK_ID])
let pointsPerStage   = Computed(@() bpProgressUnlock.get()?.stages[0].progress ?? 1)
let bpLevelPrice = Computed(@() getUnlockPrice(bpProgressUnlock.get()))

let bpFreeRewardsUnlock = Computed(@()
  activeUnlocks.get().findvalue(@(unlock) "battle_pass_free" in unlock?.meta
    && unlock?.activity.start_index == seasonNumber.get()))
let bpPaidRewardsUnlock = Computed(@()
  activeUnlocks.get().findvalue(@(unlock) "battle_pass_paid" in unlock?.meta
    && unlock?.activity.start_index == seasonNumber.get()))
let bpPurchasedUnlock = Computed(@()
  activeUnlocks.get().findvalue(@(unlock) "battlepas_purchased" in unlock?.meta))

let isBpRewardsInProgress = Computed(@()
  bpFreeRewardsUnlock.get()?.name in unlockInProgress.get()
    || bpPaidRewardsUnlock.get()?.name in unlockInProgress.get()
    || bpPurchasedUnlock.get()?.name in unlockInProgress.get())

let battlePassGoods = Computed(@() {
  [BP_COMMON] = shopGoods.get()?[BP_GOODS_ID],
  [BP_VIP] = shopGoods.get().findvalue(@(s) "battle_pass_vip" in s?.meta)
})

let isBpPurchasedByType = Computed(function() {
  let { purchasesCount = null } = servProfile.get()
  let seasons = curSeasons.get()
  return battlePassGoods.get().map(function(goods) {
    if (goods == null)
      return null

    let { oncePerSeason = "", id } = goods
    let { count = 0, lastTime = 0 } = purchasesCount?[id]
    if (oncePerSeason == "" || count <= 0)
      return count > 0

    let { start = 0, end = 0 } = seasons?[oncePerSeason]
    return lastTime != 0 && lastTime >= start && (end > 0 && lastTime <= end)
  })
})

let purchasedBpRaw = Computed(@() !isBpPurchasedByType.get()[BP_COMMON] ? BP_NONE
  : !isBpPurchasedByType.get()[BP_VIP] ? BP_COMMON
  : BP_VIP)
let purchasedBp = Computed(@() debugBp.get() ?? purchasedBpRaw.get())

let isBpActive = Computed(@() debugBp.get() == null
  ? (activeUnlocks.get()?[bpPaidRewardsUnlock.get()?.requirement].isCompleted ?? false)
  : debugBp.get() != BP_NONE)

purchasedBp.subscribe(@(_) isBPPurchaseWndOpened.set(false))

let hasBpRewardsToReceive = Computed(@() !!bpFreeRewardsUnlock.get()?.hasReward
  || !!bpPurchasedUnlock.get()?.hasReward
  || (isBpActive.get() && !!bpPaidRewardsUnlock.get()?.hasReward))

let pointsCurStage = Computed(@() (bpProgressUnlock.get()?.current ?? 0)
  % pointsPerStage.get() )
let curStage = Computed(@() bpProgressUnlock.get()?.stage ?? 0)
let maxStage = Computed(@() max(bpFreeRewardsUnlock.get()?.stages.top().progress ?? 0,
  bpPaidRewardsUnlock.get()?.stages.top().progress ?? 0))

let mkBpStagesList = @() Computed(function() {
  let listPaidStages = gatherUnlockStageInfo(bpPaidRewardsUnlock.get(), true, isBpActive.get(), curStage.get(), maxStage.get())
  let listFreeStages = gatherUnlockStageInfo(bpFreeRewardsUnlock.get(), false, true, curStage.get(), maxStage.get())

  let res = listPaidStages.extend(listFreeStages)
  let purchaseStages = gatherUnlockStageInfo(bpPurchasedUnlock.get(), true, true, curStage.get(), maxStage.get())
  if (purchaseStages.len() > 0) {
    let { isReceived, canReceive } = purchaseStages[0]
    res.insert(0, purchaseStages[0].__merge({
      progress = 0
      canBuyLevel = false
      canReceive = (debugBp.get() ?? BP_NONE) == BP_NONE ? canReceive
        : (!isReceived && !canReceive)
    }))
  }

  local addIdx = -1
  foreach(bpType in [BP_COMMON, BP_VIP]) {
    let goods = battlePassGoods.get()[bpType]
    if (goods == null)
      continue
    foreach(viewInfo in shopGoodsToRewardsViewInfo(goods))
      res.insert(0, {
        progress = addIdx--
        viewInfo
        isVip = bpType == BP_VIP
        isPaid = true
        isReceived = isBpPurchasedByType.get()[bpType]
        canBuyLevel = 0
        canReceive = false
      })
  }

  res.sort(@(a, b) ((a?.loopMultiply ?? 0) == 0 || (b?.loopMultiply ?? 0) == 0)
    ? ((a?.progress ?? 0) <=> (b?.progress ?? 0))
    : (((b?.loopMultiply ?? 0) <=> (a?.loopMultiply ?? 0)) || ((a?.progress ?? 0) <=> (b?.progress ?? 0))))
  fillViewInfo(res, serverConfigs.get())
  return res
})

let selectedStage = mkWatched(persist, "bpSelectedStage", 0)

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
  return stage == null ? null : { unlockName = name, stage, finalStage }
}

function receiveBpRewardsImpl(toReceive) {
  if (toReceive.len() == 0)
    return
  let { unlockName, stage, finalStage = null } = toReceive[0]
  receiveUnlockRewards(unlockName, stage,
    { finalStage, onSuccessCb = { id = "battlePass.grantMultiRewards", nextReceive = toReceive.slice(1) } })
}

eventbus_subscribe("battlePass.grantMultiRewards", @(msg) receiveBpRewardsImpl(msg.nextReceive))

let sendBpBqEvent = @(action, params = {}) sendCustomBqEvent("battlepass_1", params.__merge({
  action
  name = $"season_{seasonNumber.get()}"
  stageProgress = curStage.get()
  battlepassPoints = pointsCurStage.get()
  isPassPurchased = isBpActive.get()
}))

function receiveBpRewards(progress) {
  if (isBpRewardsInProgress.get())
    return

  let fullList = [
    !bpPurchasedUnlock.get()?.hasReward ? null
      : { unlockName = bpPurchasedUnlock.get().name, stage = bpPurchasedUnlock.get().stage }
    getNotReceivedInfo(bpFreeRewardsUnlock.get(), progress)
    isBpActive.get() ? getNotReceivedInfo(bpPaidRewardsUnlock.get(), progress) : null
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

function buyBPLevel() {
  let price = bpLevelPrice.get()
  if ((bpProgressUnlock.get()?.periodic == true || !bpProgressUnlock.get()?.isCompleted ) && price.price > 0) {
    buyUnlock(BP_PROGRESS_UNLOCK_ID, curStage.get() + 1, price.currency, price.price,
      { onSuccessCb = { id = "battlePass.buyUnlock" }})
  }
}

eventbus_subscribe("battlePass.buyUnlock", function(_) {
  sendBpBqEvent("buy_level", {
    paramInt1 = curStage.get() + 1
  })
  receiveBpRewards(curStage.get() + 1)
})


isBPPurchaseWndOpened.subscribe(@(v) v ? sendBpBqEvent("bp_purchase_open") : null)

let dbgOrder = [BP_NONE, BP_COMMON, BP_VIP]
register_command(
  function() {
    let cur = debugBp.get() ?? purchasedBpRaw.get()
    let idx = (dbgOrder.indexof(cur) ?? -1) + 1
    let new = dbgOrder[idx % dbgOrder.len()]
    debugBp.set(new == purchasedBpRaw.get() ? null : new)
    log($"New purchased BP = {purchasedBp.get()}. (isReal = {purchasedBp.get() == purchasedBpRaw.get()})")
  },
  "ui.debug.battlePass")

return {
  battlePassOpenCounter
  openBattlePassWnd
  closeBattlePassWnd
  isBPPurchaseWndOpened
  openBPPurchaseWnd = @() isBPPurchaseWndOpened.set(true)
  closeBPPurchaseWnd = @() isBPPurchaseWndOpened.set(false)
  receiveBpRewards
  sendBpBqEvent
  buyBPLevel

  bpFreeRewardsUnlock
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
  purchasedBp
  pointsCurStage
  bpProgressUnlock
  pointsPerStage
  bpLevelPrice
  isBPLevelPurchaseInProgress = Computed(@() unlockInProgress.get().len() > 0)
  BP_PROGRESS_UNLOCK_ID
  BP_MAX_LEVELS_TO_ADD

  seasonNumber
  seasonName
  seasonEndTime
  hasBpRewardsToReceive

  tutorialFreeMarkIdx

  getBpIcon = @(bpType, season) getBpPresentation(bpType).icon(season)
  getBpName = @(bpType) getBpPresentation(bpType).name()

  BP_NONE
  BP_COMMON
  BP_VIP
}