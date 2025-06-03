from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { round } =  require("math")
let { isEqual } = require("%sqstd/underscore.nut")
let { TIME_DAY_IN_SECONDS } = require("%sqstd/time.nut")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { campConfigs, curCampaign, todayPurchasesCount } = require("%appGlobals/pServer/campaign.nut")
let { can_debug_shop, allow_subscriptions } = require("%appGlobals/permissions.nut")
let { WP, GOLD, PLATINUM } = require("%appGlobals/currenciesState.nut")
let { sortByCurrencyId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { sendBqEventOnOpenCurrencyShop } = require("%rGui/shop/bqPurchaseInfo.nut")
let { actualSchRewardByCategory, actualSchRewards, lastAppliedSchReward, schRewards
} = require("schRewardsState.nut")
let { platformGoods, platformSubs } = require("platformGoods.nut")
let { personalGoodsByShopCategory } = require("personalGoodsState.nut")


let pageScrollHandler = ScrollHandler()

let isShopOpened = mkWatched(persist, "isShopOpened", false)
let shopOpenCount = Watched(0)

let curCategoryId = mkWatched(persist, "curCategoryId", null)

let SEEN_GOODS = "shopSeenGoods"
let UNMARK_SEEN_COUNTERS = "unmarkSeenCounters"
let shopSeenGoods = mkWatched(persist, "shopSeenGoods", {})
let unmarkSeenCounters = mkWatched(persist, "unmarkSeenCounters", {})

let categoryByCurrency = {
  [WP] = SC_WP,
  [GOLD] = SC_GOLD,
  [PLATINUM] = SC_PLATINUM
}

let sortCurrency = @(a, b) (a.currencies?.platinum ?? 0) <=> (b.currencies?.platinum ?? 0)
  || (a.currencies?.gold ?? 0) <=> (b.currencies?.gold ?? 0)
  || (a.currencies?.wp ?? 0) <=> (b.currencies?.wp ?? 0)

let sortGoods = @(a, b)
  b.meta?.eventId <=> a.meta?.eventId
  || b.meta?.order <=> a.meta?.order
  || sortByCurrencyId(a.price.currencyId, b.price.currencyId)
  || a.gtype <=> b.gtype
  || sortCurrency(a, b)
  || a.price.price <=> b.price.price
  || a.premiumDays <=> b.premiumDays
  || a.id <=> b.id

let goodsWithTimers = Computed(@() (campConfigs.value?.allGoods ?? {})
  .filter(@(g) "timeRange" in g ? g.timeRange.start > 0 || g.timeRange.end > 0 
    : g.timeRanges.len() > 0
  ))
let inactiveGoodsByTime = Watched({})
let finishedGoodsByTime = Watched({})
let nextUpdateTime = Watched({ time = 0 })
let goodsLinks = Computed(@() (campConfigs.get()?.allGoods ?? [])
  .reduce(function(res, goods) {
    if (goods.relatedGaijinId == "")
      return res
    let list = [goods.id, goods.relatedGaijinId]
    foreach(id in list)
      res[id] <- list
    return res
  }, {}))

let startNextDayTime = @() TIME_DAY_IN_SECONDS - (serverTime.get() % TIME_DAY_IN_SECONDS)

function updateGoodsTimers() {
  let inactive = {}
  let finished = {}
  local nextTime = null
  let curTime = serverTime.get()
  let isValid = isServerTimeValid.get()
  foreach(id, goods in goodsWithTimers.get()) {
    if (!isValid) {
      inactive[id] <- true
      continue
    }

    let { timeRange = null, timeRanges = [], dailyLimit = 0 } = goods
    if (timeRange != null) { 
      let { start, end } = timeRange
      if (start > curTime) {
        inactive[id] <- true
        nextTime = min(nextTime ?? start, start)
      }
      else if (end <= 0)
        continue
      else if (end <= curTime) {
        inactive[id] <- true
        finished[id] <- true
      }
      else if (end <= startNextDayTime() && dailyLimit > 0 && todayPurchasesCount.get()?[id].count == dailyLimit)
        inactive[id] <- true
      else
        nextTime = min(nextTime ?? end, end)
      continue
    }

    if (timeRanges.len() == 0)
      continue
    local isActive = false
    local hasNext = false
    foreach (tr in timeRanges) {
      let { start, end } = tr
      if (start > curTime) {
        nextTime = min(nextTime ?? start, start)
        hasNext = true
      }
      else if (end <= 0) {
        isActive = true
        break
      }
      else if (end > curTime) {
        isActive = end > startNextDayTime() || dailyLimit == 0 || (todayPurchasesCount.get()?[id].count ?? 0) < dailyLimit
        if (isActive) {
          nextTime = min(nextTime ?? end, end)
          break
        }
        else
          hasNext = end < startNextDayTime()
      }
    }
    if (!isActive) {
      inactive[id] <- true
      if (!hasNext)
        finished[id] <- true
    }
  }

  if (!isEqual(inactive, inactiveGoodsByTime.get()))
    inactiveGoodsByTime.set(inactive)
  if (!isEqual(finished, finishedGoodsByTime.get()))
    finishedGoodsByTime.set(finished)
  nextUpdateTime({ time = nextTime ?? 0 })
}

nextUpdateTime.subscribe(function(v) {
  let { time } = v
  if (time == 0)
    clearTimer(updateGoodsTimers)
  else
    resetTimeout(max(0.5, time - serverTime.get()), updateGoodsTimers)
})

updateGoodsTimers()
goodsWithTimers.subscribe(@(_) updateGoodsTimers())
isServerTimeValid.subscribe(@(_) updateGoodsTimers())
todayPurchasesCount.subscribe(@(_ ) updateGoodsTimers())

let allowWithSubs = @(goods) goods.premiumDays == 0

function calculateNewGoodsDiscount(discountedPrice = 0.0, originalPercent = 0.0, newPrice = 0.0) {
  if (originalPercent >= 100.0)
    return originalPercent

  let discountFactor = 1.0 - (originalPercent / 100.0)
  let initialPrice = discountedPrice / discountFactor
  if (initialPrice == 0.0)
    return originalPercent

  return round((1.0 - newPrice / initialPrice) * 100.0)
}

let discountsToApply = Computed(function() {
  let { personalDiscounts = {} } = serverConfigs.get()
  let myDiscounts = servProfile.get()?.discounts
  let res = {}

  if (!myDiscounts)
    return null

  foreach(list in personalDiscounts)
    foreach(discount in list) {
      let { id, goodsId, price } = discount
      if (id in myDiscounts) {
        if (goodsId not in res)
          res[goodsId] <- price
        else
          res[goodsId] <- min(res[goodsId], price)
      }
    }
  return res
})

let shopGoodsInternal = Computed(function() {
  let discToApply = discountsToApply.get()
  return (campConfigs.get()?.allGoods ?? {})
    .filter(@(g) (can_debug_shop.get() || !g.isShowDebugOnly)
      && ((g?.price.price ?? 0) > 0 || null != g?.dailyPriceInc.findvalue(@(cfg) cfg.price > 0)))
    .map(function(g) {
      if (g.id in discToApply) {
        let personalFinalPrice = discToApply[g.id]
        let res = g.__merge({
          gtype = getGoodsType(g)
          price = { price = personalFinalPrice, currencyId = g?.price.currencyId ?? "" }
          discountInPercent = calculateNewGoodsDiscount(g?.price.price, g?.discountInPercent, personalFinalPrice)
        })
        return res
      }
      return g.__merge({ gtype = getGoodsType(g) })
    })
})

let allCampaignsShopGoods = Computed(function() {
  let res = shopGoodsInternal.get()
    .__merge(platformGoods.get().map(@(g) g.__merge({ gtype = getGoodsType(g) })))
  return !allow_subscriptions.get() ? res : res.filter(allowWithSubs)
})

let allShopGoods = Computed(@() allCampaignsShopGoods.get()
  .filter(@(g) isGoodsFitToCampaign(g, campConfigs.get(), curCampaign.get())))

let shopGoods = Computed(function() {
  let exclude = inactiveGoodsByTime.get()
  return allShopGoods.get().filter(@(_, id) id not in exclude)
})

let shopGoodsAllCampaigns = Computed(function() {
  let exclude = inactiveGoodsByTime.get()
  return allCampaignsShopGoods.get().filter(@(_, id) id not in exclude)
})

let allSubs = Computed(@() allow_subscriptions.get() ? platformSubs.get() : {})

let goodsByCategory = Computed(function() {
  let res = {}
  foreach (goods in shopGoods.get()) {
    if (goods.isHidden) 
      continue
    let cat = getShopCategory(goods.gtype, goods.meta)
    if (cat not in res)
      res[cat] <- []
    res[cat].append(goods)
  }
  return res
})

let subsGroups = {
  prem = ["premium", "vip"]
}

let subsByCategory = Computed(function() {
  local allSubsData = allSubs.get()
  if (allSubsData.len() == 0)
    return {}
  local subNotInGroups = []
  local result = []
  local allGroupKeys = {}
  foreach (group in subsGroups)
    foreach (key in group)
      allGroupKeys[key] <- true
  foreach(key, value in allSubsData)
    if (!(key in allGroupKeys))
      subNotInGroups.append(value)
  result.extend(subNotInGroups)
  foreach(groupList in subsGroups)
    for (local i = groupList.len() - 1; i >= 0; i--)
      if (groupList[i] in allSubsData) {
        result.append(allSubsData[groupList[i]])
        break
      }
  return { [SC_PREMIUM] = result }
})

let goodsIdsByCategory = Computed(function() {
  let goods = {}
  foreach (cat, val in goodsByCategory.value){
    goods[cat] <- []
    val.map(@(item) goods[cat].append(item?.id))
    if (actualSchRewardByCategory.value?[cat]?.id)
      goods[cat].append(actualSchRewardByCategory.value[cat].id)
  }
  foreach (cat, list in subsByCategory.get()) {
    if (cat not in goods)
      goods[cat] <- []
    goods[cat].extend(list.map(@(v) v.id))
  }
  return goods
})

function unmarkSeenGoods(unmarkSeen, unmarkCounters = {}) {
  let toRemove = unmarkSeen.filter(@(id) id in shopSeenGoods.value)
  let counters = unmarkCounters.filter(@(id, count) unmarkSeenCounters.value?[id] != count)
  if (toRemove.len() == 0 && counters.len() == 0)
    return

  let sBlk = get_local_custom_settings_blk()

  if (toRemove.len() != 0) {
    let seenBlk = sBlk.addBlock(SEEN_GOODS)
    shopSeenGoods.mutate(function(v) {
      foreach(id in toRemove) {
        v.$rawdelete(id)
        seenBlk[id] = null
      }
    })
  }

  if (counters.len() != 0) {
    unmarkSeenCounters(unmarkSeenCounters.value.__merge(counters))
    let blk = sBlk.addBlock(UNMARK_SEEN_COUNTERS)
    foreach (id, v in counters)
      blk[id] = v
  }

  eventbus_send("saveProfile", {})
}
lastAppliedSchReward.subscribe(function(v) {
  let { rewardId } = v
  let unmarkSeen = [rewardId]
  let unmarkCounters = {}

  let { gtype = null, needAdvert = false } = schRewards.value?[rewardId]
  if (gtype != null && !needAdvert)
    foreach(id, rew in schRewards.value)
      if (rew.gtype == gtype && id != rewardId && rew.needAdvert) {
        unmarkSeen.append(id)
        unmarkCounters[id] <- 1
      }

  unmarkSeenGoods(unmarkSeen, unmarkCounters)
})

isInDebriefing.subscribe(function(v) {
  if (!v)
    unmarkSeenGoods(unmarkSeenCounters.value.filter(@(c) c == 0).keys())
})

function saveSeenGoods(ids) {
  let upd = {}
  let cUpd = {}
  foreach(id in ids) {
    if (shopSeenGoods.value?[id])
      continue
    let schReward = actualSchRewards.value?[id]
    if (schReward != null && (!schReward.needAdvert || !schReward.isReady))
      continue
    upd[id] <- true
    if (id in unmarkSeenCounters.value)
      cUpd[id] <- unmarkSeenCounters.value[id] - 1
  }
  if (upd.len() == 0)
    return

  let sBlk = get_local_custom_settings_blk()
  shopSeenGoods(shopSeenGoods.value.__merge(upd))
  let seenBlk = sBlk.addBlock(SEEN_GOODS)
  foreach (id, _ in upd)
    seenBlk[id] = true

  if (cUpd.len() != 0) {
    unmarkSeenCounters(unmarkSeenCounters.value.__merge(cUpd))
    let cBlk = sBlk.addBlock(UNMARK_SEEN_COUNTERS)
    foreach (id, v in cUpd)
      cBlk[id] = v
  }
  eventbus_send("saveProfile", {})
}

function resetSeenGoods() {
  shopSeenGoods.set({})
  unmarkSeenCounters.set({})
}

function loadSeenGoods() {
  if (!isSettingsAvailable.get())
    return resetSeenGoods()
  let blk = get_local_custom_settings_blk()
  let seenBlk = blk?[SEEN_GOODS]
  let seen = {}
  if (isDataBlock(seenBlk))
    eachParam(seenBlk, @(isSeen, id) seen[id] <- isSeen)
  shopSeenGoods(seen)

  let countersBlk = blk?[UNMARK_SEEN_COUNTERS]
  let counters = {}
  if (isDataBlock(countersBlk))
    eachParam(countersBlk, @(v, id) counters[id] <- v)
  unmarkSeenCounters(counters)
}

if (shopSeenGoods.value.len() == 0)
  loadSeenGoods()

isSettingsAvailable.subscribe(@(_) loadSeenGoods())

let isUnseenGoods = @(id, seenGoods, actSchRewards) (id not in seenGoods
  && (id not in actSchRewards || actSchRewards?[id]?.isReady == true))

let shopUnseenGoods = Computed(function() {
  let res = {}
  foreach (ids in goodsIdsByCategory.get())
    foreach (id in ids)
      if (isUnseenGoods(id, shopSeenGoods.get(), actualSchRewards.get()))
        res[id] <- true
  return res
})

let hasUnseenGoodsByCategory = Computed(function() {
  return goodsIdsByCategory.value.map(function(ids) {
    foreach (id in ids)
      if (id in shopUnseenGoods.value)
        return true
    return false
  })
})

let saveSeenGoodsCurrent = @() !hasUnseenGoodsByCategory.value?[curCategoryId.value] ? null
  : saveSeenGoods(goodsIdsByCategory.value[curCategoryId.value])

function onTabChange(id) {
  saveSeenGoodsCurrent()
  curCategoryId(id)
}

let hasGoodsCategoryNonUpdatable = @(catId) catId in goodsByCategory.get()
  || catId in personalGoodsByShopCategory.get()
  || catId in actualSchRewardByCategory.get()
  || catId in subsByCategory.get()

function openShopWnd(catId = null, bqPurchaseInfo = null) {
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return
  }

  curCategoryId.set(hasGoodsCategoryNonUpdatable(catId) ? catId
    : shopCategoriesCfg.findvalue(@(c) hasGoodsCategoryNonUpdatable(c.id))?.id)
  shopOpenCount(shopOpenCount.value + 1)
  sendBqEventOnOpenCurrencyShop(bqPurchaseInfo)
  isShopOpened(true)
}

let openShopWndByCurrencyId = @(currencyId, bqPurchaseInfo)
  openShopWnd(categoryByCurrency?[currencyId], bqPurchaseInfo.__merge({ id = currencyId }))

register_command(function() {
  shopSeenGoods({})
  get_local_custom_settings_blk().removeBlock(SEEN_GOODS)
  get_local_custom_settings_blk().removeBlock(UNMARK_SEEN_COUNTERS)
  eventbus_send("saveProfile", {})
  log("Success")
}, "debug.reset_seen_goods")

return {
  openShopWnd
  openShopWndByCurrencyId
  isShopOpened
  shopOpenCount

  curCategoryId
  goodsByCategory
  allShopGoods
  shopGoodsAllCampaigns
  shopGoods
  shopGoodsInternal
  goodsLinks
  sortGoods
  inactiveGoodsByTime
  finishedGoodsByTime
  allSubs
  subsGroups
  subsByCategory

  hasUnseenGoodsByCategory
  shopSeenGoods
  shopUnseenGoods
  isUnseenGoods
  saveSeenGoods
  saveSeenGoodsCurrent
  onTabChange
  hasGoodsCategoryNonUpdatable

  pageScrollHandler
  calculateNewGoodsDiscount
}
