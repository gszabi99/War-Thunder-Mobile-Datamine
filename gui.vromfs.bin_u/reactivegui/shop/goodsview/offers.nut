from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
from "%appGlobals/rewardType.nut" import G_BATTLE_MOD
from "%rGui/shop/goodsView/goods.nut" import getGoodsLocName, mkGoods
from "%rGui/shop/goodsView/goodsGold.nut" import mkOfferGold
from "%rGui/shop/goodsView/goodsLootbox.nut" import mkOfferLootbox
from "%rGui/shop/goodsView/goodsUnit.nut" import mkOfferUnit, mkOfferBlueprint, mkOfferBranchUnit, mkOfferBattleMode


let constructors = {
  [SGT_GOLD] = mkOfferGold,
  [SGT_UNIT] = mkOfferUnit,
  [SGT_BLUEPRINTS] = mkOfferBlueprint,
  [SGT_UNIT_BUNDLE] = mkOfferBranchUnit,
  [SGT_LOOTBOX] = mkOfferLootbox,
}

function mkOffer(offer, onClick, state) {
  let { rewards } = offer
  let hasBattleMode = rewards.findvalue(@(r) r.gType == G_BATTLE_MOD) != null
  return hasBattleMode ? mkOfferBattleMode(offer, onClick, state)
    : (constructors?[getGoodsType(offer)](offer, onClick, state) ?? mkGoods(offer, onClick, state, null))
}

return {
  getOfferLocName = getGoodsLocName
  mkOffer
}