from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { getGoodsLocName, mkGoods } = require("%rGui/shop/goodsView/goods.nut")
let { mkOfferGold } = require("%rGui/shop/goodsView/goodsGold.nut")
let { mkOfferUnit, mkOfferBlueprint, mkOfferBranchUnit, mkOfferBattleMode } = require("%rGui/shop/goodsView/goodsUnit.nut")

let constructors = {
  [SGT_GOLD] = mkOfferGold,
  [SGT_UNIT] = mkOfferUnit,
  [SGT_BLUEPRINTS] = mkOfferBlueprint,
  [SGT_BRANCH] = mkOfferBranchUnit,
}

return {
  getOfferLocName = getGoodsLocName
  mkOffer = @(offer, onClick, state)
    ((offer?.battleMods.len() ?? 0) != 0) ? mkOfferBattleMode(offer, onClick, state)
      : (constructors?[offer.gtype](offer, onClick, state) ?? mkGoods(offer, onClick, state, null))
}