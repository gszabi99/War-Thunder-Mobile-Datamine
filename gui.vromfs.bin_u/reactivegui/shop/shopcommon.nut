from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopConst.nut" import *

let shopCategoriesCfg = [
  {
    id = SC_OTHER
    title = loc("shop/category/other")
    image = null
    gtypes = [ SGT_UNKNOWN ]
  },
  {
    id = SC_FEATURED
    title = loc("shop/category/featured")
    // TODO: replace icon
    getImage =  @(campaign) campaign == "tanks" ? "!ui/gameuiskin#shop_tanks.svg"
      : "!ui/gameuiskin#shop_ships.svg"
    gtypes = [ SGT_UNIT, SGT_LOOTBOX, SGT_BOOSTERS ]
  },
  {
    id = SC_GOLD
    title = loc("shop/category/gold")
    image = "!ui/gameuiskin#shop_eagles.svg"
    gtypes = [ SGT_GOLD ]
  },
  {
    id = SC_WP
    title = loc("shop/category/wp")
    image = "!ui/gameuiskin#shop_lions.svg"
    gtypes = [ SGT_WP ]
  },
  {
    id = SC_PLATINUM
    title = loc("shop/category/platinum")
    image = "!ui/gameuiskin#shop_wolves.svg"
    gtypes = [ SGT_PLATINUM ]
  },
  {
    id = SC_PREMIUM
    title = loc("shop/category/premium")
    image = "!ui/gameuiskin#shop_premium.svg"
    gtypes = [ SGT_PREMIUM ]
  },
  {
    id = SC_CONSUMABLES
    title = loc("shop/category/consumables")
    image = "!ui/gameuiskin#shop_consumables.svg"
    gtypes = [ SGT_CONSUMABLES ]
  }
]


function getGoodsType(goods) {
  if (goods.units.len() > 0 || (goods?.unitUpgrades.len() ?? 0) > 0 || goods?.meta.previewUnit)
    return SGT_UNIT
  if (goods.items.len() > 0)
    return SGT_CONSUMABLES
  if (goods.lootboxes.len() > 0)
    return SGT_LOOTBOX
  if (goods.premiumDays > 0)
    return SGT_PREMIUM
  if ((goods?.boosters.len() ?? 0) > 0)
    return SGT_BOOSTERS
  else if (goods.currencies.len() == 1)
    return currencyToGoodsType?[goods.currencies.findindex(@(_) true)] ?? SGT_EVT_CURRENCY
  return SGT_UNKNOWN
}

function isGoodsFitToCampaign(goods, cConfigs, curCampaign = null) {
  let { units = [], unitUpgrades = [], items = {} , meta = {}} = goods
  if (units.len() > 0)
    return null != units.findvalue(@(u) u in cConfigs?.allUnits)
  if (unitUpgrades.len() > 0)
    return null != unitUpgrades.findvalue(@(u) u in cConfigs?.allUnits)
  if (items.len() > 0)
    return null != items.findvalue(@(_, i) i in cConfigs?.allItems)
  if (meta?.campaign && meta?.campaign != curCampaign)
    return false
  return true
}

return {
  shopCategoriesCfg
  getGoodsType
  isGoodsFitToCampaign
}.__merge(shopCategories, goodsTypes)
