from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "eventbus" import eventbus_subscribe
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/pServer/bqClient.nut" import sendCustomBqEvent
from "%appGlobals/pServer/profileSeasons.nut" import curSeasons
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/battlePass/passStatePkg.nut" import fillViewInfo, gatherUnlockStageInfo
from "%rGui/rewards/rewardViewInfo.nut" import shopGoodsToRewardsViewInfo
from "%rGui/shop/shopState.nut" import shopGoods
from "%rGui/unlocks/unlocks.nut" import activeUnlocks, unlockInProgress, batchReceiveRewards, buyUnlock, getUnlockPrice
from "%rGui/unlocks/userstat.nut" import userstatStatsTables


const BP_GOODS_ID = "battle_pass"
const BP_PROGRESS_UNLOCK_ID = "battlepass_points_to_progress"

const BP_NONE = "none"
const BP_COMMON = "common"
const BP_VIP = "vip"

const BP_MAX_LEVELS_TO_ADD = 10

let bpPresentation = {
  [BP_NONE] = {
    name = @() ""
    icon = @(_) $"ui/gameuiskin#bp_icon_not_active.avif"
  },
  [BP_COMMON] = {
    name = @() loc("battlePass")
    icon = @(season) season != "" ? $"ui/gameuiskin#bp_icon_active_{season}.avif"
      : $"ui/gameuiskin#bp_icon_not_active.avif"
  },
  [BP_VIP] = {
    name = @() loc("battlePassVIP")
    icon = @(season) season != "" ? $"ui/gameuiskin#bp_icon_active_{season}_vip.avif"
      : $"ui/gameuiskin#bp_icon_not_active.avif"
  },
}
let getBpPresentation = @(bpType) bpPresentation?[bpType] ?? bpPresentation[BP_NONE]

let battlePassOpenCounter = mkWatched(persist, "battlePassOpenCounter", 0)
let isBPPurchaseWndOpened = mkWatched(persist, "isBPPurchaseWndOpened", false)
let debugBp = mkWatched(persist, "debugBp", null)
let tutorialFreeMarkIdx = Watched(null)

let bpSeasonNumber = Computed(@() userstatStatsTables.get()?.stats.season["$index"] ?? -1)
let bpSeasonName = Computed(@() bpSeasonNumber.get() <= 0 ? loc("events/name/default")
  : loc($"events/name/season_{bpSeasonNumber.get()}"))
let bpSeasonEndTime = Computed(@() userstatStatsTables.get()?.stats.season["$endsAt"] ?? 0)

let bpProgressUnlock = Computed(@() activeUnlocks.get()?[BP_PROGRESS_UNLOCK_ID])
let pointsPerStage   = Computed(@() bpProgressUnlock.get()?.stages[0].progress ?? 1)
let bpLevelPrice = Computed(@() getUnlockPrice(bpProgressUnlock.get()))

let bpFreeRewardsUnlock = Computed(@()
  activeUnlocks.get().findvalue(@(unlock) "battle_pass_free" in unlock?.meta
    && unlock?.activity.start_index == bpSeasonNumber.get()))
let bpPaidRewardsUnlock = Computed(@()
  activeUnlocks.get().findvalue(@(unlock) "battle_pass_paid" in unlock?.meta
    && unlock?.activity.start_index == bpSeasonNumber.get()))
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
let isBpVipActive = Computed(@() purchasedBp.get() == BP_VIP)
let isBpCommonActive = Computed(@() purchasedBp.get() == BP_COMMON)

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
  let listPaidStages = gatherUnlockStageInfo(bpPaidRewardsUnlock.get(), true, isBpActive.get(), curStage.get())
  let listFreeStages = gatherUnlockStageInfo(bpFreeRewardsUnlock.get(), false, true, curStage.get())

  let res = listPaidStages.extend(listFreeStages)
  let purchaseStages = gatherUnlockStageInfo(bpPurchasedUnlock.get(), true, true, curStage.get())
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

let lastStageBpProgress = Computed(function() {
  let { stages = [], startStageLoop = 1, periodic = false } = bpFreeRewardsUnlock.get()
  return !periodic ? maxStage.get()
    : isEqual(stages?[startStageLoop - 1].rewards, stages?[startStageLoop - 2].rewards)
      ? (stages?[startStageLoop - 2].progress ?? 0) - 1
    : (stages?[startStageLoop - 1].progress ?? 0) - 1
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
  return stage == null ? null : { unlock = name, stage, finalStage }
}

let sendBpBqEvent = @(action, params = {}) sendCustomBqEvent("battlepass_1", params.__merge({
  action
  name = $"season_{bpSeasonNumber.get()}"
  stageProgress = curStage.get()
  battlepassPoints = pointsCurStage.get()
  isPassPurchased = isBpActive.get()
}))

function receiveBpRewards(progress) {
  if (isBpRewardsInProgress.get())
    return

  let fullList = [
    !bpPurchasedUnlock.get()?.hasReward ? null
      : { unlock = bpPurchasedUnlock.get().name, stage = bpPurchasedUnlock.get().stage }
    getNotReceivedInfo(bpFreeRewardsUnlock.get(), progress)
    isBpActive.get() ? getNotReceivedInfo(bpPaidRewardsUnlock.get(), progress) : null
  ].filter(@(v) v != null)

  if (fullList.len() == 0)
    return

  let total = fullList.reduce(@(res, c) res + (c?.finalStage ?? c.stage) - c.stage + 1, 0)
  sendBpBqEvent("receive_rewards", {
    paramInt1 = progress,
    paramInt2 = total
  })

  batchReceiveRewards(fullList.map(@(c) { unlock = c.unlock, up_to_stage = c?.finalStage ?? c.stage }))
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
  lastStageBpProgress

  mkBpStagesList
  curStage
  maxStage
  selectedStage
  isBpActive
  isBpVipActive
  isBpCommonActive
  purchasedBp
  pointsCurStage
  bpProgressUnlock
  pointsPerStage
  bpLevelPrice
  isBPLevelPurchaseInProgress = Computed(@() unlockInProgress.get().len() > 0)
  BP_PROGRESS_UNLOCK_ID
  BP_MAX_LEVELS_TO_ADD

  bpSeasonNumber
  bpSeasonName
  bpSeasonEndTime
  hasBpRewardsToReceive

  tutorialFreeMarkIdx

  getBpIcon = @(bpType, season) getBpPresentation(bpType).icon(season)
  getBpName = @(bpType) getBpPresentation(bpType).name()

  BP_NONE
  BP_COMMON
  BP_VIP
}