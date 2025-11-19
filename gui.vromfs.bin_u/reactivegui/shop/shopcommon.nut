from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopConst.nut" import *
from "%appGlobals/rewardType.nut" import *
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")

let defaultFeaturedIcon = "!ui/gameuiskin#shop_planes.svg"
let featuredIcon = {
  tanks = "!ui/gameuiskin#shop_tanks.svg"
  tanks_new = "!ui/gameuiskin#shop_tanks.svg"
  ships = "!ui/gameuiskin#shop_ships.svg"
  ships_new = "!ui/gameuiskin#shop_ships.svg"
  air = defaultFeaturedIcon
}
let defaultShopCategory = SC_EVENTS

let shopCategoriesCfg = [
  {
    id = SC_OTHER
    title = loc("shop/category/other")
    image = null
  },
  {
    id = SC_EVENTS
    title = loc("shop/category/events")
    image = "ui/gameuiskin#shop_event.svg"
  },
  {
    id = SC_FEATURED
    title = loc("shop/category/featured")
    getImage =  @(campaign) featuredIcon?[campaign] ?? defaultFeaturedIcon
  },
  {
    id = SC_GOLD
    title = loc("shop/category/gold")
    image = "!ui/gameuiskin#shop_eagles.svg"
  },
  {
    id = SC_WP
    title = loc("shop/category/wp")
    image = "!ui/gameuiskin#shop_lions.svg"
  },
  {
    id = SC_PLATINUM
    title = loc("shop/category/platinum")
    image = "!ui/gameuiskin#shop_wolves.svg"
  },
  {
    id = SC_PREMIUM
    title = loc("shop/category/premium")
    image = "!ui/gameuiskin#shop_premium.svg"
  },
  {
    id = SC_CONSUMABLES
    title = loc("shop/category/consumables")
    image = "!ui/gameuiskin#shop_consumables.svg"
  }
]

let gtypeToShopCategory = {
  [SGT_UNIT] = SC_FEATURED,
  [SGT_SLOTS] = SC_FEATURED,
  [SGT_LOOTBOX] = SC_FEATURED,
  [SGT_BLUEPRINTS] = SC_FEATURED,
  [SGT_GOLD] = SC_GOLD,
  [SGT_WP] = SC_WP,
  [SGT_PLATINUM] = SC_PLATINUM,
  [SGT_PREMIUM] = SC_PREMIUM,
  [SGT_CONSUMABLES] = SC_CONSUMABLES,
  [SGT_BOOSTERS] = SC_CONSUMABLES,
  [SGT_DECORATOR] = SC_FEATURED,
}

let getShopCategory = @(gtype, meta = {}) "eventId" in meta ? SC_EVENTS
  : gtypeToShopCategory?[gtype] ?? SC_OTHER

let rTypeToGTypeCommon = {
  [G_BLUEPRINT] = SGT_BLUEPRINTS,
  [G_BOOSTER] = SGT_BOOSTERS,
  [G_CURRENCY] = SGT_EVT_CURRENCY,
  [G_DECORATOR] = SGT_DECORATOR,
  [G_ITEM] = SGT_CONSUMABLES,
  [G_LOOTBOX] = SGT_LOOTBOX,
  [G_PREMIUM] = SGT_PREMIUM,
  [G_SKIN] = SGT_SKIN,
  [G_UNIT_UPGRADE] = SGT_UNIT,
}

let rTypeToGTypeComplex = {
  [G_UNIT] = function(rewards) {
    local units = 0
    local upgrades = 0
    foreach (r in rewards)
      if (r.gType == G_UNIT)
        units++
      else if (r.gType == G_UNIT_UPGRADE)
        upgrades++
    return upgrades == 0 && units > 1 ? SGT_BRANCH : SGT_UNIT 
  },
  [G_CURRENCY] = @(rewards) currencyToGoodsType?[rewards[0].id] ?? SGT_EVT_CURRENCY,
}

