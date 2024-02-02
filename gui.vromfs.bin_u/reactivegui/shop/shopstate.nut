from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { can_debug_shop } = require("%appGlobals/permissions.nut")
let { platformGoods } = require("platformGoods.nut")
let { WP, GOLD, PLATINUM } = require("%appGlobals/currenciesState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { actualSchRewardByCategory, actualSchRewards, lastAppliedSchReward, schRewards
} = require("schRewardsState.nut")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { sendBqEventOnOpenCurrencyShop } = require("%rGui/shop/bqPurchaseInfo.nut")
let { isInDebriefing } = require("%appGlobals/clientState/clientState.nut")

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

let sortCurrency = @(a, b) "currencies" not in a //compatibility with format before 2024.01.23
  ? a.gold <=> b.gold
    || a.wp <=> b.wp
  : (a.currencies?.platinum ?? 0) <=> (b.currencies?.platinum ?? 0)
    || (a.currencies?.gold ?? 0) <=> (b.currencies?.gold ?? 0)
    || (a.currencies?.wp ?? 0) <=> (b.currencies?.wp ?? 0)

let sortGoods = @(a, b)
  a.gtype <=> b.gtype
  || sortCurrency(a, b)
  || a.premiumDays <=> b.premiumDays
  || a.price.currencyId <=> b.price.currencyId
  || a.price.price <=> b.price.price
  || a.id <=> b.id

let shopGoodsInternal = Computed(@() (campConfigs.value?.allGoods ?? {})
  .filter(@(g) (can_debug_shop.value || !g.isShowDebugOnly)
    && (g?.price.price ?? 0) > 0
    && isGoodsFitToCampaign(g, campConfigs.value))
  .map(@(g) g.__merge({ gtype = getGoodsType(g) }))
)

let shopGoods = Computed(@() shopGoodsInternal.value
  .__merge(
    platformGoods.value.filter(@(g) isGoodsFitToCampaign(g, campConfigs.value))
      .map(@(g) g.__merge({ gtype = getGoodsType(g) })))
)

let goodsByCategory = Computed(function() {
  let res = {}
  let goodsListByType = {}
  foreach (c in shopCategoriesCfg) {
    let list = []
    res[c.id] <- list
    foreach (gt in c.gtypes)
      goodsListByType[gt] <- list
  }
  foreach (goods in shopGoods.value) {
    if (goods.isHidden) // Hidden for shop
      continue
    goodsListByType[goods.gtype].append(goods)
  }
  return res.filter(@(list) list.len() > 0)
})

let goodsIdsByCategory = Computed(function() {
  let goods = {}
  foreach (cat, val in goodsByCategory.value){
    goods[cat] <- []
    val.map(@(item) goods[cat].append(item?.id))
    if (actualSchRewardByCategory.value?[cat]?.id)
      goods[cat].append(actualSchRewardByCategory.value[cat].id)
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

function loadSeenGoods() {
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

let shopUnseenGoods = Computed(function() {
  let res = {}
  foreach (ids in goodsIdsByCategory.value)
    foreach (id in ids)
      if (id not in shopSeenGoods.value
          && (id not in actualSchRewards.value || actualSchRewards.value?[id]?.isReady == true))
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

function openShopWnd(catId = null, bqPurchaseInfo = null) {
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return
  }

  curCategoryId(catId in goodsByCategory.value ? catId
    : shopCategoriesCfg.findvalue(@(c) c.id in goodsByCategory.value)?.id)
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
  goodsIdsByCategory
  shopGoods
  shopGoodsInternal
  sortGoods

  hasUnseenGoodsByCategory
  shopSeenGoods
  shopUnseenGoods
  saveSeenGoods
  saveSeenGoodsCurrent
  onTabChange
}
