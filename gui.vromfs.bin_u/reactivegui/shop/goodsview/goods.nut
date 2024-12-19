from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { getLocNameDefault, mkGoodsDefault } = require("%rGui/shop/goodsView/goodsDefault.nut")
let { getLocNameGold, mkGoodsGold } = require("%rGui/shop/goodsView/goodsGold.nut")
let { getLocNameWp, mkGoodsWp } = require("%rGui/shop/goodsView/goodsWp.nut")
let { getLocNamePlatinum, mkGoodsPlatinum } = require("%rGui/shop/goodsView/goodsPlatinum.nut")
let { getLocNamePremium, mkGoodsPremium } = require("%rGui/shop/goodsView/goodsPremium.nut")
let { getLocNameUnit, mkGoodsUnit, getLocBlueprintUnit, getLocBranchUnits } = require("%rGui/shop/goodsView/goodsUnit.nut")
let { getLocNameConsumables, mkGoodsConsumables } = require("%rGui/shop/goodsView/goodsConsumables.nut")
let { getLocNameLootbox, mkGoodsLootbox } = require("%rGui/shop/goodsView/goodsLootbox.nut")
let { getLocNameBooster, mkGoodsBooster } = require("%rGui/shop/goodsView/goodsBooster.nut")
let { mkGoodsEventCurrency } = require("%rGui/shop/goodsView/goodsEventCurrency.nut")
let { mkGoodsSlots } = require("%rGui/shop/goodsView/goodsSlots.nut")
let { getLocNameDecorator, mkGoodsDecorator } = require("%rGui/shop/goodsView/goodsDecorator.nut")


let customLocId = {
  battle_pass = "battlePass"
  battle_pass_vip = "battlePassVIP"
}

let locNameGetters = {
  [SGT_UNKNOWN] = getLocNameDefault,
  [SGT_GOLD] = getLocNameGold,
  [SGT_PLATINUM] = getLocNamePlatinum,
  [SGT_WP] = getLocNameWp,
  [SGT_PREMIUM] = getLocNamePremium,
  [SGT_UNIT] = getLocNameUnit,
  [SGT_CONSUMABLES] = getLocNameConsumables,
  [SGT_LOOTBOX] = getLocNameLootbox,
  [SGT_BOOSTERS] = getLocNameBooster,
  [SGT_BLUEPRINTS] = getLocBlueprintUnit,
  [SGT_DECORATOR] = getLocNameDecorator,
  [SGT_BRANCH] = getLocBranchUnits
}

let constructors = {
  [SGT_UNKNOWN] = mkGoodsDefault,
  [SGT_GOLD] = mkGoodsGold,
  [SGT_PLATINUM] = mkGoodsPlatinum,
  [SGT_WP] = mkGoodsWp,
  [SGT_PREMIUM] = mkGoodsPremium,
  [SGT_UNIT] = mkGoodsUnit,
  [SGT_CONSUMABLES] = mkGoodsConsumables,
  [SGT_LOOTBOX] = mkGoodsLootbox,
  [SGT_BOOSTERS] = mkGoodsBooster,
  [SGT_SLOTS] = mkGoodsSlots,
  [SGT_DECORATOR] = mkGoodsDecorator,
  [SGT_EVT_CURRENCY] = mkGoodsEventCurrency
}

let getCustomName = @(goods) goods.meta.findindex(@(_, i) i in customLocId)

let function getGoodsLocName(goods){
  let customName = getCustomName(goods)
  return customName ? loc(customLocId[customName])
    : (locNameGetters?[goods.gtype] ?? locNameGetters[SGT_UNKNOWN])(goods)
}
let mkGoods = @(goods, onClick, state, animParams = null, addChildren = [])
  (constructors?[goods.gtype] ?? constructors[SGT_UNKNOWN])(goods, onClick, state, animParams, addChildren)

return {
  getGoodsLocName
  mkGoods
}
