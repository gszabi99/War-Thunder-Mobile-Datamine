from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { getLocNameUnknown, mkGoodsUnknown } = require("%rGui/shop/goodsView/goodsUnknown.nut")
let { getLocNameGold, mkGoodsGold } = require("%rGui/shop/goodsView/goodsGold.nut")
let { getLocNameWp, mkGoodsWp } = require("%rGui/shop/goodsView/goodsWp.nut")
let { getLocNamePremium, mkGoodsPremium } = require("%rGui/shop/goodsView/goodsPremium.nut")
let { getLocNameUnit, mkGoodsUnit } = require("%rGui/shop/goodsView/goodsUnit.nut")
let { getLocNameConsumables, mkGoodsConsumables } = require("%rGui/shop/goodsView/goodsConsumables.nut")

let locNameGetters = {
  [SGT_UNKNOWN] = getLocNameUnknown,
  [SGT_GOLD] = getLocNameGold,
  [SGT_WP] = getLocNameWp,
  [SGT_PREMIUM] = getLocNamePremium,
  [SGT_UNIT] = getLocNameUnit,
  [SGT_CONSUMABLES] = getLocNameConsumables,
}

let constructors = {
  [SGT_UNKNOWN] = mkGoodsUnknown,
  [SGT_GOLD] = mkGoodsGold,
  [SGT_WP] = mkGoodsWp,
  [SGT_PREMIUM] = mkGoodsPremium,
  [SGT_UNIT] = mkGoodsUnit,
  [SGT_CONSUMABLES] = mkGoodsConsumables,
}

let getGoodsLocName = @(goods) (locNameGetters?[goods.gtype] ?? locNameGetters[SGT_UNKNOWN])(goods)
let mkGoods = @(goods, onClick, state, animParams = null)
  (constructors?[goods.gtype] ?? constructors[SGT_UNKNOWN])(goods, onClick, state, animParams)

return {
  getGoodsLocName
  mkGoods
}
