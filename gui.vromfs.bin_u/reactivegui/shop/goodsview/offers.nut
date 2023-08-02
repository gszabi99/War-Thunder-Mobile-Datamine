from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { getGoodsLocName, mkGoods } = require("goods.nut")
let { mkOfferGold } = require("%rGui/shop/goodsView/goodsGold.nut")
let { mkOfferUnit } = require("%rGui/shop/goodsView/goodsUnit.nut")

let constructors = {
  [SGT_GOLD] = mkOfferGold,
  [SGT_UNIT] = mkOfferUnit,
}

return {
  getOfferLocName = getGoodsLocName
  mkOffer = @(offer, onClick, state, needPrice)
    constructors?[offer.gtype](offer, onClick, state, needPrice)
    ?? mkGoods(offer, onClick, state, null)
}