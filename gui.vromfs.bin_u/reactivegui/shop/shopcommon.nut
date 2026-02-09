from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopConst.nut" import *
from "%appGlobals/rewardType.nut" import *
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { allow_subscriptions } = require("%appGlobals/permissions.nut")

let defaultFeaturedIcon = "ui/gameuiskin#shop_planes.svg"
let featuredIcon = {
  tanks = "ui/gameuiskin#shop_tanks.svg"
  tanks_new = "ui/gameuiskin#shop_tanks.svg"
  ships = "ui/gameuiskin#shop_ships.svg"
  ships_new = "ui/gameuiskin#shop_ships.svg"
  air = defaultFeaturedIcon
}
let defaultShopCategory = SC_FEATURED

let shopCategoriesCfg = [
  {
    id = SC_OTHER
    title = loc("shop/category/other")
    image = null
  },
  {
    id = SC_FEATURED
    title = loc("shop/category/featured")
    getImage =  @(campaign) featuredIcon?[campaign] ?? defaultFeaturedIcon
  },
  {
    id = SC_SPECIAL
    title = loc("shop/category/special")
    image = "ui/gameuiskin#shop_event.svg"
  },
  {
    id = SC_DECORATOR
    title = loc("shop/category/decorator")
    image = "ui/gameuiskin#shop_decor.svg"
  },
  {
    id = SC_GOLD
    title = loc("shop/category/gold")
    image = "ui/gameuiskin#shop_eagles.svg"
  },
  {
    id = SC_WP
    title = loc("shop/category/wp")
    image = "ui/gameuiskin#shop_lions.svg"
  },
  {
    id = SC_PLATINUM
    title = loc("shop/category/platinum")
    image = "ui/gameuiskin#shop_wolves.svg"
  },
  {
    id = SC_PREMIUM
    title = loc("shop/category/premium")
    getImage = @(_) Computed(@(_) allow_subscriptions.get() ? "ui/gameuiskin#shop_subscription.svg" : "ui/gameuiskin#shop_premium.svg")
  },
  {
    id = SC_CONSUMABLES
    title = loc("shop/category/consumables")
    image = "ui/gameuiskin#shop_consumables.svg"
  }
]

let gtypeToShopCategory = {
  [SGT_UNIT] = SC_FEATURED,
  [SGT_SLOTS] = SC_FEATURED,
  [SGT_LOOTBOX] = SC_FEATURED,
  [SGT_BLUEPRINTS] = SC_FEATURED,
  [SGT_DECALS] = SC_FEATURED,
  [SGT_GOLD] = SC_GOLD,
  [SGT_WP] = SC_WP,
  [SGT_PLATINUM] = SC_PLATINUM,
  [SGT_EVT_CURRENCY] = SC_FEATURED,
  [SGT_PREMIUM] = SC_PREMIUM,
  [SGT_CONSUMABLES] = SC_CONSUMABLES,
  [SGT_BOOSTERS] = SC_CONSUMABLES,
  [SGT_DECORATOR] = SC_DECORATOR,
  [SGT_SKIN] = SC_FEATURED,
}

let getShopCategory = @(gtype) gtypeToShopCategory?[gtype] ?? SC_OTHER

let rTypeToGTypeCommon = {
  [G_BLUEPRINT] = SGT_BLUEPRINTS,
  [G_BOOSTER] = SGT_BOOSTERS,
  [G_CURRENCY] = SGT_EVT_CURRENCY,
  [G_DECORATOR] = SGT_DECORATOR,
  [G_ITEM] = SGT_CONSUMABLES,
  [G_LOOTBOX] = SGT_LOOTBOX,
  [G_PREMIUM] = SGT_PREMIUM,
  [G_SKIN] = SGT_SKIN,
  [G_DECAL] = SGT_DECALS,
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

  let { gType = null } = goods.rewards?[0]
  return rTypeToGTypeComplex?[gType](goods.rewards) ?? rTypeToGTypeCommon?[gType] ?? SGT_UNKNOWN
}

let isGoodsFit = {
  [G_UNIT] = @(r, cConfigs) r.id in cConfigs?.allUnits,
  [G_UNIT_UPGRADE] = @(r, cConfigs) r.id in cConfigs?.allUnits,
  [G_BLUEPRINT] = @(r, cConfigs) r.id in cConfigs?.allUnits,
  [G_SKIN] = @(r, cConfigs) r.id in cConfigs?.allUnits,
  [G_ITEM] = @(r, cConfigs) r.id in cConfigs?.allItems,
}

function isGoodsFitToCampaign(goods, cConfigs, curCampaign) {
  let { meta, rewards } = goods
  if (((meta?.campaign ?? curCampaign) != curCampaign) || ((meta?.showAsOffer ?? curCampaign) != curCampaign))
    return false

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
