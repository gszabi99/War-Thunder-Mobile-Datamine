from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { eventbus_subscribe } = require("eventbus")
let { G_UNIT } = require("%appGlobals/rewardType.nut")
let { getUnitName } = require("%appGlobals/unitPresentation.nut")
let { getOPPresentation } = require("%appGlobals/config/passPresentation.nut")
let { activeUnlocks, unlockInProgress, receiveUnlockRewards, buyUnlock, getUnlockPrice
} = require("%rGui/unlocks/unlocks.nut")
let { userstatStatsTables } = require("%rGui/unlocks/userstat.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { curSeasons } = require("%appGlobals/pServer/profileSeasons.nut")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { shopGoodsToRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { fillViewInfo, gatherUnlockStageInfo } = require("%rGui/battlePass/passStatePkg.nut")
let { curCampaign, getCampaignStatsId } = require("%appGlobals/pServer/campaign.nut")

let curStatsCampaign = Computed(@() getCampaignStatsId(curCampaign.get()))

let OP_NONE = "none"
let OP_COMMON = "common"
let OP_VIP = "vip"

let OP_MAX_LEVELS_TO_ADD = 10

let operationPassOpenCounter = mkWatched(persist, "operationPassOpenCounter", 0)
let isOPPurchaseWndOpened = mkWatched(persist, "isOPPurchaseWndOpened", false)
let debugOP = mkWatched(persist, "debugOP", null)
let tutorialFreeMarkIdx = Watched(null)
let openoperationPassWnd = @() operationPassOpenCounter.set(operationPassOpenCounter.get() + 1)
let closeOperationPassWnd = @() operationPassOpenCounter.set(0)

let OPFreeRewardsUnlock = Computed(@()
  activeUnlocks.get().findvalue(@(unlock) "operation_pass_free" in unlock?.meta
    && (unlock?.meta.campaign == null || unlock?.meta.campaign == curStatsCampaign.get())))
let OPCampaign = Computed(@() OPFreeRewardsUnlock.get()?.meta.campaign)
let OPPaidRewardsUnlock = Computed(@()
  activeUnlocks.get().findvalue(@(unlock) "operation_pass_paid" in unlock?.meta
    && unlock?.meta.campaign == OPCampaign.get()))
let OPPurchasedUnlock = Computed(@()
  activeUnlocks.get().findvalue(@(unlock) "operation_pass_purchased" in unlock?.meta
    && unlock?.meta.campaign == OPCampaign.get()))

let seasonUnitName = Computed(function() {
  let { stages = [] } = OPPaidRewardsUnlock.get()
  let { userstatRewards = {} } = serverConfigs.get()
  for (local i = stages.len() - 1; i >= 0; i--)
    foreach (k, _ in stages[i].rewards) {
      let unitReward = (userstatRewards?[k] ?? []).findvalue(@(r) r.gType == G_UNIT)
      if (unitReward != null)
        return getUnitName(unitReward.id, loc)
    }
  return null
})
let seasonNumber = Computed(@() userstatStatsTables.get()?.stats[OPFreeRewardsUnlock.get()?.table]["$index"] ?? 0)
let seasonName = Computed(@() seasonUnitName.get() != null
  ? loc("events/name/operation_pass_season", { name = seasonUnitName.get() })
  : loc($"events/name/operation_pass_season_{seasonNumber.get()}"))
let seasonEndTime = Computed(@() userstatStatsTables.get()?.stats[OPFreeRewardsUnlock.get()?.table]["$endsAt"] ?? 0)

let progressUnlockId = Computed(@() OPCampaign.get() == null
  ? "operation_pass_points_to_progress"
  : $"operation_pass_points_to_progress_{OPCampaign.get()}")
let OPProgressUnlock = Computed(@() activeUnlocks.get()?[progressUnlockId.get()])
let pointsPerStage   = Computed(@() OPProgressUnlock.get()?.stages[0].progress ?? 1)
let OPLevelPrice = Computed(@() getUnlockPrice(OPProgressUnlock.get()))

let isOPRewardsInProgress = Computed(@()
  OPFreeRewardsUnlock.get()?.name in unlockInProgress.get()
    || OPPaidRewardsUnlock.get()?.name in unlockInProgress.get()
    || OPPurchasedUnlock.get()?.name in unlockInProgress.get())

let operationPassGoods = Computed(function() {
  let campaign = OPCampaign.get()
  return {
    [OP_COMMON] = shopGoods.get().findvalue(@(s) "operation_pass" in s?.meta
      && getCampaignStatsId(s?.meta.campaign) == campaign),
    [OP_VIP] = shopGoods.get().findvalue(@(s) "operation_pass_vip" in s?.meta
      && getCampaignStatsId(s?.meta.campaign) == campaign),
  }
})

let isOPPurchasedByType = Computed(function() {
  let { purchasesCount = null } = servProfile.get()
  let seasons = curSeasons.get()
  return operationPassGoods.get().map(function(goods) {
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

let purchasedOPRaw = Computed(@() !isOPPurchasedByType.get()[OP_COMMON] ? OP_NONE
  : !isOPPurchasedByType.get()[OP_VIP] ? OP_COMMON
  : OP_VIP)
let purchasedOP = Computed(@() debugOP.get() ?? purchasedOPRaw.get())

let isOPActive = Computed(@() debugOP.get() == null
  ? (activeUnlocks.get()?[OPPaidRewardsUnlock.get()?.requirement].isCompleted ?? false)
  : debugOP.get() != OP_NONE)

purchasedOP.subscribe(@(_) isOPPurchaseWndOpened.set(false))

let hasOPRewardsToReceive = Computed(@() !!OPFreeRewardsUnlock.get()?.hasReward
  || !!OPPurchasedUnlock.get()?.hasReward
  || (isOPActive.get() && !!OPPaidRewardsUnlock.get()?.hasReward))

let pointsCurStage = Computed(@() (OPProgressUnlock.get()?.current ?? 0)
  % pointsPerStage.get() )
let curStage = Computed(@() OPProgressUnlock.get()?.stage ?? 0)
let maxStage = Computed(@() max(OPFreeRewardsUnlock.get()?.stages.top().progress ?? 0,
  OPPaidRewardsUnlock.get()?.stages.top().progress ?? 0))

let mkOPStagesList = @() Computed(function() {
  let listPaidStages = gatherUnlockStageInfo(OPPaidRewardsUnlock.get(), true, isOPActive.get(), curStage.get(), maxStage.get())
  let listFreeStages = gatherUnlockStageInfo(OPFreeRewardsUnlock.get(), false, true, curStage.get(), maxStage.get())

  let res = listPaidStages.extend(listFreeStages)
  let purchaseStages = gatherUnlockStageInfo(OPPurchasedUnlock.get(), true, true, curStage.get(), maxStage.get())
  if (purchaseStages.len() > 0) {
    let { isReceived, canReceive } = purchaseStages[0]
    res.insert(0, purchaseStages[0].__merge({
      progress = 0
      canBuyLevel = false
      canReceive = (debugOP.get() ?? OP_NONE) == OP_NONE ? canReceive
        : (!isReceived && !canReceive)
    }))
  }

  local addIdx = -1
  foreach(OPType in [OP_COMMON, OP_VIP]) {
    let goods = operationPassGoods.get()[OPType]
    if (goods == null)
      continue
    foreach(viewInfo in shopGoodsToRewardsViewInfo(goods))
      res.insert(0, {
        progress = addIdx--
        viewInfo
        isVip = OPType == OP_VIP
        isPaid = true
        isReceived = isOPPurchasedByType.get()[OPType]
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

let selectedStage = mkWatched(persist, "OPSelectedStage", 0)

function getOPIcon(passType, campaign) {
  let presentation = getOPPresentation(campaign)
  return passType == OP_COMMON ? presentation.icon
    : passType == OP_VIP ? presentation.iconVip
    : presentation.iconInactive
}
let getOPName = @(passType, name) passType == OP_COMMON ? loc("operationPass", { name })
  : passType == OP_VIP ? loc("operationPassVIP", { name })
  : ""

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

function receiveOPRewardsImpl(toReceive) {
  if (toReceive.len() == 0)
    return
  let { unlockName, stage, finalStage = null } = toReceive[0]
  receiveUnlockRewards(unlockName, stage,
    { finalStage, onSuccessCb = { id = "operationPass.grantMultiRewards", nextReceive = toReceive.slice(1) } })
}

eventbus_subscribe("operationPass.grantMultiRewards", @(msg) receiveOPRewardsImpl(msg.nextReceive))

let sendOPBqEvent = @(action, params = {}) sendCustomBqEvent("operationpass_1", params.__merge({
  action
  name = $"operation_pass_season_{seasonNumber.get()}"
  stageProgress = curStage.get()
  operationpassPoints = pointsCurStage.get()
  isPassPurchased = isOPActive.get()
}))

function receiveOPRewards(progress) {
  if (isOPRewardsInProgress.get())
    return

  let fullList = [
    !OPPurchasedUnlock.get()?.hasReward ? null
      : { unlockName = OPPurchasedUnlock.get().name, stage = OPPurchasedUnlock.get().stage }
    getNotReceivedInfo(OPFreeRewardsUnlock.get(), progress)
    isOPActive.get() ? getNotReceivedInfo(OPPaidRewardsUnlock.get(), progress) : null
  ].filter(@(v) v != null)

  if (fullList.len() == 0)
    return

  let total = fullList.reduce(@(res, c) res + c.finalStage - c.stage + 1, 0)
  sendOPBqEvent("receive_rewards", {
    paramInt1 = progress,
    paramInt2 = total
  })
  receiveOPRewardsImpl(fullList)
}

function buyOPLevel() {
  let price = OPLevelPrice.get()
  if ((OPProgressUnlock.get()?.periodic == true || !OPProgressUnlock.get()?.isCompleted ) && price.price > 0) {
    buyUnlock(progressUnlockId.get(), curStage.get() + 1, price.currency, price.price,
      { onSuccessCb = { id = "operationPass.buyUnlock" }})
  }
}

eventbus_subscribe("operationPass.buyUnlock", function(_) {
  sendOPBqEvent("buy_level", {
    paramInt1 = curStage.get() + 1
  })
  receiveOPRewards(curStage.get() + 1)
})


isOPPurchaseWndOpened.subscribe(@(v) v ? sendOPBqEvent("OP_purchase_open") : null)

let dbgOrder = [OP_NONE, OP_COMMON, OP_VIP]
register_command(
  function() {
    let cur = debugOP.get() ?? purchasedOPRaw.get()
    let idx = (dbgOrder.indexof(cur) ?? -1) + 1
    let new = dbgOrder[idx % dbgOrder.len()]
    debugOP.set(new == purchasedOPRaw.get() ? null : new)
    log($"New purchased OP = {purchasedOP.get()}. (isReal = {purchasedOP.get() == purchasedOPRaw.get()})")
  },
  "ui.debug.operationPass")

return {
  OPCampaign
  operationPassOpenCounter
  openoperationPassWnd
  closeOperationPassWnd
  isOPPurchaseWndOpened
  openOPPurchaseWnd = @() isOPPurchaseWndOpened.set(true)
  closeOPPurchaseWnd = @() isOPPurchaseWndOpened.set(false)
  receiveOPRewards
  sendOPBqEvent
  buyOPLevel

  OPFreeRewardsUnlock
  OPPaidRewardsUnlock
  OPPurchasedUnlock
  operationPassGoods
  isOPRewardsInProgress
  isOPSeasonActive = Computed(@() OPFreeRewardsUnlock.get() != null)

  mkOPStagesList
  curStage
  maxStage
  selectedStage
  isOPActive
  purchasedOP
  pointsCurStage
  OPProgressUnlock
  pointsPerStage
  OPLevelPrice
  isOPLevelPurchaseInProgress = Computed(@() unlockInProgress.get().len() > 0)
  progressUnlockId
  OP_MAX_LEVELS_TO_ADD

  seasonUnitName
  seasonNumber
  seasonName
  seasonEndTime
  hasOPRewardsToReceive

  tutorialFreeMarkIdx

  getOPIcon
  getOPName

  OP_NONE
  OP_COMMON
  OP_VIP
}