function getGoodsType(goods) {
  if ((goods?.slotsPreset ?? "") != "")
    return SGT_SLOTS
  if ((goods?.meta.previewUnit ?? "") != "")
    return SGT_UNIT

  if ("rewards" in goods) {
    let { gType = null } = goods.rewards?[0]
    return rTypeToGTypeComplex?[gType](goods.rewards) ?? rTypeToGTypeCommon?[gType] ?? SGT_UNKNOWN
  }

  
  if (goods.units.len() == 1 || (goods?.unitUpgrades.len() ?? 0) > 0)
    return SGT_UNIT
  if (goods.units.len() >= 2 )
    return SGT_BRANCH
  if (goods.skins.len() > 0)
    return SGT_SKIN
  if (goods.items.len() > 0)
    return SGT_CONSUMABLES
  if (goods.lootboxes.len() > 0)
    return SGT_LOOTBOX
  if (goods.premiumDays > 0)
    return SGT_PREMIUM
  if ((goods?.boosters.len() ?? 0) > 0)
    return SGT_BOOSTERS
  if ((goods?.decorators.len() ?? 0) > 0)
    return SGT_DECORATOR
  if ((goods?.blueprints.len() ?? 0) > 0)
    return SGT_BLUEPRINTS
  else if (goods.currencies.len() == 1)
    return currencyToGoodsType?[goods.currencies.findindex(@(_) true)] ?? SGT_EVT_CURRENCY
  return SGT_UNKNOWN
}

let isGoodsFit = {
  [G_UNIT] = @(r, cConfigs) r.id in cConfigs?.allUnits,
  [G_UNIT_UPGRADE] = @(r, cConfigs) r.id in cConfigs?.allUnits,
  [G_BLUEPRINT] = @(r, cConfigs) r.id in cConfigs?.allUnits,
  [G_SKIN] = @(r, cConfigs) r.id in cConfigs?.allUnits,
  [G_ITEM] = @(r, cConfigs) r.id in cConfigs?.allItems,
}

function isGoodsFitToCampaign(goods, cConfigs, curCampaign) {
  let { meta = {}, rewards = null } = goods
  if (meta?.campaign && meta?.campaign != curCampaign)
    return false

  if (rewards != null) {
    local hasCampRewards = false
    foreach (r in rewards) {
      if (r.gType not in isGoodsFit)
        continue
      hasCampRewards = true
      if (isGoodsFit[r.gType](r, cConfigs))
        return true
    }
    return !hasCampRewards
  }

  
  let { units = [], unitUpgrades = [], skins = {}, items = {}, blueprints = {} } = goods
  if (units.len() > 0)
    return null != units.findvalue(@(u) u in cConfigs?.allUnits)
  if (blueprints.len() > 0)
    return null != units.findvalue(@(u) u in cConfigs?.allUnits)
  if (unitUpgrades.len() > 0)
    return null != unitUpgrades.findvalue(@(u) u in cConfigs?.allUnits)
  if (skins.len() > 0)
    return null != skins.findvalue(@(_, u) u in cConfigs?.allUnits)
  if (items.len() > 0)
    return null != items.findvalue(@(_, i) i in cConfigs?.allItems)
  return true
}

function getSubsPeriodString(subs) {
  let { duration = 0, billingPeriod = null } = subs
  if (duration > 0)
    return secondsToHoursLoc(duration)

  if (billingPeriod == null)
    return ""
  if (billingPeriod.len() == 1)
    foreach (period, n in billingPeriod) {
      let locId = n == 1 ? $"measureUnits/single/{period}" : $"measureUnits/full/{period}"
      return loc(locId, { n }) 
    }

  let list = []
  foreach (period, n in billingPeriod)
    list.append(loc($"measureUnits/full/{period}", { n }))
  return comma.join(list)
}

return {
  defaultShopCategory
  shopCategoriesCfg
  getShopCategory
  getGoodsType
  isGoodsFitToCampaign
  getSubsPeriodString
}.__merge(shopCategories, goodsTypes)
