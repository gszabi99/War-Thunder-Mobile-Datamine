from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
from "%appGlobals/config/goodsPresentation.nut" import getCustomGoodsNameById
from "%rGui/shop/goodsView/goodsBooster.nut" import getLocNameBooster, mkGoodsBooster
from "%rGui/shop/goodsView/goodsConsumables.nut" import getLocNameConsumables, mkGoodsConsumables
from "%rGui/shop/goodsView/goodsDecal.nut" import getLocNameDecal, mkGoodsDecal
from "%rGui/shop/goodsView/goodsDecorator.nut" import getLocNameDecorator, mkGoodsDecorator
from "%rGui/shop/goodsView/goodsDefault.nut" import getLocNameDefault, mkGoodsDefault
from "%rGui/shop/goodsView/goodsEventCurrency.nut" import mkGoodsEventCurrency
from "%rGui/shop/goodsView/goodsGold.nut" import getLocNameGold, mkGoodsGold
from "%rGui/shop/goodsView/goodsLootbox.nut" import getLocNameLootbox, mkGoodsLootbox
from "%rGui/shop/goodsView/goodsPlatinum.nut" import getLocNamePlatinum, mkGoodsPlatinum
from "%rGui/shop/goodsView/goodsPremium.nut" import getLocNamePremium, mkGoodsPremium
from "%rGui/shop/goodsView/goodsSkin.nut" import mkGoodsSkin, getLocNameSkin
from "%rGui/shop/goodsView/goodsSlots.nut" import mkGoodsSlots
from "%rGui/shop/goodsView/goodsUnit.nut" import getLocNameUnit, mkGoodsUnit, mkGoodsUnitBundle, getLocBlueprintUnit,
  getLocBranchUnits
from "%rGui/shop/goodsView/goodsWp.nut" import getLocNameWp, mkGoodsWp


let customLocId = {
  battle_pass = "battlePass"
  battle_pass_vip = "battlePassVIP"
  event_pass = "eventPass"
  event_pass_vip = "eventPassVip"
  operation_pass = "operationPass"
  operation_pass_vip = "operationPassVIP"
}

let locNameGetters = {
  [SGT_UNKNOWN] = getLocNameDefault,
  [SGT_GOLD] = getLocNameGold,
  [SGT_PLATINUM] = getLocNamePlatinum,
  [SGT_WP] = getLocNameWp,
  [SGT_PREMIUM] = getLocNamePremium,
  [SGT_UNIT] = getLocNameUnit,
  [SGT_UNIT_BUNDLE] = getLocBranchUnits,
  [SGT_SKIN] = getLocNameSkin,
  [SGT_DECALS] = getLocNameDecal,
  [SGT_CONSUMABLES] = getLocNameConsumables,
  [SGT_LOOTBOX] = getLocNameLootbox,
  [SGT_BOOSTERS] = getLocNameBooster,
  [SGT_BLUEPRINTS] = getLocBlueprintUnit,
  [SGT_DECORATOR] = getLocNameDecorator,
}

let constructors = {
  [SGT_UNKNOWN] = mkGoodsDefault,
  [SGT_GOLD] = mkGoodsGold,
  [SGT_PLATINUM] = mkGoodsPlatinum,
  [SGT_WP] = mkGoodsWp,
  [SGT_PREMIUM] = mkGoodsPremium,
  [SGT_UNIT] = mkGoodsUnit,
  [SGT_UNIT_BUNDLE] = mkGoodsUnitBundle,
  [SGT_SKIN] = mkGoodsSkin,
  [SGT_DECALS] = mkGoodsDecal,
  [SGT_CONSUMABLES] = mkGoodsConsumables,
  [SGT_LOOTBOX] = mkGoodsLootbox,
  [SGT_BOOSTERS] = mkGoodsBooster,
  [SGT_SLOTS] = mkGoodsSlots,
  [SGT_DECORATOR] = mkGoodsDecorator,
  [SGT_EVT_CURRENCY] = mkGoodsEventCurrency
}

let getCustomName = @(goods) goods.meta.findindex(@(_, i) i in customLocId)

function getGoodsLocName(goods, locParam = null) {
  let res = getCustomGoodsNameById(goods.id)
  if (res != null)
    return res
  let customName = getCustomName(goods)
  return customName ? loc(customLocId[customName], { name = locParam })
    : (locNameGetters?[getGoodsType(goods)] ?? locNameGetters[SGT_UNKNOWN])(goods)
}
let mkGoods = @(goods, onClick, state, animParams = null, addChildren = [])
  (constructors?[getGoodsType(goods)] ?? constructors[SGT_UNKNOWN])(goods, onClick, state, animParams, addChildren)

return {
  getGoodsLocName
  mkGoods
}
