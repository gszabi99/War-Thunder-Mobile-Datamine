from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { can_debug_shop } = require("%appGlobals/permissions.nut")
let { platformGoods } = require("platformGoods.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { actualSchRewardByCategory, actualSchRewards, watchedSchRewardAd } = require("schRewardsState.nut")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")

let isShopOpened = mkWatched(persist, "isShopOpened", false)
let shopOpenCount = Watched(0)

let curCategoryId = mkWatched(persist, "curCategoryId", null)

let SEEN_GOODS = "shopSeenGoods"
let shopSeenGoods = mkWatched(persist, "shopSeenGoods", {})

let categoryByCurrency = {
  [WP] = SC_WP,
  [GOLD] = SC_GOLD,
}

let sortGoods = @(a, b)
  a.gtype <=> b.gtype
  || a.gold <=> b.gold
  || a.wp <=> b.wp
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

let function removeSeenGood(id) {
  if (id not in shopSeenGoods.value)
    return
  shopSeenGoods.mutate(@(v) delete v[id])
  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(SEEN_GOODS)
  blk[id] = null
  send("saveProfile", {})
}
watchedSchRewardAd.subscribe(@(v) removeSeenGood(v.schRewardId))

let function saveSeenGoods(ids) {
  shopSeenGoods.mutate(function(v) {
    foreach (id in ids) {
      let schReward = actualSchRewards.value?[id]
      if (schReward?.needAdvert == false || schReward?.isReady == false)
        continue
      v[id] <- true
    }
  })
  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(SEEN_GOODS)
  foreach (id, isSeen in shopSeenGoods.value)
    if (isSeen)
      blk[id] = true
  send("saveProfile", {})
}

let function loadSeenGoods() {
  let blk = get_local_custom_settings_blk()
  let htBlk = blk?[SEEN_GOODS]
  if (!isDataBlock(htBlk)) {
    shopSeenGoods({})
    return
  }
  let res = {}
  eachParam(htBlk, @(isSeen, id) res[id] <- isSeen)
  shopSeenGoods(res)
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

let saveSeenGoodsCurrent = @() !hasUnseenGoodsByCategory.value[curCategoryId.value] ? null
  : saveSeenGoods(goodsIdsByCategory.value[curCategoryId.value])

let function onTabChange(id) {
  saveSeenGoodsCurrent()
  curCategoryId(id)
}

let function openShopWnd(catId = null) {
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return
  }

  curCategoryId(catId in goodsByCategory.value ? catId
    : shopCategoriesCfg.findvalue(@(c) c.id in goodsByCategory.value)?.id)
  shopOpenCount(shopOpenCount.value + 1)
  isShopOpened(true)
}

let openShopWndByCurrencyId = @(currencyId) openShopWnd(categoryByCurrency?[currencyId])

register_command(function() {
  shopSeenGoods({})
  get_local_custom_settings_blk().removeBlock(SEEN_GOODS)
  send("saveProfile", {})
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
