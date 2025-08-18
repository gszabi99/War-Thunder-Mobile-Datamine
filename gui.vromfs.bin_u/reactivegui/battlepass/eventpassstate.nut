from "%globalsDarg/darg_library.nut" import *

let { register_command } = require("console")
let { eventbus_subscribe } = require("eventbus")
let { activeUnlocks, unlockInProgress, receiveUnlockRewards, buyUnlock, getUnlockPrice
} = require("%rGui/unlocks/unlocks.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { curSeasons } = require("%appGlobals/pServer/profileSeasons.nut")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { shopGoodsToRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { allSpecialEvents } = require("%rGui/event/eventState.nut")
let { fillViewInfo, gatherUnlockStageInfo } = require("%rGui/battlePass/passStatePkg.nut")
let gmEventPresentation = require("%appGlobals/config/gmEventPresentation.nut")

let EVENTPASS_POINTS = "eventpass_points_for_stages"
let curEventId = mkWatched(persist, "curEventId", "")

let eventPassTables = Computed(function() {
  let res = []
  foreach (unlock in activeUnlocks.get()) {
    if(EVENTPASS_POINTS in unlock?.meta)
      res.append(unlock.table)
  }
  return res
})

let eventsPassList = Computed(@() allSpecialEvents.get().values().filter(@(v) eventPassTables.get().contains(v.tableId)))
let curOpenEventPass = Computed(@() eventsPassList.get().findvalue(@(v) v.eventName == curEventId.get()))

let BP_GOODS_ID = "event_pass"
let epPrograssUnlockId = Computed(@()
  activeUnlocks.get().findvalue(@(unlock) EVENTPASS_POINTS in unlock?.meta)?.name)

let seasonEndTime = Computed(@() curOpenEventPass.get()?.endsAt ?? 0)

let EP_NONE = "none"
let EP_COMMON = "common"
let EP_VIP = "vip"

let epPresentation = {
  [EP_NONE] = {
    name = @() ""
    icon = @(_) $"ui/gameuiskin#event_pass_icon_not_active.avif"
  },
  [EP_COMMON] = {
    name = @() loc("eventPass")
    icon = @(eventName) $"ui/gameuiskin#event_pass_icon_{eventName}.avif"
  },
  [EP_VIP] = {
    name = @() loc("eventPassVIP")
    icon = @(eventName) $"ui/gameuiskin#event_pass_icon_{eventName}_vip.avif"
  },
}
let getEpPresentation = @(epType) epPresentation?[epType] ?? epPresentation[EP_NONE]
let eventPassOpenCounter = mkWatched(persist, "eventPassOpenCounter", 0)
let isEPPurchaseWndOpened = mkWatched(persist, "isEPPurchaseWndOpened", false)
let debugBp = mkWatched(persist, "debugBp", null)
let tutorialFreeMarkIdx = Watched(null)
function openEventPassWnd(id) {
  eventPassOpenCounter.set(eventPassOpenCounter.get() + 1)
  curEventId.set(id)
}
let closeEventPassWnd = @() eventPassOpenCounter.set(0)

let eventProgressUnlock = Computed(@() activeUnlocks.get()?[epPrograssUnlockId.get()])
let pointsPerStage   = Computed(@() eventProgressUnlock.get()?.stages[0].progress ?? 1)
let eventLevelPrice = Computed(@() getUnlockPrice(eventProgressUnlock.get()))

let eventFreeRewardsUnlock = Computed(@()
  activeUnlocks.get().findvalue(@(unlock) "eventpass_free" in unlock?.meta
    && curOpenEventPass.get()?.tableId == unlock.table))
let eventPaidRewardsUnlock = Computed(@()
  activeUnlocks.get().findvalue(@(unlock) "eventpass_paid" in unlock?.meta
    && curOpenEventPass.get()?.tableId == unlock.table))
let eventPurchasedUnlock = Computed(@()
  activeUnlocks.get().findvalue(@(unlock) "eventpass_purchased" in unlock?.meta
    && curOpenEventPass.get()?.tableId == unlock.table))

let isEpRewardsInProgress = Computed(@()
  eventFreeRewardsUnlock.get()?.name in unlockInProgress.get()
    || eventPaidRewardsUnlock.get()?.name in unlockInProgress.get()
    || eventPurchasedUnlock.get()?.name in unlockInProgress.get())

let eventPassGoods = Computed(@() {
  [EP_COMMON] = shopGoods.get()?[BP_GOODS_ID],
  [EP_VIP] = shopGoods.get().findvalue(@(s) "event_pass_vip" in s?.meta)
})

let isEpPurchasedByType = Computed(function() {
  let { purchasesCount = null } = servProfile.get()
  let seasons = curSeasons.get()
  return eventPassGoods.get().map(function(goods) {
    if (goods == null)
      return null

    let { oncePerSeason = "", id } = goods
    let { count = 0, lastTime = 0 } = purchasesCount?[id]
    if (oncePerSeason == "" || count <= 0)
      return count > 0

    let { start = 0, end = 0 } = seasons?[oncePerSeason]
    return lastTime != 0 && start != 0 && lastTime >= start && lastTime <= end
  })
})

let purchasedEpRaw = Computed(@() !isEpPurchasedByType.get()[EP_COMMON] ? EP_NONE
  : !isEpPurchasedByType.get()[EP_VIP] ? EP_COMMON
  : EP_VIP)
let purchasedEp = Computed(@() debugBp.get() ?? purchasedEpRaw.get())

let isEpActive = Computed(@() debugBp.get() == null
  ? (activeUnlocks.get()?[eventPaidRewardsUnlock.get()?.requirement].isCompleted ?? false)
  : debugBp.get() != EP_NONE)

purchasedEp.subscribe(@(_) isEPPurchaseWndOpened.set(false))

let hasEpRewardsToReceive = Computed(@() !!eventFreeRewardsUnlock.get()?.hasReward
  || !!eventPurchasedUnlock.get()?.hasReward
  || (isEpActive.get() && !!eventPaidRewardsUnlock.get()?.hasReward))

let pointsCurStage = Computed(@() (eventProgressUnlock.get()?.current ?? 0)
  % pointsPerStage.get() )
let curStage = Computed(@() eventProgressUnlock.get()?.stage ?? 0)
let maxStage = Computed(@() max(eventFreeRewardsUnlock.get()?.stages.top().progress ?? 0,
  eventPaidRewardsUnlock.get()?.stages.top().progress ?? 0))


let mkEpStagesList = @() Computed(function() {
  let listPaidStages = gatherUnlockStageInfo(eventPaidRewardsUnlock.get(), true, isEpActive.get(), curStage.get(), maxStage.get())
  let listFreeStages = gatherUnlockStageInfo(eventFreeRewardsUnlock.get(), false, true, curStage.get(), maxStage.get())

  let res = listPaidStages.extend(listFreeStages)
  let purchaseStages = gatherUnlockStageInfo(eventPurchasedUnlock.get(), true, true, curStage.get(), maxStage.get())
  if (purchaseStages.len() > 0) {
    let { isReceived, canReceive } = purchaseStages[0]
    res.insert(0, purchaseStages[0].__merge({
      progress = 0
      canBuyLevel = false
      canReceive = (debugBp.get() ?? EP_NONE) == EP_NONE ? canReceive
        : (!isReceived && !canReceive)
    }))
  }

  local addIdx = -1
  foreach(bpType in [EP_COMMON, EP_VIP]) {
    let goods = eventPassGoods.get()[bpType]
    if (goods == null)
      continue
    foreach(viewInfo in shopGoodsToRewardsViewInfo(goods))
      res.insert(0, {
        progress = addIdx--
        viewInfo
        isVip = bpType == EP_VIP
        isPaid = true
        isReceived = isEpPurchasedByType.get()[bpType]
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

let selectedStage = mkWatched(persist, "epSelectedStage", 0)

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

function receiveEpRewardsImpl(toReceive) {
  if ((toReceive?.len() ?? 0) == 0)
    return
  let { unlockName, stage, finalStage = null } = toReceive[0]
  receiveUnlockRewards(unlockName, stage,
    { finalStage, onSuccessCb = { id = "battlePass.grantMultiRewards", nextReceive = toReceive.slice(1) } })
}

eventbus_subscribe("battlePass.grantMultiRewards", @(msg) receiveEpRewardsImpl(msg.nextReceive))

let sendEpBqEvent = @(action, params = {}) sendCustomBqEvent("eventpass_1", params.__merge({
  action
  name = $"{curEventId.get()}"
  stageProgress = curStage.get()
  eventpassPoints = pointsCurStage.get()
  isPassPurchased = isEpActive.get()
}))

function receiveEpRewards(progress) {
  if (isEpRewardsInProgress.get())
    return

  let fullList = [
    !eventPurchasedUnlock.get()?.hasReward ? null
      : { unlockName = eventPurchasedUnlock.get().name, stage = eventPurchasedUnlock.get().stage }
    getNotReceivedInfo(eventFreeRewardsUnlock.get(), progress)
    isEpActive.get() ? getNotReceivedInfo(eventPaidRewardsUnlock.get(), progress) : null
  ].filter(@(v) v != null)

  if (fullList.len() == 0)
    return

  let total = fullList.reduce(@(res, c) res + c.finalStage - c.stage + 1, 0)
  sendEpBqEvent("receive_rewards", {
    paramInt1 = progress,
    paramInt2 = total
  })
  receiveEpRewardsImpl(fullList)
}

function buyEPLevel() {
  let price = eventLevelPrice.get()
  if ((eventProgressUnlock.get()?.periodic == true || !eventProgressUnlock.get()?.isCompleted ) && price.price > 0) {
    buyUnlock(epPrograssUnlockId.get(), curStage.get() + 1, price.currency, price.price,
      { onSuccessCb = { id = "eventPass.buyUnlock" }})
  }
}

eventbus_subscribe("eventPass.buyUnlock", function(_) {
  sendEpBqEvent("buy_level", {
    paramInt1 = curStage.get() + 1
  })
  receiveEpRewards(curStage.get() + 1)
})


isEPPurchaseWndOpened.subscribe(@(v) v ? sendEpBqEvent("ep_purchase_open") : null)

let dbgOrder = [EP_NONE, EP_COMMON, EP_VIP]
register_command(
  function() {
    let cur = debugBp.get() ?? purchasedEpRaw.get()
    let idx = (dbgOrder.indexof(cur) ?? -1) + 1
    let new = dbgOrder[idx % dbgOrder.len()]
    debugBp.set(new == purchasedEpRaw.get() ? null : new)
    log($"New purchased EP = {purchasedEp.get()}. (isReal = {purchasedEp.get() == purchasedEpRaw.get()})")
  },
  "ui.debug.eventPass")

return {
  eventBgImage = Computed(@() gmEventPresentation(curEventId.get()).bgImage )
  eventPassOpenCounter
  openEventPassWnd
  closeEventPassWnd
  isEPPurchaseWndOpened
  openEPPurchaseWnd = @() isEPPurchaseWndOpened.set(true)
  closeEPPurchaseWnd = @() isEPPurchaseWndOpened.set(false)
  receiveEpRewards
  curOpenEventPass

  sendEpBqEvent
  buyEPLevel

  eventFreeRewardsUnlock
  eventPaidRewardsUnlock
  eventPurchasedUnlock
  eventPassGoods
  isEpRewardsInProgress
  isEpSeasonActive = Computed(@() eventFreeRewardsUnlock.get() != null)

  mkEpStagesList
  curStage
  maxStage
  selectedStage
  isEpActive
  purchasedEp
  pointsCurStage
  eventProgressUnlock
  pointsPerStage
  eventLevelPrice
  isEPLevelPurchaseInProgress = Computed(@() unlockInProgress.get().len() > 0)
  epPrograssUnlockId

  eventsPassList
  curEventId
  seasonEndTime
  hasEpRewardsToReceive

  tutorialFreeMarkIdx

  getEpIcon = @(epType, season) getEpPresentation(epType).icon(season)
  getEpName = @(epType) getEpPresentation(epType).name()

  EP_NONE
  EP_COMMON
  EP_VIP
}