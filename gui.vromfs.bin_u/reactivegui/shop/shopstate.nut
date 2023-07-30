from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { can_debug_shop } = require("%appGlobals/permissions.nut")
let { platformGoods } = require("platformGoods.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

let isShopOpened = mkWatched(persist, "isShopOpened", false)
let shopOpenCount = Watched(0)

let curCategoryId = mkWatched(persist, "curCategoryId", null)

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

return {
  openShopWnd
  openShopWndByCurrencyId
  isShopOpened
  shopOpenCount

  curCategoryId
  goodsByCategory
  shopGoods
  shopGoodsInternal

  sortGoods
}
