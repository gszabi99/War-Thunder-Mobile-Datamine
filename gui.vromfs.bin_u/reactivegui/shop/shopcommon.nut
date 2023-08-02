from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopConst.nut" import *

let shopCategoriesCfg = [
  {
    id = SC_OTHER
    title = loc("shop/category/other")
    image = ""
    gtypes = [ SGT_UNKNOWN ]
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
    id = SC_PREMIUM
    title = loc("shop/category/premium")
    image = "!ui/gameuiskin#shop_premium.svg"
    gtypes = [ SGT_PREMIUM ]
  },
  {
    id = SC_UNIT
    getTitle = @(campaign) campaign == "tanks" ? loc("shop/category/tanks")
      : loc("shop/category/ships")
    getImage =  @(campaign) campaign == "tanks" ? "!ui/gameuiskin#shop_tanks.svg"
      : "!ui/gameuiskin#shop_ships.svg"
    gtypes = [ SGT_UNIT ]
  },
  {
    id = SC_CONSUMABLES
    title = loc("shop/category/consumables")
    image = "!ui/gameuiskin#shop_consumables.svg"
    gtypes = [ SGT_CONSUMABLES ]
  }
]


let function getGoodsType(goods) {
  if (goods.units.len() > 0 || (goods?.unitUpgrades.len() ?? 0) > 0)
    return SGT_UNIT
  if (goods.items.len() > 0)
    return SGT_CONSUMABLES
  if (goods.premiumDays > 0)
    return SGT_PREMIUM
  if (goods.gold > 0)
    return SGT_GOLD
  if (goods.wp > 0)
    return SGT_WP
  return SGT_UNKNOWN
}

let function isGoodsFitToCampaign(goods, cConfigs) {
  let { units = [], unitUpgrades = [], items = {} } = goods
  if (units.len() > 0)
    return null != units.findvalue(@(u) u in cConfigs?.allUnits)
  if (unitUpgrades.len() > 0)
    return null != unitUpgrades.findvalue(@(u) u in cConfigs?.allUnits)
  if (items.len() > 0)
    return null != items.findvalue(@(_, i) i in cConfigs?.allItems)
  return true
}

return {
  shopCategoriesCfg
  getGoodsType
  isGoodsFitToCampaign
}.__merge(shopCategories, goodsTypes)
