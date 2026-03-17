from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { eventbus_subscribe } = require("eventbus")
let { isEqual } = require("%sqstd/underscore.nut")
let gmEventPresentation = require("%appGlobals/config/gmEventPresentation.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { activeUnlocks, unlockInProgress, batchReceiveRewards, buyUnlock, getUnlockPrice
} = require("%rGui/unlocks/unlocks.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { curSeasons } = require("%appGlobals/pServer/profileSeasons.nut")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { shopGoodsToRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { allSpecialEvents } = require("%rGui/event/eventState.nut")
let { fillViewInfo, gatherUnlockStageInfo } = require("%rGui/battlePass/passStatePkg.nut")


let EVENT_PASS = "event_pass"
let EVENTPASS_POINTS = "eventpass_points_for_stages"
let curEventId = mkWatched(persist, "curEventId", "")

let eventPassTables = Computed(function() {
  let res = []
  foreach (unlock in activeUnlocks.get())
    if (EVENTPASS_POINTS in unlock?.meta)
      res.append(unlock.table)
  return res
})

let getEventPassName = @(eventName) $"{EVENT_PASS}_{eventName}"

let eventsPassList = Computed(@() allSpecialEvents.get().values().filter(@(v) eventPassTables.get().contains(v.tableId)))
let curOpenEventPass = Computed(@() eventsPassList.get().findvalue(@(v) v.eventName == curEventId.get()))

let epProgressUnlockId = Computed(@() activeUnlocks.get().findvalue(@(unlock)
  EVENTPASS_POINTS in unlock?.meta && curOpenEventPass.get()?.tableId == unlock.table)?.name)

let seasonEndTime = Computed(@() curOpenEventPass.get()?.endsAt ?? 0)

let eventBgImage = Computed(@() allSpecialEvents.get().findvalue(@(e) e.eventName == curEventId.get()) != null
  ? getEventPresentation(curEventId.get()).bg
  : gmEventPresentation(curEventId.get()).bgImage)

let eventTitle = Computed(@() allSpecialEvents.get().findvalue(@(e) e.eventName == curEventId.get()) != null
  ? $"events/name/{curEventId.get()}"
  : gmEventPresentation(curEventId.get()).locId)

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
let getPresentationByType = @(epType) epPresentation?[epType] ?? epPresentation[EP_NONE]
let isEPPurchaseWndOpened = mkWatched(persist, "isEPPurchaseWndOpened", false)
let debugBp = mkWatched(persist, "debugBp", null)

let eventProgressUnlock = Computed(@() activeUnlocks.get()?[epProgressUnlockId.get()])
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

let allEventPassGoods = Computed(function() {
  let res = {}
  foreach (v in eventsPassList.get())
    res[v.eventName] <- { [EP_COMMON] = null, [EP_VIP] = null }
  if (res.len() == 0)
    return res
  foreach (g in shopGoods.get())
    if ("event_pass" in g?.meta && res?[g.meta?.event_id] != null)
      res[g.meta.event_id][EP_COMMON] = g
    else if ("event_pass_vip" in g?.meta && res?[g.meta?.event_id] != null)
      res[g.meta.event_id][EP_VIP] = g
  return res
})
let mkEventPassGoods = @(name) Computed(function() {
  let { eventName = null } = eventsPassList.get().findvalue(@(v) getEventPassName(v.eventName) == name)
  return allEventPassGoods.get()?[eventName] ?? { [EP_COMMON] = null, [EP_VIP] = null }
})
let openedEventPassGoods = Computed(@() allEventPassGoods.get()?[curEventId.get()]
  ?? { [EP_COMMON] = null, [EP_VIP] = null })

let eventPassVipLevels = Computed(@() (openedEventPassGoods.get()?[EP_VIP].meta.pass_levels ?? 7).tointeger())

let isEpPurchasedByType = Computed(function() {
  let { purchasesCount = null } = servProfile.get()
  let seasons = curSeasons.get()
  return openedEventPassGoods.get().map(function(goods) {
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

let purchasedEpRaw = Computed(@() !isEpPurchasedByType.get()?[EP_COMMON] ? EP_NONE
  : !isEpPurchasedByType.get()[EP_VIP] ? EP_COMMON
  : EP_VIP)
let purchasedEp = Computed(@() debugBp.get() ?? purchasedEpRaw.get())
let isEpVipActive = Computed(@() purchasedEp.get() == EP_VIP)
let isEpCommonActive = Computed(@() purchasedEp.get() == EP_COMMON)

let isEpActive = Computed(@() debugBp.get() == null
  ? (activeUnlocks.get()?[eventPaidRewardsUnlock.get()?.requirement].isCompleted ?? false)
  : debugBp.get() != EP_NONE)

purchasedEp.subscribe(@(_) isEPPurchaseWndOpened.set(false))

let hasEpRewardsToReceive = Computed(function() {
  let res = {}
  foreach (v in eventsPassList.get())
    res[v.tableId] <- false
  if (res.len() == 0)
    return res

  let freeRewardsUnlocks = {}
  let paidRewardsUnlocks = {}
  let purchasedUnlocks = {}
  foreach (u in activeUnlocks.get())
    if ("eventpass_free" in u?.meta && res?[u.table] != null)
      freeRewardsUnlocks[u.table] <- u
    else if ("eventpass_paid" in u?.meta && res?[u.table] != null)
      paidRewardsUnlocks[u.table] <- u
    else if ("eventpass_purchased" in u?.meta && res?[u.table] != null)
      purchasedUnlocks[u.table] <- u

  foreach (k, _ in res)
    res[k] = freeRewardsUnlocks?[k].hasReward
      || purchasedUnlocks?[k].hasReward
      || (paidRewardsUnlocks?[k].hasReward
            && (debugBp.get() == null
                  ? (activeUnlocks.get()?[paidRewardsUnlocks?[k].requirement].isCompleted ?? false)
                  : debugBp.get() != EP_NONE))
  return res
})

let mkHasEpRewardsToReceive = @(name) Computed(function() {
  let { tableId = null } = eventsPassList.get().findvalue(@(v) getEventPassName(v.eventName) == name.get())
  return hasEpRewardsToReceive.get()?[tableId]
})

let hasAnyEpRewardsToReceive = Computed(@() null != hasEpRewardsToReceive.get().findvalue(@(v) v))

let pointsCurStage = Computed(@() (eventProgressUnlock.get()?.current ?? 0)
  % pointsPerStage.get() )
let curStage = Computed(@() eventProgressUnlock.get()?.stage ?? 0)
let maxStage = Computed(@() max(eventFreeRewardsUnlock.get()?.stages.top().progress ?? 0,
  eventPaidRewardsUnlock.get()?.stages.top().progress ?? 0))


let mkEpStagesList = @() Computed(function() {
  let listPaidStages = gatherUnlockStageInfo(eventPaidRewardsUnlock.get(), true, isEpActive.get(), curStage.get())
  let listFreeStages = gatherUnlockStageInfo(eventFreeRewardsUnlock.get(), false, true, curStage.get())

  let res = listPaidStages.extend(listFreeStages)
  let purchaseStages = gatherUnlockStageInfo(eventPurchasedUnlock.get(), true, true, curStage.get())
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
    let goods = openedEventPassGoods.get()[bpType]
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

let lastStageEpProgress = Computed(function() {
  let { stages = [], startStageLoop = 1, periodic = false } = eventFreeRewardsUnlock.get()
  return !periodic ? maxStage.get()
    : isEqual(stages?[startStageLoop - 1].rewards, stages?[startStageLoop - 2].rewards)
      ? (stages?[startStageLoop - 2].progress ?? 0) - 1
    : (stages?[startStageLoop - 1].progress ?? 0) - 1
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
  return stage == null ? null : { unlock = name, stage, finalStage }
}

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
      : { unlock = eventPurchasedUnlock.get().name, stage = eventPurchasedUnlock.get().stage }
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

  batchReceiveRewards(fullList.map(@(c) { unlock = c.unlock, up_to_stage = c?.finalStage ?? c.stage }))
}

function buyEPLevel() {
  let price = eventLevelPrice.get()
  if ((eventProgressUnlock.get()?.periodic == true || !eventProgressUnlock.get()?.isCompleted ) && price.price > 0) {
    buyUnlock(epProgressUnlockId.get(), curStage.get() + 1, price.currency, price.price,
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
  eventBgImage
  eventTitle
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
  openedEventPassGoods
  allEventPassGoods
  mkEventPassGoods
  isEpRewardsInProgress
  isEpSeasonActive = Computed(@() eventFreeRewardsUnlock.get() != null)
  lastStageEpProgress
  eventPassVipLevels

  mkEpStagesList
  curStage
  maxStage
  selectedStage
  isEpActive
  isEpVipActive
  isEpCommonActive
  purchasedEp
  pointsCurStage
  eventProgressUnlock
  pointsPerStage
  eventLevelPrice
  isEPLevelPurchaseInProgress = Computed(@() unlockInProgress.get().len() > 0)
  epProgressUnlockId

  eventsPassList
  curEventId
  seasonEndTime
  hasAnyEpRewardsToReceive
  mkHasEpRewardsToReceive

  getEpIcon = @(epType, season) getPresentationByType(epType).icon(season)
  getEpName = @(epType) getPresentationByType(epType).name()

  EP_NONE
  EP_COMMON
  EP_VIP

  getEventPassName
  EVENT_PASS
}