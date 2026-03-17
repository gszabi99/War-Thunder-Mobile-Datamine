from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { isEqual } = require("%sqstd/underscore.nut")
let { TIME_DAY_IN_SECONDS } = require("%sqstd/time.nut")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { orderByItems } = require("%appGlobals/itemsState.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { serverTimeDay } = require("%appGlobals/userstats/serverTimeDay.nut")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { campConfigs, curCampaign, todayPurchasesCount } = require("%appGlobals/pServer/campaign.nut")
let { can_debug_shop, allow_subscriptions } = require("%appGlobals/permissions.nut")
let { WP, GOLD, PLATINUM } = require("%appGlobals/currenciesState.nut")
let { sortByCurrencyId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { G_PREMIUM, G_ITEM } = require("%appGlobals/rewardType.nut")
let { resetExtTimeout, clearExtTimer } = require("%appGlobals/timeoutExt.nut")
let { sendBqEventOnOpenCurrencyShop } = require("%rGui/shop/bqPurchaseInfo.nut")
let { actualSchRewardByCategory, actualSchRewards, lastAppliedSchReward, schRewards
} = require("%rGui/shop/schRewardsState.nut")
let { platformGoods, platformSubs } = require("%rGui/shop/platformGoods.nut")
let { personalGoodsByShopCategory, personalGoodsUnseenIds, markPersonalGoodsSeen, resetSeenPersonalGoods
} = require("%rGui/shop/personalGoodsState.nut")
let { shopGoodsToRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")


let SEEN_GOODS = "shopSeenGoods_v2"
let UNMARK_SEEN_COUNTERS = "unmarkSeenCounters"
let EXPIRATION_DAYS = 28

let pageScrollHandler = ScrollHandler()

let isShopOpened = mkWatched(persist, "isShopOpened", false)
let shopOpenCount = Watched(0)
let shopId = mkWatched(persist, "shopId", null)
let prevShopId = mkWatched(persist, "prevShopId", null)
let prevCategoryId = mkWatched(persist, "prevCategoryId", null)
let curCategoryId = mkWatched(persist, "curCategoryId", null)
let shopSeenGoods = mkWatched(persist, "shopSeenGoods", {})
let unmarkSeenCounters = mkWatched(persist, "unmarkSeenCounters", {})

isShopOpened.subscribe(function(v) {
  if (v)
    return
  shopId.set(null)
  prevShopId.set(null)
  curCategoryId.set(null)
  prevCategoryId.set(null)
})

let categoryByCurrency = {
  [WP] = SC_WP,
  [GOLD] = SC_GOLD,
  [PLATINUM] = SC_PLATINUM
}

let sortByGType = {
  [G_ITEM] = @(a, b) (orderByItems?[a.id] ?? 1000) <=> (orderByItems?[b.id] ?? 1000),
}

let sortGoodsByReward = @(a, b) (b == null) <=> (a == null)
  || (a == null ? 0
    : a.gType <=> b.gType
        || (sortByGType?[a.gType](a, b) ?? 0)
        || (a.id == b.id ? (a.count <=> b.count) : 0))

let sortGoods = @(a, b)
  b.meta?.eventId <=> a.meta?.eventId
  || b.meta?.order <=> a.meta?.order
  || b.slotsPreset <=> a.slotsPreset
  || sortByCurrencyId(a.price.currencyId, b.price.currencyId)
  || getGoodsType(a) <=> getGoodsType(b)
  || sortGoodsByReward(a.rewards?[0], b.rewards?[0])
  || a.price.price <=> b.price.price
  || a.id <=> b.id

let goodsWithTimers = Computed(@() (campConfigs.get()?.allGoods ?? {})
  .filter(@(g) g.timeRanges.len() > 0))
let inactiveGoodsByTime = Watched({})
let finishedGoodsByTime = Watched({})
let soonGoodsByTime = Watched({})
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

let shopsCfgOrdered = [
  {
    id = "events2"
    isFit = @(g) g?.meta.shopId == "2"
  }
  {
    id = "events"
    isFit = @(g) g?.meta.shopId == "1" || "eventId" in g?.meta
  }
  {
    id = "common"
    isFit = @(g) !g?.isHidden
  }
]

let getGoodsShopId = @(g) shopsCfgOrdered.findvalue(@(c) c.isFit(g))?.id
let searchOrder = ["common", "events", "events2"]

function updateGoodsTimers() {
  let inactive = {}
  let finished = {}
  let soon = {}
  local nextTime = null
  let curTime = serverTime.get()
  let isValid = isServerTimeValid.get()
  foreach(id, goods in goodsWithTimers.get()) {
    if (!isValid) {
      inactive[id] <- true
      continue
    }

    let { timeRanges, dailyLimit, showTimeBeforeActivate = 0 } = goods
    if (timeRanges.len() == 0)
      continue
    local isActive = false
    local hasNext = false
    foreach (tr in timeRanges) {
      let { start, end } = tr
      if (start > curTime) {
        nextTime = min(nextTime ?? start, start)
        hasNext = true

        if (showTimeBeforeActivate > 0)
          if (start - showTimeBeforeActivate > curTime)
            nextTime = min(nextTime, start - showTimeBeforeActivate)
          else
            soon[id] <- true
        break
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
  if (!isEqual(soon, soonGoodsByTime.get()))
    soonGoodsByTime.set(soon)
  nextUpdateTime.set({ time = nextTime ?? 0 })
}

nextUpdateTime.subscribe(function(v) {
  let { time } = v
  if (time == 0)
    clearExtTimer(updateGoodsTimers)
  else
    resetExtTimeout(max(0.5, time - serverTime.get()), updateGoodsTimers)
})

updateGoodsTimers()
goodsWithTimers.subscribe(@(_) updateGoodsTimers())
isServerTimeValid.subscribe(@(_) updateGoodsTimers())
todayPurchasesCount.subscribe(@(_ ) updateGoodsTimers())

let allowWithSubs = @(goods) null == goods.rewards.findvalue(@(r) r.gType == G_PREMIUM)

let shopGoodsInternal = Computed(@()(campConfigs.get()?.allGoods ?? {})
  .filter(@(g) (can_debug_shop.get() || !g.isShowDebugOnly)
    && ((g?.price.price ?? 0) > 0 || null != g?.dailyPriceInc.findvalue(@(cfg) cfg.price > 0))))

let allCampaignsShopGoods = Computed(function() {
  let res = shopGoodsInternal.get().__merge(platformGoods.get())
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
    let cat = getShopCategory(getGoodsType(goods))
    if (cat not in res)
      res[cat] <- []
    res[cat].append(goods)
  }
  return res
})

let soonGoodsByShop = Computed(function() {
  let res = shopsCfgOrdered.reduce(@(res, v) res.$rawset(v.id, {}), {})
  let soon = soonGoodsByTime.get()
  foreach (id, goods in allShopGoods.get())
    if (id in soon) {
      let sId = getGoodsShopId(goods)
      if (sId in res)
        getSubArray(res[sId], getShopCategory(getGoodsType(goods))).append(goods)
    }
  return res
})

let mkGoodsByShop = @(gByCategoryW) Computed(function() {
  let res = shopsCfgOrdered.reduce(@(res, v) res.$rawset(v.id, {}), {})
  foreach(catId, goodsList in gByCategoryW.get())
    foreach(goods in goodsList)
      getSubArray(res[getGoodsShopId(goods)], catId).append(goods)
  return res
})

let goodsByShop = mkGoodsByShop(goodsByCategory)

let personalGoodsByShop = mkGoodsByShop(personalGoodsByShopCategory)

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

let goodsIdsByShop = Computed(function() {
  let res = {}
  foreach (sId, goodsByCat in goodsByShop.get()) {
    let shopList = getSubTable(res, sId)
    foreach (cat, gList in goodsByCat) {
      let resList = getSubArray(shopList, cat)
      gList.each(@(g) resList.append(g.id))
    }
  }
  foreach (sId, goodsByCat in personalGoodsByShop.get()) {
    let shopList = getSubTable(res, sId)
    foreach (cat, gList in goodsByCat) {
      let resList = getSubArray(shopList, cat)
      gList.each(@(g) resList.append(g.id))
    }
  }
  let commonShop = getSubTable(res, "common")
  foreach (cat, sReward in actualSchRewardByCategory.get())
    getSubArray(commonShop, cat).append(sReward.id)
  foreach (cat, list in subsByCategory.get())
    getSubArray(commonShop, cat).extend(list.map(@(v) v.id))
  return res
})

function unmarkSeenGoods(unmarkSeen, unmarkCounters = {}) {
  let toRemove = unmarkSeen.filter(@(id) id in shopSeenGoods.get())
  let counters = unmarkCounters.filter(@(id, count) unmarkSeenCounters.get()?[id] != count)
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
    unmarkSeenCounters.set(unmarkSeenCounters.get().__merge(counters))
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

  let reward = schRewards.get()?[rewardId]
  let { needAdvert = false } = reward
  if (reward != null && !needAdvert) {
    let gtype = getGoodsType(reward)
    foreach(id, rew in schRewards.get())
      if (getGoodsType(rew) == gtype && id != rewardId && rew.needAdvert) {
        unmarkSeen.append(id)
        unmarkCounters[id] <- 1
      }
  }

  unmarkSeenGoods(unmarkSeen, unmarkCounters)
})

isInDebriefing.subscribe(function(v) {
  if (!v)
    unmarkSeenGoods(unmarkSeenCounters.get().filter(@(c) c == 0).keys())
})

function saveSeenGoods(ids) {
  let upd = {}
  let cUpd = {}
  markPersonalGoodsSeen(ids)
  let today = serverTimeDay.get()
  foreach(id in ids) {
    if (shopSeenGoods.get()?[id])
      continue
    let schReward = actualSchRewards.get()?[id]
    if (schReward != null && (!schReward.needAdvert || !schReward.isReady))
      continue
    upd[id] <- today
    if (id in unmarkSeenCounters.get())
      cUpd[id] <- unmarkSeenCounters.get()[id] - 1
  }
  if (upd.len() == 0)
    return

  let curSeenFull = shopSeenGoods.get().__merge(upd)
  let exclude = inactiveGoodsByTime.get()
  foreach (id, _ in allCampaignsShopGoods.get()) 
    if (id not in exclude && id in curSeenFull)
      curSeenFull[id] <- today
  let curSeen = curSeenFull.filter(@(v) v > today - EXPIRATION_DAYS)

  let sBlk = get_local_custom_settings_blk()
  shopSeenGoods.set(curSeen)
  let seenBlk = sBlk.addBlock(SEEN_GOODS)
  seenBlk.clearData()
  foreach (id, v in curSeen)
    seenBlk[id] = v

  if (cUpd.len() != 0) {
    unmarkSeenCounters.set(unmarkSeenCounters.get().__merge(cUpd))
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

function applyCompatibility(blk) {
  let prevSeen = blk?.shopSeenGoods
  if (!isDataBlock(prevSeen))
    return

  let day = serverTimeDay.get() - EXPIRATION_DAYS - 1
  let newSeen = blk.addBlock(SEEN_GOODS)
  eachParam(prevSeen, function(isSeen, id) {
    if (isSeen)
      newSeen[id] = day
  })
  blk.removeBlock("shopSeenGoods")
}

function loadSeenGoods() {
  if (!isSettingsAvailable.get())
    return resetSeenGoods()
  let blk = get_local_custom_settings_blk()
  applyCompatibility(blk)

  let seenBlk = blk?[SEEN_GOODS]
  let seen = {}
  if (isDataBlock(seenBlk))
    eachParam(seenBlk, @(day, id) seen[id] <- day)
  shopSeenGoods.set(seen)

  let countersBlk = blk?[UNMARK_SEEN_COUNTERS]
  let counters = {}
  if (isDataBlock(countersBlk))
    eachParam(countersBlk, @(v, id) counters[id] <- v)
  unmarkSeenCounters.set(counters)
}

if (shopSeenGoods.get().len() == 0)
  loadSeenGoods()

isSettingsAvailable.subscribe(@(_) loadSeenGoods())

let isUnseenGoods = @(id, seenGoods, actSchRewards) (id not in seenGoods
  && (id not in actSchRewards || actSchRewards?[id]?.isReady == true))

let shopUnseenGoods = Computed(function() {
  let res = {}
  foreach (cats in goodsIdsByShop.get())
    foreach (ids in cats)
      foreach (id in ids)
        if (isUnseenGoods(id, shopSeenGoods.get(), actualSchRewards.get()) || (personalGoodsUnseenIds.get()?[id] ?? false))
          res[id] <- true
  return res
})

function isDisabledGoods(reward, allGoods, servConfigs) {
  if (reward?.rType == "discount" || reward?.gType == "discount") {
    let goodsId = servConfigs?.personalDiscounts.findindex(@(list) list.findindex(@(v) v.id == reward.id) != null)
    let previewReward = goodsId in allGoods
      ? shopGoodsToRewardsViewInfo(allGoods[goodsId]).sort(sortRewardsViewInfo)?[0]
      : null
    if (!goodsId || !previewReward)
      return true
  }
  return false
}

let hasGoodsCategoryNonUpdatable = @(catId) catId in goodsByCategory.get()
  || catId in personalGoodsByShopCategory.get()
  || catId in actualSchRewardByCategory.get()
  || catId in subsByCategory.get()

function openShopWnd(catId = null, bqPurchaseInfo = null, sId = "common") {
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return
  }
  if (shopId.get() != sId){
    prevShopId.set(shopId.get())
    prevCategoryId.set(curCategoryId.get())
    shopId.set(sId)
  }
  curCategoryId.set(hasGoodsCategoryNonUpdatable(catId) ? catId
    : shopCategoriesCfg.findvalue(@(c) hasGoodsCategoryNonUpdatable(c.id))?.id)
  shopOpenCount.set(shopOpenCount.get() + 1)
  sendBqEventOnOpenCurrencyShop(bqPurchaseInfo)
  isShopOpened.set(true)
}

function openShopWndByGoods(goods) {
  openShopWnd(getShopCategory(getGoodsType(goods)), null, getGoodsShopId(goods))
  deferOnce(@() anim_start($"attract_goods_{goods.id}"))
}

let curShopActualSchRewardsByCategory = Computed(function() {
  let res = {}
  foreach(catId, goods in actualSchRewardByCategory.get())
    if(shopId.get() != null && getGoodsShopId(goods) == shopId.get()) {
      res.$rawset(catId, goods)
    }
  return res
})

let curShopGoodsByCategory = Computed(@() goodsByShop.get()?[shopId.get()])
let curShopSoonGoodsByCategory = Computed(@() soonGoodsByShop.get()?[shopId.get()])

let getCurShopGoodsByCategory = @(goodsByCategoryW) Computed(function() {
  let res = {}
  foreach(catId, goodsList in goodsByCategoryW.get())
    foreach (goods in goodsList)
      if(getGoodsShopId(goods) == shopId.get()) {
        getSubArray(res, catId).append(goods)
      }
  return res
})

let curShopPersonalGoodsByCategory = Computed(@() personalGoodsByShop.get()?[shopId.get()])

let curShopSubsByCategory = getCurShopGoodsByCategory(subsByCategory)

let hasUnseenGoodsByShop = Computed(function() {
  let unseen = shopUnseenGoods.get()
  return goodsIdsByShop.get().map(@(idsByCat)
    idsByCat.map(@(ids) null != ids.findvalue(@(id) id in unseen)))
})

let saveSeenGoodsCurrent = @() saveSeenGoods(goodsIdsByShop.get()?[shopId.get()][curCategoryId.get()] ?? [])

function onTabChange(id) {
  saveSeenGoodsCurrent()
  curCategoryId.set(id)
}

let openShopWndByCurrencyId = @(currencyId, bqPurchaseInfo = null)
  openShopWnd(categoryByCurrency?[currencyId], bqPurchaseInfo?.__merge({ id = currencyId }))

function findGoodsByShop(goodsByShopV, isFit) {
  foreach (sId in searchOrder)
    foreach (catId, list in goodsByShopV?[sId] ?? {})
      foreach (goods in list)
        if (isFit(goods))
          return { shop = sId, category = catId }
  return { shop = null, category = null }
}

register_command(function() {
  shopSeenGoods.set({})
  get_local_custom_settings_blk().removeBlock(SEEN_GOODS)
  get_local_custom_settings_blk().removeBlock(UNMARK_SEEN_COUNTERS)
  resetSeenPersonalGoods()
  eventbus_send("saveProfile", {})
  log("Success")
}, "debug.reset_seen_goods")

register_command(@() console_print(shopSeenGoods.get()), "debug.log_seen_goods") 

return {
  openShopWnd
  openShopWndByCurrencyId
  openShopWndByGoods
  isShopOpened
  shopOpenCount

  curCategoryId
  prevCategoryId
  goodsByCategory
  allShopGoods
  shopGoodsAllCampaigns
  shopGoods
  shopGoodsInternal
  goodsLinks
  sortGoods
  inactiveGoodsByTime
  finishedGoodsByTime
  soonGoodsByTime
  allSubs
  subsGroups
  subsByCategory

  hasUnseenGoodsByShop
  shopSeenGoods
  shopUnseenGoods
  isUnseenGoods
  saveSeenGoods
  saveSeenGoodsCurrent
  onTabChange
  hasGoodsCategoryNonUpdatable

  pageScrollHandler
  isDisabledGoods

  shopId
  prevShopId
  goodsByShop
  goodsIdsByShop
  soonGoodsByShop
  curShopActualSchRewardsByCategory
  curShopGoodsByCategory
  curShopSoonGoodsByCategory
  curShopPersonalGoodsByCategory
  curShopSubsByCategory

  findGoodsByShop
}
